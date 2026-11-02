# Codex ZH Localizer

一个面向 Windows 的 Codex 桌面端非官方界面汉化辅助工具。

它通过 Codex 自带的本机 Chromium 调试接口注入翻译表，替换常见界面文字，不会修改 Codex 安装文件，也不会把界面内容发送到网络。

当前版本：`1.2.1`

## 功能

- 汉化导航、项目、设置、对话框等常见界面文字
- 启动时关闭并重新打开 Codex
- 提供一键恢复入口，随时停用汉化
- 翻译词条集中在 `overlay.js`，便于自行补充
- 不依赖第三方 npm 包

## 环境要求

- Windows 10 或 Windows 11
- 已安装并至少启动过一次 Codex 桌面端
- Node.js 已安装并可从命令行运行（`node --version` 应能输出版本号）
- PowerShell 5.1 或更高版本
- Windows 自带的 .NET Framework 4.8（运行 `CodexZH.exe`）

## 使用方法

1. 下载或克隆整个仓库，不要只复制其中一个脚本。
2. 双击桌面快捷方式，或 `CodexZH.exe`。
3. 在图形界面中点击 `启动汉化`，Codex 会自动重启并加载中文界面。
4. 如需恢复原界面，在同一个窗口中点击 `恢复原界面`。

如需在桌面创建启动快捷方式，可在 PowerShell 中运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-shortcut.ps1
```

运行日志和进程信息保存在：

```text
%LOCALAPPDATA%\CodexChineseOverlay
```

## 从源码构建

发布包已经包含 `CodexZH.exe`。如需重新构建控制面板，可运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

## 自定义翻译

编辑 `overlay.js` 顶部的 `exact` 映射表，按下面格式增加词条：

```js
["English text", "中文文字"],
```

修改后重新运行启动脚本即可生效。

## 注意事项

- 本项目不是 OpenAI 官方产品。
- Codex 更新后，内部页面结构或内置运行时可能变化，导致汉化失效。
- Windows 原生标题栏、菜单栏及尚未收录到词条表中的文字仍可能显示英文。
- 启动脚本会为本机 Codex 开启调试端口，并允许本机调试连接。请仅在可信的电脑上运行。
- 调试服务绑定到 `127.0.0.1`，但本机其他程序理论上仍可访问该端口。使用后可通过恢复脚本关闭调试会话。

## 免责声明

本项目按现状提供，不对因使用本工具造成的界面异常、Codex 更新不兼容或其他损失作保证。请先了解脚本行为，再决定是否使用。
