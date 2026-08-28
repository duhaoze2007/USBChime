import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var id: String { rawValue }

    static func detectSystem() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-TW") || preferred.hasPrefix("zh-HK") {
            return .traditionalChinese
        }
        if preferred.hasPrefix("zh") { return .simplifiedChinese }
        return .english
    }
}

enum L10nKey: String, CaseIterable {
    // General
    case appName, menuBarTitle
    case enableSounds, volume, ignoreHID, ignoreHIDHint
    case settings, quit, about
    case connectSound, disconnectSound, testConnect, testDisconnect
    case openSettings, eventLog, clearLog, noEvents
    case customSound, chooseCustomFile, removeCustom, restoreDefault, playPreview
    case launchAtLogin, versionLabel, language, followSystem
    case tabGeneral, tabSounds, tabEvents, tabAbout
    case copyright, privacyTitle, privacyBody
    case firstRunCopyrightTitle, firstRunCopyrightBody, firstRunPrivacyTitle, firstRunPrivacyBody
    case agree, disagree
    case connected, disconnected, time, device
    case builtinWindowsConnect, builtinWindowsDisconnect, builtinSoft, builtinPop, builtinBlip
    case builtinSystemPop, builtinSystemGlass, builtinSystemTink, builtinSystemBasso
    case custom, soundFiles
    case logHint, aboutBody, mitLicense
    case noAudioFile
}

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage {
        didSet {
            AppSettings.languageOverride = (language == .system) ? nil : language.rawValue
            syncAppleLanguages()
        }
    }

    /// The language actually in use (resolves .system).
    var resolved: AppLanguage {
        language == .system ? AppLanguage.detectSystem() : language
    }

    private init() {
        if let saved = AppSettings.languageOverride,
           let lang = AppLanguage(rawValue: saved) {
            self.language = lang
        } else {
            self.language = .system
        }
        syncAppleLanguages()
    }

    /// Keep AppKit-level UI (open panels etc.) in sync with the in-app choice.
    private func syncAppleLanguages() {
        switch resolved {
        case .english:
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        case .simplifiedChinese:
            UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")
        case .traditionalChinese:
            UserDefaults.standard.set(["zh-Hant"], forKey: "AppleLanguages")
        case .system:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    subscript(key: L10nKey) -> String {
        strings[key]?[resolved] ?? strings[key]?[.english] ?? key.rawValue
    }

    private let strings: [L10nKey: [AppLanguage: String]] = [
        .appName: [.english: "USBChime", .simplifiedChinese: "USBChime", .traditionalChinese: "USBChime"],
        .menuBarTitle: [.english: "USBChime", .simplifiedChinese: "USB提示音", .traditionalChinese: "USB提示音"],

        .enableSounds: [.english: "USB sounds", .simplifiedChinese: "启用 USB 提示音", .traditionalChinese: "啟用 USB 提示音"],
        .volume: [.english: "Volume", .simplifiedChinese: "音量", .traditionalChinese: "音量"],
        .ignoreHID: [.english: "Ignore HID devices", .simplifiedChinese: "忽略 HID 输入设备", .traditionalChinese: "忽略 HID 輸入裝置"],
        .ignoreHIDHint: [.english: "Keyboard, mouse, trackpad and gamepad", .simplifiedChinese: "键盘、鼠标、触控板和游戏手柄", .traditionalChinese: "鍵盤、滑鼠、觸控板和遊戲手把"],

        .settings: [.english: "Settings…", .simplifiedChinese: "设置…", .traditionalChinese: "設定…"],
        .quit: [.english: "Quit USBChime", .simplifiedChinese: "退出 USBChime", .traditionalChinese: "結束 USBChime"],
        .about: [.english: "About", .simplifiedChinese: "关于", .traditionalChinese: "關於"],

        .connectSound: [.english: "Connect sound", .simplifiedChinese: "连接提示音", .traditionalChinese: "連接提示音"],
        .disconnectSound: [.english: "Disconnect sound", .simplifiedChinese: "断开提示音", .traditionalChinese: "斷開提示音"],
        .testConnect: [.english: "Test connect sound", .simplifiedChinese: "试听连接音", .traditionalChinese: "試聽連接音"],
        .testDisconnect: [.english: "Test disconnect sound", .simplifiedChinese: "试听断开音", .traditionalChinese: "試聽斷開音"],

        .openSettings: [.english: "Open Settings", .simplifiedChinese: "打开设置", .traditionalChinese: "開啟設定"],
        .eventLog: [.english: "Event Log", .simplifiedChinese: "事件记录", .traditionalChinese: "事件記錄"],
        .clearLog: [.english: "Clear", .simplifiedChinese: "清空", .traditionalChinese: "清空"],
        .noEvents: [.english: "No events yet. Plug in a USB device to test.", .simplifiedChinese: "暂无事件。插入 USB 设备即可测试。", .traditionalChinese: "尚無事件。插入 USB 裝置即可測試。"],

        .customSound: [.english: "Custom audio file…", .simplifiedChinese: "自定义音频文件…", .traditionalChinese: "自訂音訊檔案…"],
        .chooseCustomFile: [.english: "Choose Audio File…", .simplifiedChinese: "选择音频文件…", .traditionalChinese: "選擇音訊檔案…"],
        .removeCustom: [.english: "Remove custom file", .simplifiedChinese: "移除自定义文件", .traditionalChinese: "移除自訂檔案"],
        .restoreDefault: [.english: "Restore Default", .simplifiedChinese: "恢复默认", .traditionalChinese: "恢復預設"],
        .playPreview: [.english: "Play", .simplifiedChinese: "试听", .traditionalChinese: "試聽"],

        .launchAtLogin: [.english: "Launch at login", .simplifiedChinese: "登录时自动启动", .traditionalChinese: "登入時自動啟動"],
        .versionLabel: [.english: "Version", .simplifiedChinese: "版本", .traditionalChinese: "版本"],
        .language: [.english: "Language", .simplifiedChinese: "语言", .traditionalChinese: "語言"],
        .followSystem: [.english: "Follow System", .simplifiedChinese: "跟随系统", .traditionalChinese: "跟隨系統"],

        .tabGeneral: [.english: "General", .simplifiedChinese: "通用", .traditionalChinese: "一般"],
        .tabSounds: [.english: "Sounds", .simplifiedChinese: "声音", .traditionalChinese: "聲音"],
        .tabEvents: [.english: "Events", .simplifiedChinese: "事件", .traditionalChinese: "事件"],
        .tabAbout: [.english: "About", .simplifiedChinese: "关于", .traditionalChinese: "關於"],

        .copyright: [.english: "Copyright © 2026 Du Haoze. MIT License.", .simplifiedChinese: "Copyright © 2026 Du Haoze. MIT License.", .traditionalChinese: "Copyright © 2026 Du Haoze. MIT License."],

        .privacyTitle: [.english: "Privacy Policy", .simplifiedChinese: "隐私政策", .traditionalChinese: "隱私政策"],
        .privacyBody: [.english: "USBChime is completely offline. It never collects, stores, or transmits any personal data. USB device detection happens entirely on your Mac using IOKit — no network access, no analytics, no tracking.", .simplifiedChinese: "USBChime 完全离线运行。它不收集、不存储、不传输任何个人数据。USB 设备检测完全在你的 Mac 本地通过 IOKit 完成——无网络访问、无统计、无追踪。", .traditionalChinese: "USBChime 完全離線執行。它不收集、不儲存、不傳輸任何個人資料。USB 裝置偵測完全在你的 Mac 本地透過 IOKit 完成——無網路存取、無統計、無追蹤。"],

        .firstRunCopyrightTitle: [.english: "Copyright Notice", .simplifiedChinese: "版权声明", .traditionalChinese: "版權聲明"],
        .firstRunCopyrightBody: [.english: "Copyright © 2026 Du Haoze. All rights reserved.\n\nUSBChime is licensed under the MIT License. You may use, copy, modify, and distribute this software in accordance with the license terms.", .simplifiedChinese: "Copyright © 2026 Du Haoze. 保留所有权利。\n\nUSBChime 采用 MIT License 开源许可。你可以依据许可条款使用、复制、修改和分发本软件。", .traditionalChinese: "Copyright © 2026 Du Haoze. 保留所有權利。\n\nUSBChime 採用 MIT License 開源授權。你可以依據授權條款使用、複製、修改和散布本軟體。"],
        .firstRunPrivacyTitle: [.english: "Privacy Notice", .simplifiedChinese: "隐私声明", .traditionalChinese: "隱私聲明"],
        .firstRunPrivacyBody: [.english: "USBChime is completely offline and collects no data.\n\nIt only watches USB device connect/disconnect events locally via IOKit and plays sounds on your Mac. No network connection, no analytics, no personal information leaves your device.", .simplifiedChinese: "USBChime 完全离线，不收集任何数据。\n\n它仅在本地通过 IOKit 监听 USB 设备的连接/断开事件，并在你的 Mac 上播放提示音。无网络连接、无统计、无任何个人信息离开你的设备。", .traditionalChinese: "USBChime 完全離線，不收集任何資料。\n\n它僅在本地透過 IOKit 監聽 USB 裝置的連接/斷開事件，並在你的 Mac 上播放提示音。無網路連線、無統計、無任何個人資訊離開你的裝置。"],

        .agree: [.english: "Agree", .simplifiedChinese: "同意", .traditionalChinese: "同意"],
        .disagree: [.english: "Disagree", .simplifiedChinese: "不同意", .traditionalChinese: "不同意"],

        .connected: [.english: "Connected", .simplifiedChinese: "已连接", .traditionalChinese: "已連接"],
        .disconnected: [.english: "Disconnected", .simplifiedChinese: "已断开", .traditionalChinese: "已斷開"],
        .time: [.english: "Time", .simplifiedChinese: "时间", .traditionalChinese: "時間"],
        .device: [.english: "Device", .simplifiedChinese: "设备", .traditionalChinese: "裝置"],

        .builtinWindowsConnect: [.english: "Windows Connect", .simplifiedChinese: "Windows 连接音", .traditionalChinese: "Windows 連接音"],
        .builtinWindowsDisconnect: [.english: "Windows Disconnect", .simplifiedChinese: "Windows 断开音", .traditionalChinese: "Windows 斷開音"],
        .builtinSoft: [.english: "Soft Chime", .simplifiedChinese: "柔和提示", .traditionalChinese: "柔和提示"],
        .builtinPop: [.english: "Pop", .simplifiedChinese: "轻快 Pop", .traditionalChinese: "輕快 Pop"],
        .builtinBlip: [.english: "Blip", .simplifiedChinese: "短促 Blip", .traditionalChinese: "短促 Blip"],
        .builtinSystemPop: [.english: "System: Pop", .simplifiedChinese: "系统音效：Pop", .traditionalChinese: "系統音效：Pop"],
        .builtinSystemGlass: [.english: "System: Glass", .simplifiedChinese: "系统音效：Glass", .traditionalChinese: "系統音效：Glass"],
        .builtinSystemTink: [.english: "System: Tink", .simplifiedChinese: "系统音效：Tink", .traditionalChinese: "系統音效：Tink"],
        .builtinSystemBasso: [.english: "System: Basso", .simplifiedChinese: "系统音效：Basso", .traditionalChinese: "系統音效：Basso"],

        .custom: [.english: "Custom", .simplifiedChinese: "自定义", .traditionalChinese: "自訂"],
        .soundFiles: [.english: "Audio files (WAV, MP3, AIFF, M4A)", .simplifiedChinese: "音频文件（WAV、MP3、AIFF、M4A）", .traditionalChinese: "音訊檔案（WAV、MP3、AIFF、M4A）"],

        .logHint: [.english: "Recent USB events detected by USBChime.", .simplifiedChinese: "USBChime 检测到的最近 USB 事件。", .traditionalChinese: "USBChime 偵測到的最近 USB 事件。"],
        .aboutBody: [.english: "Play custom sounds when USB devices connect or disconnect on your Mac — just like Windows.", .simplifiedChinese: "在 Mac 上插入或拔出 USB 设备时播放可自定义的提示音，就像 Windows 一样。", .traditionalChinese: "在 Mac 上插入或拔出 USB 裝置時播放可自訂的提示音，就像 Windows 一樣。"],
        .mitLicense: [.english: "Open source under the MIT License. Completely offline.", .simplifiedChinese: "基于 MIT License 开源。完全离线运行。", .traditionalChinese: "基於 MIT License 開源。完全離線執行。"],

        .noAudioFile: [.english: "File not found — it may have been moved.", .simplifiedChinese: "找不到音频文件，它可能已被移动。", .traditionalChinese: "找不到音訊檔案，它可能已被移動。"],
    ]
}
