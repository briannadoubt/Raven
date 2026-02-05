#!/bin/bash
set -e

echo "🧪 Testing TodoApp Deployment"
echo "=============================="
echo ""

# Check if WASM built
if [ ! -f ".build/wasm32-unknown-wasip1/debug/TodoApp.wasm" ]; then
    echo "❌ WASM not built. Run: swift build --swift-sdk swift-6.2.3-RELEASE_wasm --product TodoApp"
    exit 1
fi

echo "✅ WASM built successfully"
WASM_SIZE=$(ls -lh .build/wasm32-unknown-wasip1/debug/TodoApp.wasm | awk '{print $5}')
WASM_HASH=$(md5 .build/wasm32-unknown-wasip1/debug/TodoApp.wasm | awk '{print $4}')
echo "   Size: $WASM_SIZE"
echo "   Hash: $WASM_HASH"
echo ""

# Copy to public directory
mkdir -p public
cp .build/wasm32-unknown-wasip1/debug/TodoApp.wasm public/TodoApp-v2.wasm
echo "✅ Copied to public/TodoApp-v2.wasm"
echo ""

# Check Flask server
if [ -f "serve.py" ]; then
    echo "✅ Flask server script found"
else
    echo "❌ Flask server script not found"
    exit 1
fi
echo ""

# Verify files
echo "📋 Verification:"
echo "   - docker-entrypoint.sh uses TodoApp-v2.wasm: $(grep -c 'TodoApp-v2.wasm' docker-entrypoint.sh)"
echo "   - index.html loads TodoApp-v2.wasm: $(grep -c 'TodoApp-v2.wasm' public/index.html)"
echo "   - serve.py has cache-control headers: $(grep -c 'Cache-Control' serve.py)"
echo ""

echo "🚀 Ready to test!"
echo ""
echo "Start Docker container:"
echo "   docker compose up --build"
echo ""
echo "Or run locally:"
echo "   python3 serve.py"
echo ""
echo "Then open http://localhost:8000 in your browser"
echo "Check browser console for:"
echo "   - 'VNode children count: 5' (parameter packs working)"
echo "   - No 'unreachable' errors (DOMBridge safe)"
echo "   - TodoApp UI renders with 5 elements"
