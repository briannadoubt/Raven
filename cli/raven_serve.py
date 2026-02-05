"""
Raven Serve - Serve app without hot reload
"""

import os
import sys
import webbrowser
import threading
from pathlib import Path

import click
from flask import Flask, send_from_directory

from .utils import Colors, log, find_app_root, get_config


@click.command()
@click.option('--port', '-p', default=8000, help='Port to serve on')
@click.option('--no-browser', is_flag=True, help='Don\'t open browser')
def serve_command(port, no_browser):
    """Serve app without hot reload"""

    # Find app root
    app_root = find_app_root()
    if not app_root:
        click.echo(f"{Colors.FAIL}Error: Not in a Raven app directory{Colors.ENDC}")
        sys.exit(1)

    os.chdir(app_root)
    config = get_config(app_root)

    public_dir = config.get('public_dir', 'public')

    # Check if public directory exists
    if not Path(public_dir).exists():
        click.echo(f"{Colors.FAIL}Error: {public_dir}/ directory not found{Colors.ENDC}")
        click.echo("Run 'raven build' first")
        sys.exit(1)

    # Check if WASM exists
    wasm_file = Path(public_dir) / f"{config['app_name']}-v2.wasm"
    if not wasm_file.exists():
        click.echo(f"{Colors.WARNING}Warning: {wasm_file} not found{Colors.ENDC}")
        click.echo("Run 'raven build' to create it")

    # Create Flask app
    app = Flask(__name__)

    @app.route('/')
    def index():
        return send_from_directory(public_dir, 'index.html')

    @app.route('/<path:path>')
    def serve_file(path):
        return send_from_directory(public_dir, path)

    @app.after_request
    def add_headers(response):
        if response.mimetype == 'application/wasm':
            response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
            response.headers['Pragma'] = 'no-cache'
            response.headers['Expires'] = '0'
        return response

    # Open browser
    if not no_browser:
        url = f"http://localhost:{port}"
        log(f"🌐 Opening: {url}", 'info')
        threading.Timer(1.0, lambda: webbrowser.open(url)).start()

    log(f"🚀 Serving on http://localhost:{port}", 'success')
    click.echo(f"{Colors.OKCYAN}  • Press Ctrl+C to stop{Colors.ENDC}\n")

    # Start server
    try:
        app.run(host='0.0.0.0', port=port, debug=False)
    except KeyboardInterrupt:
        log("\n🛑 Server stopped", 'info')
