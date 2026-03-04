#!/bin/bash
# Build TDLib for macOS and install to ./tdlib-local
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_DIR="$ROOT_DIR/tdlib-local"

if [ -f "$INSTALL_DIR/lib/libtdjson.dylib" ]; then
    echo "✅ TDLib already built at $INSTALL_DIR"
    exit 0
fi

echo "📦 Installing build dependencies..."
brew install gperf cmake openssl 2>/dev/null || true

echo "📥 Cloning TDLib..."
TD_DIR="$ROOT_DIR/.build-tdlib"
rm -rf "$TD_DIR"
git clone --depth 1 https://github.com/tdlib/td.git "$TD_DIR"

echo "🔨 Building TDLib..."
cd "$TD_DIR"
mkdir -p build && cd build

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENSSL_ROOT_DIR="$(brew --prefix openssl)" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    ..

cmake --build . --target install -j$(sysctl -n hw.ncpu)

echo "🧹 Cleaning build artifacts..."
rm -rf "$TD_DIR"

echo "✅ TDLib installed to $INSTALL_DIR"
echo "   Libraries: $INSTALL_DIR/lib/"
echo "   Headers:   $INSTALL_DIR/include/"
