#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MSFastCopy"
SETUP_APP_NAME="MS Fast Copy 安装助手"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
SETUP_APP_DIR="$BUILD_DIR/$SETUP_APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
SETUP_MACOS_DIR="$SETUP_APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"
TARGET="${ARCH}-apple-macos13.0"
SWIFT_FLAGS=(
    -O
    -whole-module-optimization
    -sdk "$SDK_PATH"
    -target "$TARGET"
    -parse-as-library
    -framework AppKit
)

sign_app() {
    local app_path="$1"
    codesign --force --deep --sign - --timestamp=none "$app_path"
    codesign --verify --deep --strict "$app_path"
}

echo "→ 清理旧构建…"
rm -rf "$APP_DIR" "$SETUP_APP_DIR"
mkdir -p "$MACOS_DIR" "$SETUP_MACOS_DIR" "$RESOURCES_DIR"

echo "→ 编译主程序…"
swiftc "${SWIFT_FLAGS[@]}" \
    -framework ApplicationServices \
    -framework ServiceManagement \
    -o "$MACOS_DIR/$APP_NAME" \
    "$ROOT/Sources/MSFastCopyApp.swift" \
    "$ROOT/Sources/ClipboardMonitor.swift" \
    "$ROOT/Sources/ClipboardSanitizer.swift" \
    "$ROOT/Sources/MenuBarController.swift" \
    "$ROOT/Sources/SystemSettingsOpener.swift"

echo "→ 编译安装助手…"
swiftc "${SWIFT_FLAGS[@]}" \
    -o "$SETUP_MACOS_DIR/MSFastCopySetup" \
    "$ROOT/Sources/Setup/SetupApp.swift" \
    "$ROOT/Sources/SystemSettingsOpener.swift"

echo "→ 打包 App Bundle…"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/Resources/SetupInfo.plist" "$SETUP_APP_DIR/Contents/Info.plist"

echo "→ 签名…"
sign_app "$APP_DIR"
sign_app "$SETUP_APP_DIR"

cp "$ROOT/安装说明.txt" "$BUILD_DIR/"

echo ""
echo "✓ 构建完成:"
echo "  主程序:   $APP_DIR"
echo "  安装助手: $SETUP_APP_DIR"
echo ""
echo "  首次安装请打开: open \"$SETUP_APP_DIR\""
