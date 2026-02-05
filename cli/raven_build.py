"""
Raven Build - Build WASM binary
"""

import os
import sys
import subprocess
from pathlib import Path

import click

from .utils import Colors, log, find_app_root, get_config


@click.command()
@click.option('--release', '-r', is_flag=True, help='Build for release')
@click.option('--optimize-size', '-O', is_flag=True, help='Optimize for size')
@click.option('--verbose', '-v', is_flag=True, help='Verbose output')
def build_command(release, optimize_size, verbose):
    """Build WASM binary"""

    # Find app root
    app_root = find_app_root()
    if not app_root:
        click.echo(f"{Colors.FAIL}Error: Not in a Raven app directory{Colors.ENDC}")
        sys.exit(1)

    os.chdir(app_root)
    config = get_config(app_root)

    app_name = config['app_name']
    swift_sdk = config['swift_sdk']

    # Build command
    cmd = ['swift', 'build', '--swift-sdk', swift_sdk]

    if release:
        cmd.extend(['-c', 'release'])
        log(f"🔨 Building {app_name}.wasm (release)...", 'build')
    else:
        log(f"🔨 Building {app_name}.wasm (debug)...", 'build')

    if optimize_size:
        cmd.extend([
            '-Xswiftc', '-Osize',
            '-Xswiftc', '-whole-module-optimization'
        ])

    if verbose:
        cmd.append('--verbose')

    # Build
    try:
        import time
        start = time.time()

        result = subprocess.run(cmd, capture_output=not verbose, text=True)

        if result.returncode != 0:
            log("❌ Build failed", 'error')
            if not verbose and result.stderr:
                errors = [line for line in result.stderr.split('\n')
                         if 'error:' in line.lower()]
                for error in errors[:10]:
                    print(f"  {error}")
            sys.exit(1)

        elapsed = time.time() - start

        # Get WASM path
        wasm_src = config['wasm_src']
        if release:
            wasm_src = wasm_src.parent.parent / 'release' / f"{app_name}.wasm"

        if not wasm_src.exists():
            log(f"❌ WASM not found: {wasm_src}", 'error')
            sys.exit(1)

        # Show size
        size_mb = wasm_src.stat().st_size / (1024 * 1024)
        log(f"✅ Build successful ({elapsed:.1f}s, {size_mb:.1f}MB)", 'success')
        log(f"   Output: {wasm_src}", 'info')

        # Copy to public if it exists
        public_dir = Path(config['public_dir'])
        if public_dir.exists():
            import shutil
            wasm_dst = public_dir / f"{app_name}-v2.wasm"
            shutil.copy2(wasm_src, wasm_dst)
            log(f"   Copied to: {wasm_dst}", 'info')

    except KeyboardInterrupt:
        log("\n❌ Build cancelled", 'error')
        sys.exit(1)
    except Exception as e:
        log(f"❌ Build error: {e}", 'error')
        sys.exit(1)
