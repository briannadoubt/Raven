"""
Raven Dev - Hot reload development server
"""

import os
import sys
import time
import hashlib
import subprocess
import threading
import webbrowser
from pathlib import Path
from datetime import datetime

import click
from flask import Flask, send_from_directory, jsonify
from flask_cors import CORS
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

from .utils import Colors, log, find_app_root, get_config

class RavenDevServer:
    """Development server with hot reload"""

    def __init__(self, port=8000, config=None):
        self.port = port
        self.config = config or {}
        self.app = Flask(__name__)
        CORS(self.app)
        self.building = False
        self.build_queued = False
        self.last_wasm_hash = None
        self.setup_routes()

    def setup_routes(self):
        """Setup Flask routes"""
        public_dir = self.config.get('public_dir', 'public')

        @self.app.route('/')
        def index():
            return send_from_directory(public_dir, 'index.html')

        @self.app.route('/<path:path>')
        def serve_file(path):
            return send_from_directory(public_dir, path)

        @self.app.route('/api/status')
        def status():
            return jsonify({
                'building': self.building,
                'wasm_hash': self.last_wasm_hash,
                'timestamp': datetime.now().isoformat()
            })

        @self.app.after_request
        def add_headers(response):
            if response.mimetype == 'application/wasm':
                response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
                response.headers['Pragma'] = 'no-cache'
                response.headers['Expires'] = '0'
            response.headers['Access-Control-Allow-Origin'] = '*'
            return response

    def get_wasm_hash(self):
        """Get MD5 hash of WASM file"""
        wasm_file = self.config.get('wasm_file')
        if not wasm_file or not wasm_file.exists():
            return None

        with open(wasm_file, 'rb') as f:
            return hashlib.md5(f.read()).hexdigest()

    def build_wasm(self):
        """Build WASM binary"""
        if self.building:
            self.build_queued = True
            return

        self.building = True
        app_name = self.config.get('app_name', 'App')
        swift_sdk = self.config.get('swift_sdk', 'swift-6.2.3-RELEASE_wasm')

        log(f"🔨 Building {app_name}.wasm...", 'build')

        try:
            start_time = time.time()
            result = subprocess.run(
                ['swift', 'build', '--swift-sdk', swift_sdk],
                capture_output=True,
                text=True,
                timeout=120
            )

            build_time = time.time() - start_time

            if result.returncode != 0:
                log(f"❌ Build failed ({build_time:.1f}s)", 'error')
                errors = [line for line in result.stderr.split('\n')
                         if 'error:' in line.lower()]
                for error in errors[:5]:
                    print(f"  {error}")
                if len(errors) > 5:
                    print(f"  ... and {len(errors) - 5} more errors")
                return False

            # Copy WASM
            wasm_src = self.config['wasm_src']
            wasm_dst = self.config['wasm_file']

            if not wasm_src.exists():
                log(f"❌ WASM not found: {wasm_src}", 'error')
                return False

            import shutil
            shutil.copy2(wasm_src, wasm_dst)

            new_hash = self.get_wasm_hash()
            size_mb = wasm_dst.stat().st_size / (1024 * 1024)

            log(f"✅ Build successful ({build_time:.1f}s, {size_mb:.1f}MB)", 'success')
            log(f"   Hash: {new_hash[:8]}...", 'info')

            self.last_wasm_hash = new_hash
            return True

        except subprocess.TimeoutExpired:
            log("❌ Build timeout (120s)", 'error')
            return False
        except Exception as e:
            log(f"❌ Build error: {e}", 'error')
            return False
        finally:
            self.building = False

            if self.build_queued:
                self.build_queued = False
                log("🔄 Running queued build...", 'info')
                threading.Thread(target=self.build_wasm, daemon=True).start()

    def run(self):
        """Start server"""
        log(f"🚀 Raven Dev Server on http://localhost:{self.port}", 'success')
        self.app.run(host='0.0.0.0', port=self.port, debug=False, use_reloader=False)


class SourceWatcher(FileSystemEventHandler):
    """Watch Swift source files"""

    def __init__(self, dev_server):
        self.dev_server = dev_server
        self.last_build = 0
        self.debounce_seconds = 1.0

    def should_trigger_build(self, path):
        if not path.endswith('.swift'):
            return False
        if '/.build/' in path or '/.' in path:
            return False

        now = time.time()
        if now - self.last_build < self.debounce_seconds:
            return False

        return True

    def on_modified(self, event):
        if event.is_directory:
            return

        if self.should_trigger_build(event.src_path):
            self.last_build = time.time()
            log(f"📝 Changed: {Path(event.src_path).name}", 'info')
            threading.Thread(target=self.dev_server.build_wasm, daemon=True).start()

    def on_created(self, event):
        self.on_modified(event)


def inject_hot_reload(html_path):
    """Inject hot reload script into HTML"""
    if not html_path.exists():
        return

    content = html_path.read_text()
    if 'raven-hot-reload' in content:
        return

    script = """
    <!-- Raven Hot Reload -->
    <script id="raven-hot-reload">
    (function() {
        let lastHash = null;
        function checkForUpdates() {
            fetch('/api/status')
                .then(r => r.json())
                .then(data => {
                    if (lastHash === null) {
                        lastHash = data.wasm_hash;
                        console.log('🔥 Hot reload active');
                        return;
                    }
                    if (data.wasm_hash && data.wasm_hash !== lastHash) {
                        console.log('🔄 Reloading...');
                        window.location.reload();
                    }
                })
                .catch(() => {});
        }
        setInterval(checkForUpdates, 2000);
        checkForUpdates();
    })();
    </script>
    """

    if '</body>' in content:
        content = content.replace('</body>', script + '\n</body>')
        html_path.write_text(content)
        click.echo(f"{Colors.OKGREEN}✓{Colors.ENDC} Hot reload injected")


@click.command()
@click.option('--port', '-p', default=8000, help='Port to serve on')
@click.option('--no-browser', is_flag=True, help='Don\'t open browser')
@click.option('--no-initial-build', is_flag=True, help='Skip initial build')
def dev_command(port, no_browser, no_initial_build):
    """Start development server with hot reload"""

    # Find app root
    app_root = find_app_root()
    if not app_root:
        click.echo(f"{Colors.FAIL}Error: Not in a Raven app directory{Colors.ENDC}")
        click.echo("Must have Package.swift in current or parent directory")
        sys.exit(1)

    os.chdir(app_root)
    config = get_config(app_root)

    # Verify Swift SDK
    swift_sdk = config.get('swift_sdk', 'swift-6.2.3-RELEASE_wasm')
    result = subprocess.run(['swift', 'sdk', 'list'], capture_output=True, text=True)
    if swift_sdk not in result.stdout:
        click.echo(f"{Colors.FAIL}Error: {swift_sdk} not installed{Colors.ENDC}")
        sys.exit(1)

    # Ensure public directory
    public_dir = Path(config.get('public_dir', 'public'))
    public_dir.mkdir(exist_ok=True)

    # Inject hot reload
    inject_hot_reload(public_dir / 'index.html')

    # Create dev server
    dev_server = RavenDevServer(port=port, config=config)

    # Initial build
    if not no_initial_build:
        click.echo(f"\n{Colors.BOLD}🏗️  Initial build...{Colors.ENDC}")
        if not dev_server.build_wasm():
            click.echo(f"{Colors.WARNING}⚠️  Build failed, continuing anyway{Colors.ENDC}")

    # Setup watcher
    watcher = SourceWatcher(dev_server)
    observer = Observer()

    source_dirs = config.get('source_dirs', ['Sources'])
    for source_dir in source_dirs:
        src_path = app_root / source_dir
        if src_path.exists():
            observer.schedule(watcher, str(src_path), recursive=True)
            click.echo(f"{Colors.OKCYAN}👀 Watching:{Colors.ENDC} {source_dir}")

    observer.start()

    # Open browser
    if not no_browser:
        url = f"http://localhost:{port}"
        click.echo(f"\n{Colors.OKGREEN}🌐 Opening:{Colors.ENDC} {url}")
        threading.Timer(1.0, lambda: webbrowser.open(url)).start()

    click.echo(f"\n{Colors.BOLD}{Colors.OKGREEN}✓ Ready!{Colors.ENDC}")
    click.echo(f"{Colors.OKCYAN}  • Edit .swift files to trigger rebuild{Colors.ENDC}")
    click.echo(f"{Colors.OKCYAN}  • Browser auto-reloads on changes{Colors.ENDC}")
    click.echo(f"{Colors.OKCYAN}  • Press Ctrl+C to stop{Colors.ENDC}\n")

    try:
        dev_server.run()
    finally:
        observer.stop()
        observer.join()
