#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MSFastCopy"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "→ 清理旧构建…"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "→ 编译 Swift…"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"

swiftc \
    -O \
    -whole-module-optimization \
    -sdk "$SDK_PATH" \
    -target "${ARCH}-apple-macos13.0" \
    -parse-as-library \
    -framework AppKit \
    -framework ServiceManagement \
    -o "$MACOS_DIR/$APP_NAME" \
    "$ROOT/Sources/"*.swift

echo "→ 打包 App Bundle…"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

# 生成简单图标（可选）
if command -v sips &>/dev/null; then
    ICON_TMP="$BUILD_DIR/icon.png"
    python3 - <<'PY' "$ICON_TMP" 2>/dev/null || true
import sys
from pathlib import Path
try:
    from PIL import Image, ImageDraw
    img = Image.new("RGBA", (512, 512), (30, 120, 220, 255))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((96, 120, 416, 392), radius=40, fill=(255, 255, 255, 255))
    d.rectangle((140, 180, 372, 210), fill=(30, 120, 220, 255))
    d.rectangle((140, 240, 320, 270), fill=(30, 120, 220, 200))
    img.save(sys.argv[1])
except Exception:
    pass
PY
    if [[ -f "$ICON_TMP" ]]; then
        mkdir -p "$RESOURCES_DIR/AppIcon.iconset"
        for size in 16 32 128 256 512; do
            sips -z $size $size "$ICON_TMP" --out "$RESOURCES_DIR/AppIcon.iconset/icon_${size}x${size}.png" &>/dev/null || true
            double=$((size * 2))
            sips -z $double $double "$ICON_TMP" --out "$RESOURCES_DIR/AppIcon.iconset/icon_${size}x${size}@2x.png" &>/dev/null || true
        done
        iconutil -c icns "$RESOURCES_DIR/AppIcon.iconset" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null || true
    fi
fi

echo ""
echo "✓ 构建完成: $APP_DIR"
echo "  运行: open \"$APP_DIR\""
