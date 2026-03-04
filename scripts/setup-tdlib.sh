#!/bin/bash
# Build TDLib from source for macOS. Fully automated.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_DIR="$ROOT_DIR/tdlib-local"

if [ -f "$INSTALL_DIR/lib/libtdjson.dylib" ]; then
    echo "✅ TDLib already built at $INSTALL_DIR"
    exit 0
fi

echo "📦 Checking build dependencies..."
if ! command -v brew &>/dev/null; then
    echo "❌ Homebrew required. Install: https://brew.sh"
    exit 1
fi

for dep in gperf cmake; do
    if ! command -v $dep &>/dev/null; then
        echo "  Installing $dep..."
        brew install $dep
    fi
done

# OpenSSL from Homebrew
OPENSSL_DIR="$(brew --prefix openssl 2>/dev/null || true)"
if [ -z "$OPENSSL_DIR" ] || [ ! -d "$OPENSSL_DIR" ]; then
    echo "  Installing openssl..."
    brew install openssl
    OPENSSL_DIR="$(brew --prefix openssl)"
fi

echo "📥 Cloning TDLib..."
TD_DIR="$ROOT_DIR/.build-tdlib"
rm -rf "$TD_DIR"
git clone --depth 1 https://github.com/tdlib/td.git "$TD_DIR"

echo "🔨 Building TDLib (this takes 3-5 minutes)..."
cd "$TD_DIR"
mkdir -p build && cd build

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENSSL_ROOT_DIR="$OPENSSL_DIR" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    ..

cmake --build . --target install -j$(sysctl -n hw.ncpu)

echo "🧹 Cleaning build dir..."
rm -rf "$TD_DIR"

echo "✅ TDLib built and installed to $INSTALL_DIR"
ls -lh "$INSTALL_DIR/lib/libtdjson.dylib"
