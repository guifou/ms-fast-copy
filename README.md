# MS Fast Copy

在 macOS 上，从 Microsoft Word / PowerPoint 复制文字后，粘贴到 Cursor、Codex 等 Electron 应用时，内容有时会以**图片**形式出现。本工具在后台监听剪贴板，自动移除 Office 附带的图片表示，让 `⌘V` 正常粘贴为文字。

## 安装

1. 打开 [Releases](https://github.com/guifou/ms-fast-copy/releases) 下载 `MSFastCopy.zip`
2. 解压后阅读 **`安装说明.txt`**
3. 将 `MSFastCopy.app` 拖到「应用程序」
4. **右键 → 打开** MSFastCopy.app（首次需绕过 macOS 未公证提示）
5. 若仍被拦截：「系统设置 → 隐私与安全性」→ 底部点「仍要打开」

## 使用

- 菜单栏出现图标即表示运行中
- 从 Word / PPT 复制文字，在 Cursor 里 `⌘V` 粘贴
- 可选：「系统设置 → 隐私与安全性 → 辅助功能」中勾选 MSFastCopy

## 从源码构建

```bash
git clone https://github.com/guifou/ms-fast-copy.git
cd ms-fast-copy
./scripts/build.sh
open build/MSFastCopy.app
```

## 原理

Microsoft Office 复制文字时，剪贴板同时包含文本和富文本/图片快照。Electron 应用粘贴时可能读到图片。**MS Fast Copy** 检测到 Office 来源后，将剪贴板重写为纯文本。

监听方式：全局 `⌘C` / `⌘X` 触发 + 1 秒低频兜底。

## 系统要求

- macOS 13.0+
- Apple Silicon 或 Intel Mac

## 隐私

- 仅本地处理剪贴板，不联网、不保存历史

## License

MIT
