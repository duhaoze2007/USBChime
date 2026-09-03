# USBChime v1.0.1 — Release Notes

---

## English

**USBChime v1.0.1** — Play custom sounds when USB devices connect or disconnect on your Mac, just like Windows.

### What's New in v1.0.1

- 🔊 The built-in **Windows Connect** and **Windows Disconnect** sounds are now the **original Windows 10 hardware sounds** — "Windows Hardware Insert" and "Windows Hardware Remove", straight from Microsoft — instead of synthetic approximations
- 🎵 Existing installs that selected "Windows Connect / Windows Disconnect" will automatically play the new authentic sounds — no reconfiguration needed

### Features (unchanged from v1.0.0)

- 🔊 Plays a **connect chime** and a **disconnect chime** instantly when USB devices are plugged in or removed
- 🎵 9 built-in sounds, including the **original Windows 10 connect/disconnect** sounds
- 🎚️ **Custom audio files** (WAV / MP3 / AIFF / M4A) for connect and disconnect events
- 🔇 Per-event volume slider and master on/off switch
- ⌨️ Optional **ignore HID devices** (keyboard, mouse, trackpad, gamepad)
- 📋 Built-in event log showing every detected connect/disconnect
- 🚀 Launch at login support
- 🌐 Trilingual UI: English / 简体中文 / 繁體中文 (follows system or manual override)
- 🧊 Menu bar resident (LSUIElement) — no Dock clutter
- 🔒 **100% offline** — no network code, no analytics, no tracking
- 📜 MIT licensed, open source

### Installation

1. Download `USBChime.dmg` and drag `USBChime.app` into **Applications** (or replace the existing copy)
2. Launch USBChime — it lives in the **menu bar** (look for the USB-C icon)

### Requirements

- macOS 14.0 or later (Apple Silicon & Intel)

### Privacy

USBChime is completely offline. It never collects, stores, or transmits any personal data — all USB detection happens locally via IOKit.

---

## 中文

**USBChime v1.0.1** —— 在你的 Mac 上插入或拔出 USB 设备时播放可自定义的提示音，就像 Windows 一样。

### v1.0.1 更新内容

- 🔊 内置的 **Windows 连接音 / Windows 断开音** 现已替换为 **Windows 10 原装音效**——"Windows Hardware Insert" 与 "Windows Hardware Remove"，微软官方原声，不再是合成仿版
- 🎵 已安装用户只要选择了"Windows 连接音 / 断开音"，更新后会自动播放新的原装音效，无需重新设置

### 功能（与 v1.0.0 一致）

- 🔊 插入或拔出 USB 设备时**立即播放连接音与断开音**
- 🎵 内置 9 款音效，包含 **Windows 10 原装连接/断开音**
- 🎚️ 支持**自定义音频文件**（WAV / MP3 / AIFF / M4A），连接音与断开音可分别设置
- 🔇 音量滑块与总开关，独立控制
- ⌨️ 可选**忽略 HID 输入设备**（键盘、鼠标、触控板、游戏手柄）
- 📋 内置事件记录，显示每次检测到的连接/断开
- 🚀 支持登录时自动启动
- 🌐 三语界面：English / 简体中文 / 繁體中文（跟随系统或手动切换）
- 🧊 菜单栏常驻（LSUIElement），不占用 Dock
- 🔒 **完全离线**——无网络代码、无统计、无追踪
- 📜 MIT 开源许可

### 安装方法

1. 下载 `USBChime.dmg`，将 `USBChime.app` 拖入**应用程序**文件夹（或直接替换旧版本）
2. 启动 USBChime —— 它常驻**菜单栏**（找 USB-C 图标）

### 系统要求

- macOS 14.0 或更高版本（Apple Silicon 与 Intel）

### 隐私

USBChime 完全离线运行，不收集、不存储、不传输任何个人数据——所有 USB 检测都在本地通过 IOKit 完成。
