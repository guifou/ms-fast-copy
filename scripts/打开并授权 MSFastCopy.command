#!/bin/bash
# 首次安装时双击此脚本：去除下载隔离标记，并打开「隐私与安全性」设置页

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/MSFastCopy.app"

if [[ ! -d "$APP" ]]; then
    APP="/Applications/MSFastCopy.app"
fi

if [[ ! -d "$APP" ]]; then
    osascript -e 'display alert "未找到 MSFastCopy.app" message "请将此脚本与 MSFastCopy.app 放在同一文件夹，或先将 app 拖到「应用程序」。" as critical'
    exit 1
fi

xattr -cr "$APP" 2>/dev/null || true

open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension" 2>/dev/null \
    || open "x-apple.systempreferences:com.apple.preference.security" 2>/dev/null \
    || true

osascript <<EOF
display dialog "已打开「系统设置 → 隐私与安全性」。

请向下滚动，找到 MSFastCopy，点击「仍要打开」。

完成后可关闭此对话框，再双击 MSFastCopy.app 启动。" buttons {"知道了"} default button 1 with title "MS Fast Copy"
EOF

open "$APP" 2>/dev/null || true
