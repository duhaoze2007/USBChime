import SwiftUI
import AppKit
import ServiceManagement

/// Singleton settings window (menu bar apps have no Settings scene in SPM builds).
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func open(initialTab: SettingsTab? = nil) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            if let initialTab {
                window.contentViewController?.view.window?.setValue(initialTab.rawValue, forKey: "initialTab")
                // Tabs are driven by the view's @State; simplest: notify via NSNotification
                NotificationCenter.default.post(name: .switchSettingsTab, object: initialTab)
            }
            return
        }

        let view = SettingsView()
            .environmentObject(LocalizationManager.shared)
            .environmentObject(USBDeviceMonitor.shared)
        let controller = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: controller)
        win.title = LocalizationManager.shared[.appName] + " — " + LocalizationManager.shared[.settings]
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.setContentSize(NSSize(width: 620, height: 520))
        win.center()
        win.delegate = self
        win.isReleasedWhenClosed = false
        window = win

        if let initialTab {
            NotificationCenter.default.post(name: .switchSettingsTab, object: initialTab)
        }
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

enum SettingsTab: Int {
    case general = 0
    case sounds = 1
    case events = 2
    case about = 3
}

extension Notification.Name {
    static let switchSettingsTab = Notification.Name("USBChimeSwitchSettingsTab")
}

/// The full settings window content.
struct SettingsView: View {
    @EnvironmentObject private var locale: LocalizationManager
    @EnvironmentObject private var monitor: USBDeviceMonitor
    @State private var tab: SettingsTab = .general

    var body: some View {
        TabView(selection: $tab) {
            GeneralTab()
                .tabItem { Label(locale[.tabGeneral], systemImage: "switch.2") }
                .tag(SettingsTab.general)
            SoundsTab()
                .tabItem { Label(locale[.tabSounds], systemImage: "music.note") }
                .tag(SettingsTab.sounds)
            EventsTab()
                .tabItem { Label(locale[.tabEvents], systemImage: "list.bullet.rectangle") }
                .tag(SettingsTab.events)
            AboutTab()
                .tabItem { Label(locale[.tabAbout], systemImage: "info.circle") }
                .tag(SettingsTab.about)
        }
        .frame(width: 620, height: 520)
        .onReceive(NotificationCenter.default.publisher(for: .switchSettingsTab)) { note in
            if let tabValue = note.object as? SettingsTab {
                tab = tabValue
            }
        }
    }
}

// MARK: - General

struct GeneralTab: View {
    @EnvironmentObject private var locale: LocalizationManager
    @AppStorage("usbchime.enabled") private var enabled = true
    @AppStorage("usbchime.volume") private var volume = 0.8
    @AppStorage("usbchime.ignoreHID") private var ignoreHID = true
    @State private var loginItemError: String?

    var body: some View {
        Form {
            Toggle(locale[.enableSounds], isOn: $enabled)

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(locale[.volume])
                        Spacer()
                        Text("\(Int(volume * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $volume, in: 0...1)
                }
                .disabled(!enabled)

                VStack(alignment: .leading, spacing: 4) {
                    Toggle(locale[.ignoreHID], isOn: $ignoreHID)
                    Text(locale[.ignoreHIDHint])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(locale[.menuBarTitle])
            }

            Section {
                Toggle(locale[.launchAtLogin], isOn: Binding(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            loginItemError = nil
                        } catch {
                            loginItemError = error.localizedDescription
                        }
                    }
                ))
                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text(locale[.menuBarTitle])
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }
}

// MARK: - Sounds

struct SoundsTab: View {
    @EnvironmentObject private var locale: LocalizationManager
    @AppStorage("usbchime.connectSound") private var connectSound = "windows_connect"
    @AppStorage("usbchime.disconnectSound") private var disconnectSound = "windows_disconnect"

    var body: some View {
        Form {
            Section {
                soundRow(
                    title: locale[.connectSound],
                    key: "usbchime.connectSound",
                    selection: $connectSound,
                    testAction: { SoundManager.shared.playConnect() }
                )
                soundRow(
                    title: locale[.disconnectSound],
                    key: "usbchime.disconnectSound",
                    selection: $disconnectSound,
                    testAction: { SoundManager.shared.playDisconnect() }
                )
            } header: {
                Text(locale[.tabSounds])
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }

    private func soundRow(title: String, key: String, selection: Binding<String>, testAction: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Picker("", selection: selection) {
                ForEach(BuiltinSound.allCases) { builtin in
                    Text(label(for: builtin)).tag(builtin.rawValue)
                }
                if selection.wrappedValue.hasPrefix("file:") {
                    Text(SoundSelection(storageValue: selection.wrappedValue).label)
                        .tag(selection.wrappedValue)
                }
            }
            .labelsHidden()
            .frame(width: 220)
            .onChange(of: selection.wrappedValue) { _, newValue in
                let option = SoundSelection(storageValue: newValue)
                SoundManager.shared.play(selection: option)
            }
            Button(action: testAction) {
                Image(systemName: "play.circle")
            }
            .help(locale[.playPreview])
        }
    }

    private func label(for builtin: BuiltinSound) -> String {
        switch builtin {
        case .windowsConnect: locale[.builtinWindowsConnect]
        case .windowsDisconnect: locale[.builtinWindowsDisconnect]
        case .soft: locale[.builtinSoft]
        case .pop: locale[.builtinPop]
        case .blip: locale[.builtinBlip]
        case .systemPop: locale[.builtinSystemPop]
        case .systemGlass: locale[.builtinSystemGlass]
        case .systemTink: locale[.builtinSystemTink]
        case .systemBasso: locale[.builtinSystemBasso]
        }
    }
}

// MARK: - Events

struct EventsTab: View {
    @EnvironmentObject private var locale: LocalizationManager
    @EnvironmentObject private var monitor: USBDeviceMonitor

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(locale[.logHint])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(locale[.clearLog]) {
                    monitor.clearLog()
                }
                .disabled(monitor.events.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            if monitor.events.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "cable.connector")
                        .font(.system(size: 34))
                        .foregroundStyle(.tertiary)
                    Text(locale[.noEvents])
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List(monitor.events) { event in
                    HStack(spacing: 10) {
                        Image(systemName: event.kind == .connected ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundStyle(event.kind == .connected ? .green : .orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(event.deviceName)
                                .lineLimit(1)
                            Text(event.kind == .connected ? locale[.connected] : locale[.disconnected])
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Self.timeFormatter.string(from: event.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}

// MARK: - About

struct AboutTab: View {
    @EnvironmentObject private var locale: LocalizationManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 56, height: 56)
            Text(locale[.appName])
                .font(.title2.bold())
                .padding(.top, 10)
            Text(locale[.aboutBody])
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
                .padding(.horizontal, 48)

            VStack(spacing: 4) {
                Text("\(locale[.versionLabel]) 1.0.0 (1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(locale[.copyright])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(locale[.mitLicense])
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)

            Divider()
                .padding(.horizontal, 48)
                .padding(.vertical, 14)

            // Language
            HStack {
                Text(locale[.language])
                Spacer()
                Picker("", selection: languageBinding) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(displayName(for: lang)).tag(lang)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 18)
            Spacer()
        }
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { LocalizationManager.shared.language },
            set: { LocalizationManager.shared.language = $0 }
        )
    }

    private func displayName(for lang: AppLanguage) -> String {
        switch lang {
        case .system:
            let detected = AppLanguage.detectSystem()
            let flag = detected == .simplifiedChinese ? " (简体)" : (detected == .traditionalChinese ? " (繁體)" : " (English)")
            return locale[.followSystem] + flag
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        }
    }
}
