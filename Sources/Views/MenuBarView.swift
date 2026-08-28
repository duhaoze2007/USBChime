import SwiftUI
import AppKit

/// The menu bar dropdown.
struct MenuBarView: View {
    @EnvironmentObject private var locale: LocalizationManager
    @AppStorage("usbchime.enabled") private var enabled = true
    @AppStorage("usbchime.volume") private var volume = 0.8

    var body: some View {
        Toggle(locale[.enableSounds], isOn: $enabled)

        Divider()

        SoundPickerMenu(kind: .connect)
        SoundPickerMenu(kind: .disconnect)

        Divider()

        VStack(spacing: 4) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                Text(locale[.volume])
                Spacer()
                Text("\(Int(volume * 100))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $volume, in: 0...1)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)

        Divider()

        Button {
            SoundManager.shared.playConnect()
        } label: {
            Label(locale[.testConnect], systemImage: "play.circle")
        }
        Button {
            SoundManager.shared.playDisconnect()
        } label: {
            Label(locale[.testDisconnect], systemImage: "play.circle")
        }

        Divider()

        Button {
            SettingsWindowController.shared.open()
        } label: {
            Label(locale[.openSettings], systemImage: "gearshape")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button {
            NSApp.terminate(nil)
        } label: {
            Label(locale[.quit], systemImage: "power")
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

/// A submenu that picks one sound for an event kind, with preview + custom file.
struct SoundPickerMenu: View {
    enum Kind {
        case connect, disconnect
    }

    let kind: Kind
    @EnvironmentObject private var locale: LocalizationManager
    @State private var selection: SoundSelection

    init(kind: Kind) {
        self.kind = kind
        let key = kind == .connect ? "usbchime.connectSound" : "usbchime.disconnectSound"
        _selection = State(initialValue: SoundSelection(storageValue: UserDefaults.standard.string(forKey: key) ?? (kind == .connect ? "windows_connect" : "windows_disconnect")))
    }

    var body: some View {
        Menu {
            ForEach(BuiltinSound.allCases) { builtin in
                let option = SoundSelection(storageValue: builtin.rawValue)
                Button {
                    select(option)
                } label: {
                    if selection == option {
                        Label(label(for: builtin), systemImage: "checkmark")
                    } else {
                        Text(label(for: builtin))
                    }
                }
            }

            Divider()

            if case .customFile(let url) = selection.kind {
                Button {
                    select(.init(storageValue: "file:" + url.path))
                } label: {
                    Label(url.lastPathComponent, systemImage: "checkmark")
                }
            }

            Button(locale[.customSound]) {
                chooseCustomFile()
            }
        } label: {
            Text(kind == .connect ? locale[.connectSound] : locale[.disconnectSound])
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

    private func select(_ option: SoundSelection) {
        selection = option
        let key = kind == .connect ? "usbchime.connectSound" : "usbchime.disconnectSound"
        UserDefaults.standard.set(option.storageValue, forKey: key)
        SoundManager.shared.play(selection: option)
    }

    private func chooseCustomFile() {
        let panel = NSOpenPanel()
        panel.title = locale[.chooseCustomFile]
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        // Pop after the menu closes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard panel.runModal() == .OK, let url = panel.url else { return }
            select(.init(storageValue: "file:" + url.path))
        }
    }
}
