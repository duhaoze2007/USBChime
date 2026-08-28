import SwiftUI
import AppKit

@main
struct USBChimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var monitor = USBDeviceMonitor.shared
    @StateObject private var sounds = SoundManager.shared
    @StateObject private var locale = LocalizationManager.shared

    init() {
        // App.init is guaranteed to run (applicationDidFinishLaunching is not
        // reliably delivered on MenuBarExtra-only apps), so start the USB
        // watcher here. USBDeviceMonitor.start() is guarded against repeats.
        USBDeviceMonitor.shared.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(locale)
                .environmentObject(monitor)
        } label: {
            Image(systemName: "cable.connector")
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("USBChime: applicationDidFinishLaunching called")
        NSApp.setActivationPolicy(.accessory)
        USBDeviceMonitor.shared.start()

        // Delay so the menu bar item is live before any modal appears.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.showFirstLaunchDialogsIfNeeded()
        }
    }

    // MARK: - First-launch dialogs

    private func showFirstLaunchDialogsIfNeeded() {
        // Only prompt for copies launched from /Applications (dev copies skip).
        guard Bundle.main.bundlePath.hasPrefix("/Applications/") else { return }
        let key = "USBChime_FirstRun_" + Bundle.main.bundlePath
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let locale = LocalizationManager.shared

        // 1) Copyright
        let copyright = NSAlert()
        copyright.messageText = locale[.firstRunCopyrightTitle]
        copyright.informativeText = locale[.firstRunCopyrightBody]
        copyright.alertStyle = .informational
        copyright.icon = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: nil)
        copyright.addButton(withTitle: locale[.agree])
        copyright.addButton(withTitle: locale[.disagree])
        guard copyright.runModal() == .alertFirstButtonReturn else {
            NSApp.terminate(nil)
            return
        }

        // 2) Privacy
        let privacy = NSAlert()
        privacy.messageText = locale[.firstRunPrivacyTitle]
        privacy.informativeText = locale[.firstRunPrivacyBody]
        privacy.alertStyle = .informational
        privacy.icon = NSImage(systemSymbolName: "hand.raised.fill", accessibilityDescription: nil)
        privacy.addButton(withTitle: locale[.agree])
        privacy.addButton(withTitle: locale[.disagree])
        guard privacy.runModal() == .alertFirstButtonReturn else {
            NSApp.terminate(nil)
            return
        }

        UserDefaults.standard.set(true, forKey: key)
    }
}
