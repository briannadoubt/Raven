"""
Shared utilities for Raven CLI
"""

import os
import sys
from pathlib import Path
from datetime import datetime

class Colors:
    """Terminal color codes"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def log(message, level='info'):
    """Colored logging with timestamp"""
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


def find_app_root():
    """Find app root by looking for Package.swift"""
    current = Path.cwd()

    # Check current directory
    if (current / 'Package.swift').exists():
        return current

    # Check parent directories (up to 3 levels)
    for _ in range(3):
        current = current.parent
        if (current / 'Package.swift').exists():
            return current

    return None


def get_config(app_root):
    """Get app configuration"""
    # Try to find .raven.json config
    config_file = app_root / '.raven.json'
    if config_file.exists():
        import json
        with open(config_file) as f:
            config = json.load(f)
    else:
        config = {}

    # Defaults
    defaults = {
        'app_name': app_root.name,
        'swift_sdk': 'swift-6.2.3-RELEASE_wasm',
        'wasm_target': 'wasm32-unknown-wasip1/debug',
        'public_dir': 'public',
        'build_dir': '.build',
        'source_dirs': ['Sources']
    }

    # Merge
    for key, value in defaults.items():
        config.setdefault(key, value)

    # Add framework sources if this is an example
    if 'Examples' in str(app_root):
        framework_sources = app_root / '../../Sources'
        if framework_sources.exists():
            if 'source_dirs' not in config:
                config['source_dirs'] = ['Sources']
            config['source_dirs'].append('../../Sources')

    # Compute paths
    app_name = config['app_name']
    wasm_target = config['wasm_target']
    build_dir = app_root / config['build_dir']
    public_dir = app_root / config['public_dir']

    config['wasm_src'] = build_dir / wasm_target / f"{app_name}.wasm"
    config['wasm_file'] = public_dir / f"{app_name}-v2.wasm"

    return config


def check_dependencies():
    """Check if required dependencies are installed"""
    missing = []

    try:
        import click
    except ImportError:
        missing.append('click')

    try:
        import flask
    except ImportError:
        missing.append('flask')

    try:
        import flask_cors
    except ImportError:
        missing.append('flask-cors')

    try:
        import watchdog
    except ImportError:
        missing.append('watchdog')

    if missing:
        print(f"{Colors.FAIL}Error: Missing dependencies{Colors.ENDC}")
        print(f"Install with: pip3 install {' '.join(missing)}")
        sys.exit(1)
