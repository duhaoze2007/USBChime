# USBChime

Play custom sounds when USB devices connect or disconnect on your Mac — just like Windows. A lightweight menu bar app for Apple Silicon & Intel Macs, built with SwiftUI + IOKit.

---

# USBChime

在你的 Mac 上插入或拔出 USB 设备时播放可自定义的提示音，就像 Windows 一样。基于 SwiftUI + IOKit 的轻量菜单栏 App，支持 Apple Silicon 与 Intel Mac。

---

## Features / 功能

- Plays a **connect chime** and a **disconnect chime** the moment a USB device is plugged in or removed
- 9 built-in sounds, including the **original Windows 10 connect/disconnect** sounds
- **Custom audio files** (WAV, MP3, AIFF, M4A) for either event
- Per-event volume slider and master on/off switch
- **Ignore HID devices** (keyboard, mouse, trackpad, gamepad) — optional
- Built-in event log showing every detected connect/disconnect
- Launch at login support
- Trilingual UI: **English / 简体中文 / 繁體中文** (follows system or manual override)
- Menu bar resident (LSUIElement) — no Dock clutter
- **100% offline**: no network code, no analytics, no tracking
- MIT licensed, open source

---

- 插入或拔出 USB 设备时立即播放**连接音**与**断开音**
- 内置 9 款音效，包含 **Windows 10 原装连接/断开音**
- 支持**自定义音频文件**（WAV、MP3、AIFF、M4A）分别设置连接音与断开音
- 音量滑块与总开关，独立控制
- **忽略 HID 输入设备**（键盘、鼠标、触控板、游戏手柄）——可选
- 内置事件记录，显示每次检测到的连接/断开
- 支持登录时自动启动
- 三语界面：**English / 简体中文 / 繁體中文**（跟随系统或手动切换）
- 菜单栏常驻（LSUIElement），不占用 Dock
- **完全离线**：无网络代码、无统计、无追踪
- MIT 开源许可

---

## Requirements / 系统要求

- macOS 14.0 or later / macOS 14.0 或更高版本
- Apple Silicon or Intel / Apple Silicon 或 Intel

## Dependencies / 依赖

**Zero external dependencies** — the app uses only Apple system frameworks (SwiftUI, AppKit, IOKit, ServiceManagement) and is built with Swift Package Manager. No Xcode required; the Command Line Tools toolchain is sufficient.

**零外部依赖** — 仅使用 Apple 系统框架（SwiftUI、AppKit、IOKit、ServiceManagement），Swift Package Manager 构建，无需 Xcode，安装 Command Line Tools 即可。

---

## Build / 构建

```bash
bash build.sh
```

The script builds in release mode, bundles `USBChime.app` with resources (sounds + icon), and ad-hoc signs it.

脚本以 release 模式构建，将资源（音效 + 图标）打包进 `USBChime.app` 并完成 ad-hoc 签名。

### Run / 运行

```bash
open USBChime.app
```

Click the USB-C icon in the menu bar to toggle sounds, pick sounds, adjust volume, or open Settings (⌘,).

点击菜单栏的 USB-C 图标即可开关提示音、选择音效、调节音量或打开设置（⌘,）。

---

## How it works / 工作原理

USBChime watches the IOKit registry (`IOUSBDevice` and `IOUSBHostDevice` — both exist on Apple Silicon Macs) and diffs periodic snapshots to detect connect/disconnect events. On Apple Silicon, USB-C devices can be reported under both service classes, so registry-entry IDs are used to deduplicate. An initial baseline snapshot ensures devices already attached at launch never trigger a false connect sound.

USBChime 通过 IOKit 注册表（`IOUSBDevice` 与 `IOUSBHostDevice`——Apple Silicon Mac 上两者并存）周期性快照对比来检测连接/断开事件。Apple Silicon 上 USB-C 设备可能同时出现在两个服务类下，因此使用 registry entry ID 去重。启动时的首次快照作为基线，确保已连接的设备不会误触发连接音。

---

## Privacy / 隐私

USBChime is completely offline. It never collects, stores, or transmits any personal data. All USB detection happens locally on your Mac via IOKit.

USBChime 完全离线运行。它不收集、不存储、不传输任何个人数据，所有 USB 检测都在你的 Mac 本地通过 IOKit 完成。

---

## License / 许可证

MIT License — see [LICENSE](LICENSE) for details.

MIT License — 详见 [LICENSE](LICENSE)。
