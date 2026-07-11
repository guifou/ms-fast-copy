# MS Fast Copy

在 macOS 上，从 Microsoft Word / PowerPoint 复制文字后，粘贴到 Cursor、Codex 等 Electron 应用时，内容有时会以**图片**形式出现。本工具在后台监听剪贴板，自动移除 Office 附带的图片表示，让 `⌘V` 正常粘贴为文字。

## 快速安装（推荐给普通用户）

1. 打开 [Releases](https://github.com/guifou/ms-fast-copy/releases) 页面
2. 下载 `MSFastCopy.zip`
3. 解压后 **先双击 `打开并授权 MSFastCopy.command`**（会自动打开「隐私与安全性」并尝试启动 app）
4. 在「系统设置 → 隐私与安全性」底部找到 MSFastCopy，点击 **「仍要打开」**
5. 也可将 `MSFastCopy.app` 拖到「应用程序」后，从菜单栏使用

> **若提示「Apple 无法验证…」或「应用程序已损坏」**：不要直接双击 app，请先运行上面的 `.command` 脚本；或在终端执行 `xattr -cr /Applications/MSFastCopy.app` 后，在菜单栏 app 里点「打开隐私与安全性设置…」。

> 首次运行建议授予 **辅助功能** 权限（系统设置 → 隐私与安全性 → 辅助功能），以便准确识别 `⌘C` 复制来源。未授权时仍可通过低频兜底模式工作。

### 日常使用

- 应用无 Dock 图标，只在**菜单栏**显示
- 默认已启用，无需额外操作
- 可在菜单中勾选「登录时启动」，或手动加入系统「登录项」

## 从源码构建（开发者）

需要安装 [Xcode Command Line Tools](https://developer.apple.com/xcode/resources/)：

```bash
git clone https://github.com/guifou/ms-fast-copy.git
cd ms-fast-copy
chmod +x scripts/build.sh
./scripts/build.sh
open build/MSFastCopy.app
```

构建产物约 **130KB**，运行时内存约 **30MB**（AppKit 基础开销）。

## 原理

Microsoft Office for Mac 复制文字时，剪贴板里往往同时存在：

- 文本格式（`public.utf8-plain-text`、`public.rtf` 等）
- 图片格式（`public.tiff` 等，或 **嵌在 RTF/HTML 里的图片快照**）

部分桌面应用（Cursor、Codex 等 Electron 应用）粘贴时会通过 `NSImage(pasteboard:)` 读到图片，导致 `⌘V` 粘贴成图片。

**MS Fast Copy** 检测到 Office 文字复制后，会将剪贴板 **完全重写为纯文本**，彻底移除 RTF/HTML/TIFF 等格式。

### 监听策略

macOS 没有「剪贴板已变化」的系统通知，因此采用两种方式配合：

1. **复制时触发（主路径）**：监听全局 `⌘C` / `⌘X`，在按键瞬间记录前台应用（即复制来源），约 80ms 后读取并处理剪贴板。
2. **低频兜底（1 秒一次）**：捕获菜单栏「编辑 → 复制」等非快捷键操作；此时用前台应用或剪贴板上的 `com.microsoft.*` 格式判断来源。

即使复制后立刻切到 Cursor，剪贴板上的 Microsoft 专有格式仍可识别来源，不依赖前台应用。

## 菜单选项

- **启用剪贴板修复** — 开关核心功能
- **登录时启动** — 开机自动运行（需 macOS 13+）
- **退出**

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon 或 Intel Mac

## 隐私

- 仅读取系统剪贴板，在本地处理
- 不联网、不上传任何数据
- 不保存剪贴板历史

## 已知限制

1. **仅处理 Office 来源**：从 Word / PowerPoint / Excel 等 Microsoft 应用复制、且剪贴板同时含文字与图片时才会清理。
2. **真实图片复制**：若在 Office 中复制的是图片本身，可能被误处理；此时可暂时关闭本工具。
3. **未签名应用**：Release 版未经 Apple 公证，下载后若提示「已损坏」，请执行 `xattr -cr /Applications/MSFastCopy.app`；「登录时启动」也可能需手动加入系统登录项。

## License

MIT
