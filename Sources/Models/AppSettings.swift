import Foundation

/// Static UserDefaults-backed settings, readable from anywhere (views, services).
@MainActor
enum AppSettings {
    private static let defaults = UserDefaults.standard

    private enum Key {
        static let enabled        = "usbchime.enabled"
        static let volume         = "usbchime.volume"
        static let connectSound   = "usbchime.connectSound"
        static let disconnectSound = "usbchime.disconnectSound"
        static let ignoreHID      = "usbchime.ignoreHID"
        static let language       = "usbchime.language"
    }

    // MARK: - Values

    /// Master on/off switch.
    static var isEnabled: Bool {
        get { defaults.object(forKey: Key.enabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    /// Playback volume 0...1.
    static var volume: Double {
        get { min(max(defaults.object(forKey: Key.volume) as? Double ?? 0.8, 0), 1) }
        set { defaults.set(min(max(newValue, 0), 1), forKey: Key.volume) }
    }

    /// Selected sound id for connect events ("windows_connect", "soft", ... or "file:/path/to/audio").
    static var connectSound: String {
        get { defaults.string(forKey: Key.connectSound) ?? "windows_connect" }
        set { defaults.set(newValue, forKey: Key.connectSound) }
    }

    /// Selected sound id for disconnect events.
    static var disconnectSound: String {
        get { defaults.string(forKey: Key.disconnectSound) ?? "windows_disconnect" }
        set { defaults.set(newValue, forKey: Key.disconnectSound) }
    }

    /// Skip keyboard/mouse/touchpad/gamepad (USB HID class 3) devices.
    static var ignoreHID: Bool {
        get { defaults.object(forKey: Key.ignoreHID) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.ignoreHID) }
    }

    /// Language override; nil / missing means "follow system".
    static var languageOverride: String? {
        get { defaults.string(forKey: Key.language) }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Key.language)
            } else {
                defaults.removeObject(forKey: Key.language)
            }
        }
    }
}

/// Built-in sound catalog. Each entry is either a bundled resource file
/// or a macOS system sound name (played via NSSound(named:)).
enum BuiltinSound: String, CaseIterable, Identifiable {
    case windowsConnect = "windows_connect"
    case windowsDisconnect = "windows_disconnect"
    case soft = "soft"
    case pop = "pop"
    case blip = "blip"
    case systemPop = "sys_pop"
    case systemGlass = "sys_glass"
    case systemTink = "sys_tink"
    case systemBasso = "sys_basso"

    var id: String { rawValue }

    /// Bundle resource file name (without extension), or nil for system sounds.
    var resourceFile: String? {
        switch self {
        case .windowsConnect: "windows_connect"
        case .windowsDisconnect: "windows_disconnect"
        case .soft: "soft"
        case .pop: "pop"
        case .blip: "blip"
        default: nil
        }
    }

    /// NSSound(named:) system sound, or nil for bundled resources.
    var systemName: String? {
        switch self {
        case .systemPop: "Pop"
        case .systemGlass: "Glass"
        case .systemTink: "Tink"
        case .systemBasso: "Basso"
        default: nil
        }
    }
}

/// A user-selected sound: one of the built-ins, or a custom audio file.
struct SoundSelection: Equatable {
    enum Kind: Equatable {
        case builtin(BuiltinSound)
        case customFile(URL)
    }

    var kind: Kind
    /// Human-readable label (localized by caller).
    var label: String

    /// Stored form in UserDefaults ("windows_connect" or "file:/abs/path").
    var storageValue: String {
        switch kind {
        case .builtin(let s): s.rawValue
        case .customFile(let url): "file:" + url.path
        }
    }

    init(storageValue: String) {
        if storageValue.hasPrefix("file:") {
            let path = storageValue.dropFirst(5).description
            kind = .customFile(URL(fileURLWithPath: path))
            label = URL(fileURLWithPath: path).lastPathComponent
        } else if let builtin = BuiltinSound(rawValue: storageValue) {
            kind = .builtin(builtin)
            label = builtin.rawValue
        } else {
            kind = .builtin(.windowsConnect)
            label = BuiltinSound.windowsConnect.rawValue
        }
    }
}
