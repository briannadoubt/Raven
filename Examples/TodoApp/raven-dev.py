#!/usr/bin/env python3
"""
Raven Development Server with Hot Reloading

Watches for file changes, rebuilds WASM, and auto-reloads browser.
Based on the raven-dev skill workflow.

Usage:
    python3 raven-dev.py [--port PORT] [--no-browser]
"""

import os
import sys
import time
import hashlib
import subprocess
import threading
import signal
from pathlib import Path
from datetime import datetime
from flask import Flask, send_from_directory, jsonify
from flask_cors import CORS
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configuration
SWIFT_SDK = "swift-6.2.3-RELEASE_wasm"
WASM_TARGET = "wasm32-unknown-wasip1/debug"
APP_NAME = "TodoApp"
SOURCE_DIRS = ["Sources", "../../Sources"]  # Watch app and framework sources
PUBLIC_DIR = "public"
BUILD_DIR = ".build"

# Color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class RavenDevServer:
    def __init__(self, port=8000):
        self.port = port
        self.app = Flask(__name__)
        CORS(self.app)
        self.building = False
        self.build_queued = False
        self.last_wasm_hash = None
        self.setup_routes()

    def setup_routes(self):
        """Setup Flask routes with proper cache control"""

        @self.app.route('/')
        def index():
            return send_from_directory(PUBLIC_DIR, 'index.html')

        @self.app.route('/<path:path>')
        def serve_file(path):
            return send_from_directory(PUBLIC_DIR, path)

        @self.app.route('/api/status')
        def status():
            """API endpoint to check if new WASM is available"""
            return jsonify({
                'building': self.building,
                'wasm_hash': self.last_wasm_hash,
                'timestamp': datetime.now().isoformat()
            })

        @self.app.after_request
        def add_headers(response):
            """Add cache control headers for WASM files"""
            if response.mimetype == 'application/wasm':
                response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
                response.headers['Pragma'] = 'no-cache'
                response.headers['Expires'] = '0'
            # Add hot reload headers
            response.headers['Access-Control-Allow-Origin'] = '*'
            return response

    def get_wasm_hash(self):
        """Get MD5 hash of current WASM file"""
        wasm_path = Path(PUBLIC_DIR) / f"{APP_NAME}-v2.wasm"
        if not wasm_path.exists():
            return None

        with open(wasm_path, 'rb') as f:
            return hashlib.md5(f.read()).hexdigest()

    def log(self, message, level='info'):
        """Colored logging"""
        timestamp = datetime.now().strftime('%H:%M:%S')

        colors = {
            'info': Colors.OKCYAN,
            'success': Colors.OKGREEN,
            'warning': Colors.WARNING,
            'error': Colors.FAIL,
            'build': Colors.OKBLUE
        }

        color = colors.get(level, '')
        print(f"{color}[{timestamp}]{Colors.ENDC} {message}")

    def build_wasm(self):
        """Build WASM binary using Swift"""
        if self.building:
            self.build_queued = True
            return

        self.building = True
        self.log(f"🔨 Building {APP_NAME}.wasm...", 'build')

        try:
            # Run swift build
            start_time = time.time()
            result = subprocess.run(
                ['swift', 'build', '--swift-sdk', SWIFT_SDK],
                capture_output=True,
                text=True,
                timeout=120
            )

            build_time = time.time() - start_time

            if result.returncode != 0:
                self.log(f"❌ Build failed ({build_time:.1f}s)", 'error')
                # Show only errors, not warnings
                errors = [line for line in result.stderr.split('\n')
                         if 'error:' in line.lower()]
                for error in errors[:5]:  # Show first 5 errors
                    print(f"  {error}")
                if len(errors) > 5:
                    print(f"  ... and {len(errors) - 5} more errors")
                return False

            # Copy WASM to public directory
            wasm_src = Path(BUILD_DIR) / WASM_TARGET / f"{APP_NAME}.wasm"
            wasm_dst = Path(PUBLIC_DIR) / f"{APP_NAME}-v2.wasm"

            if not wasm_src.exists():
                self.log(f"❌ WASM file not found: {wasm_src}", 'error')
                return False

            # Copy file
            import shutil
            shutil.copy2(wasm_src, wasm_dst)

            # Update hash
            new_hash = self.get_wasm_hash()
            size_mb = wasm_dst.stat().st_size / (1024 * 1024)

            self.log(f"✅ Build successful ({build_time:.1f}s, {size_mb:.1f}MB)", 'success')
            self.log(f"   Hash: {new_hash[:8]}...", 'info')

            self.last_wasm_hash = new_hash
            return True

        except subprocess.TimeoutExpired:
            self.log("❌ Build timeout (120s)", 'error')
            return False
        except Exception as e:
            self.log(f"❌ Build error: {e}", 'error')
            return False
        finally:
            self.building = False

            # Check if another build was queued
            if self.build_queued:
                self.build_queued = False
                self.log("🔄 Running queued build...", 'info')
                threading.Thread(target=self.build_wasm, daemon=True).start()

    def run(self):
        """Start the development server"""
        self.log(f"🚀 Raven Dev Server starting on port {self.port}", 'success')
        self.app.run(host='0.0.0.0', port=self.port, debug=False, use_reloader=False)


class SourceWatcher(FileSystemEventHandler):
    """Watch source files for changes"""

    def __init__(self, dev_server):
        self.dev_server = dev_server
        self.last_build = 0
        self.debounce_seconds = 1.0  # Wait 1s after last change

    def should_trigger_build(self, path):
        """Check if file change should trigger rebuild"""
        # Only watch .swift files
        if not path.endswith('.swift'):
            return False

        # Ignore hidden files and build artifacts
        if '/.build/' in path or '/.' in path:
            return False

        # Debounce: wait for changes to settle
        now = time.time()
        if now - self.last_build < self.debounce_seconds:
            return False

        return True

    def on_modified(self, event):
        if event.is_directory:
            return

        if self.should_trigger_build(event.src_path):
            self.last_build = time.time()
            self.dev_server.log(f"📝 Changed: {Path(event.src_path).name}", 'info')

            # Trigger rebuild in background
            threading.Thread(target=self.dev_server.build_wasm, daemon=True).start()

    def on_created(self, event):
        self.on_modified(event)


def inject_hot_reload_script():
    """Inject hot reload script into index.html if not present"""
    index_path = Path(PUBLIC_DIR) / 'index.html'

    if not index_path.exists():
        return

    content = index_path.read_text()

    # Check if already injected
    if 'raven-hot-reload' in content:
        return

    hot_reload_script = """
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
                        console.log('🔥 Hot reload active, hash:', lastHash?.substring(0, 8));
                        return;
                    }

                    if (data.wasm_hash && data.wasm_hash !== lastHash) {
                        console.log('🔄 New build detected, reloading...');
                        window.location.reload();
                    }
                })
                .catch(err => console.error('Hot reload check failed:', err));
        }

        // Check every 2 seconds
        setInterval(checkForUpdates, 2000);
        checkForUpdates();
    })();
    </script>
    """

    # Inject before closing body tag
    if '</body>' in content:
        content = content.replace('</body>', hot_reload_script + '\n</body>')
        index_path.write_text(content)
        print(f"{Colors.OKGREEN}✓{Colors.ENDC} Hot reload script injected into index.html")


def main():
    import argparse

    parser = argparse.ArgumentParser(description='Raven development server with hot reloading')
    parser.add_argument('--port', type=int, default=8000, help='Port to serve on (default: 8000)')
    parser.add_argument('--no-browser', action='store_true', help='Don\'t open browser automatically')
    parser.add_argument('--no-initial-build', action='store_true', help='Skip initial build')

    args = parser.parse_args()

    # Check we're in the right directory
    if not Path('Package.swift').exists():
        print(f"{Colors.FAIL}Error: Must run from app directory (e.g., Examples/TodoApp){Colors.ENDC}")
        sys.exit(1)

    # Check Swift SDK
    result = subprocess.run(['swift', 'sdk', 'list'], capture_output=True, text=True)
    if SWIFT_SDK not in result.stdout:
        print(f"{Colors.FAIL}Error: {SWIFT_SDK} not found{Colors.ENDC}")
        print(f"Install with: swift sdk install <URL>")
        sys.exit(1)

    # Create public directory if needed
    Path(PUBLIC_DIR).mkdir(exist_ok=True)

    # Inject hot reload script
    inject_hot_reload_script()

    # Create dev server
    dev_server = RavenDevServer(port=args.port)

    # Initial build
    if not args.no_initial_build:
        print(f"\n{Colors.BOLD}🏗️  Initial build...{Colors.ENDC}")
        if not dev_server.build_wasm():
            print(f"\n{Colors.WARNING}⚠️  Initial build failed, but starting server anyway{Colors.ENDC}")

    # Setup file watcher
    event_handler = SourceWatcher(dev_server)
    observer = Observer()

    for source_dir in SOURCE_DIRS:
        if Path(source_dir).exists():
            observer.schedule(event_handler, source_dir, recursive=True)
            print(f"{Colors.OKCYAN}👀 Watching:{Colors.ENDC} {source_dir}")

    observer.start()

    # Handle Ctrl+C gracefully
    def signal_handler(sig, frame):
        print(f"\n\n{Colors.OKCYAN}🛑 Shutting down...{Colors.ENDC}")
        observer.stop()
        observer.join()
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)

    # Open browser
    if not args.no_browser:
        import webbrowser
        url = f"http://localhost:{args.port}"
        print(f"\n{Colors.OKGREEN}🌐 Opening browser:{Colors.ENDC} {url}\n")
        threading.Timer(1.0, lambda: webbrowser.open(url)).start()

    print(f"\n{Colors.BOLD}{Colors.OKGREEN}✓ Ready!{Colors.ENDC}")
    print(f"{Colors.OKCYAN}  • Edit .swift files to trigger rebuild{Colors.ENDC}")
    print(f"{Colors.OKCYAN}  • Browser will auto-reload on changes{Colors.ENDC}")
    print(f"{Colors.OKCYAN}  • Press Ctrl+C to stop{Colors.ENDC}\n")

    # Start server (blocking)
    try:
        dev_server.run()
    except KeyboardInterrupt:
        signal_handler(None, None)


if __name__ == '__main__':
    main()
