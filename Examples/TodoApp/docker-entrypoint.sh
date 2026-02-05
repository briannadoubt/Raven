#!/bin/bash
set -e

case "${1:-dev}" in
  dev)
    echo "🚀 Starting Swift WASM development server..."

    # Resolve dependencies first
    echo "📦 Resolving dependencies..."
    swift package resolve

    echo "🔨 Building WASM bundle with command ABI (like Tokamak)..."
    # Build for WASM with command ABI
    swift build --swift-sdk ${SWIFT_SDK} --product TodoApp

    # Copy WASM file to public directory
    mkdir -p public
    cp .build/wasm32-unknown-wasip1/debug/TodoApp.wasm public/TodoApp-v2.wasm

    # Get file size
    WASM_SIZE=$(ls -lh public/TodoApp-v2.wasm | awk '{print $5}')
    echo "📦 WASM bundle size: $WASM_SIZE"

    # Start HTTP server
    echo "✅ Build complete! Serving at http://localhost:8000"
    echo "📝 Edit sources and rebuild with: docker compose exec wasm-dev rebuild"
    python3 serve.py
    ;;

  build)
    echo "🔨 Building WASM (debug)..."
    swift package resolve
    swift build --swift-sdk ${SWIFT_SDK} --product TodoApp \
      -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor
    ;;

  release)
    echo "🔨 Building WASM (optimized release)..."
    swift package resolve
    swift build --swift-sdk ${SWIFT_SDK} --product TodoApp -c release -Xswiftc -Osize \
      -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor
    ls -lh .build/wasm32-unknown-wasip1/release/TodoApp.wasm
    ;;

  rebuild)
    echo "🔄 Rebuilding..."
    swift build --swift-sdk ${SWIFT_SDK} --product TodoApp \
      -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor
    mkdir -p public
    cp .build/wasm32-unknown-wasip1/debug/TodoApp.wasm public/TodoApp-v2.wasm
    WASM_SIZE=$(ls -lh public/TodoApp-v2.wasm | awk '{print $5}')
    echo "✅ Rebuild complete! Size: $WASM_SIZE"
    ;;

  shell)
    exec /bin/bash
    ;;

  *)
    exec "$@"
    ;;
esac
