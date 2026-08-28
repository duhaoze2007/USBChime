import AppKit
import SwiftUI

/// Plays the selected sounds. Main-actor bound because NSSound is AppKit.
@MainActor
final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    private init() {}

    func playConnect() {
        play(selection: SoundSelection(storageValue: AppSettings.connectSound))
    }

    func playDisconnect() {
        play(selection: SoundSelection(storageValue: AppSettings.disconnectSound))
    }

    /// Preview any selection (used by the test buttons and pickers).
    func play(selection: SoundSelection) {
        guard let sound = makeSound(selection) else { return }
        sound.volume = Float(AppSettings.volume)
        sound.play()
    }

    private func makeSound(_ selection: SoundSelection) -> NSSound? {
        switch selection.kind {
        case .builtin(let builtin):
            if let file = builtin.resourceFile,
               let url = Bundle.module.url(forResource: file, withExtension: "wav") {
                return NSSound(contentsOf: url, byReference: true)
            }
            if let systemName = builtin.systemName {
                return NSSound(named: NSSound.Name(systemName))
            }
            return nil
        case .customFile(let url):
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return NSSound(contentsOf: url, byReference: true)
        }
    }
}
