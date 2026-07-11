#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MSFastCopy"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
ZIP_PATH="$BUILD_DIR/MSFastCopy.zip"

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"
TARGET="${ARCH}-apple-macos13.0"

echo "→ 清理旧构建（含历史安装助手等残留）…"
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "→ 编译…"
swiftc \
    -O \
    -whole-module-optimization \
    -sdk "$SDK_PATH" \
    -target "$TARGET" \
    -parse-as-library \
    -framework AppKit \
    -framework ServiceManagement \
    -o "$MACOS_DIR/$APP_NAME" \
    "$ROOT/Sources/"*.swift

echo "→ 打包…"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/安装说明.txt" "$BUILD_DIR/"

echo "→ 签名…"
codesign --force --deep --sign - --timestamp=none "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"

echo "→ 生成 zip（仅含 app + 安装说明）…"
rm -f "$ZIP_PATH"
(
    cd "$BUILD_DIR"
    COPYFILE_DISABLE=1 zip -r MSFastCopy.zip MSFastCopy.app 安装说明.txt >/dev/null
)

echo ""
echo "✓ 构建完成: $APP_DIR"
echo "✓ 发布包:   $ZIP_PATH"
echo ""
echo "zip 内容:"
unzip -l "$ZIP_PATH"
