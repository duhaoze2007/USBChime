import Foundation
import IOKit
import IOKit.usb
import SwiftUI

/// One connect/disconnect event recorded for the event log.
struct USBEvent: Identifiable {
    enum Kind {
        case connected, disconnected
    }

    let id: UUID
    let date: Date
    let kind: Kind
    let deviceName: String

    init(date: Date, kind: Kind, deviceName: String) {
        self.id = UUID()
        self.date = date
        self.kind = kind
        self.deviceName = deviceName
    }
}

/// Watches USB devices by polling the IOKit registry.
///
/// IOKit's IOServiceAddMatchingNotification never delivered callbacks inside
/// this app (verified across run-loop sources, main-queue and dedicated-queue
/// bindings — identical code works in a bare CLI), so we poll
/// IOServiceGetMatchingServices on a short interval and diff snapshots. The
/// initial snapshot is the baseline (no sounds); subsequent diffs fire sounds.
@MainActor
final class USBDeviceMonitor: ObservableObject {
    static let shared = USBDeviceMonitor()

    @Published private(set) var events: [USBEvent] = []

    private var knownDevices: [UInt64: (name: String, hid: Bool)] = [:]
    private var lastPlayed: (kind: USBEvent.Kind, time: Date)?
    private var started = false
    private var baselineEstablished = false

    private static let deviceClasses = ["IOUSBDevice", "IOUSBHostDevice"]
    private static let pollInterval: TimeInterval = 0.7

    // MARK: - Lifecycle

    func start() {
        guard !started else { return }
        started = true

        // Baseline: current devices, no sounds.
        snapshot(establishBaseline: true)
        scheduleNextPoll()
    }

    private func scheduleNextPoll() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.pollInterval) { [weak self] in
            guard let self else { return }
            self.snapshot(establishBaseline: false)
            self.scheduleNextPoll()
        }
    }

    // MARK: - Snapshot & diff

    @MainActor
    private func snapshot(establishBaseline: Bool) {
        var current: [UInt64: (name: String, hid: Bool)] = [:]
        for klass in Self.deviceClasses {
            guard let matching = IOServiceMatching(klass) as NSMutableDictionary? else { continue }
            var iter: io_iterator_t = 0
            guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS else { continue }
            while case let device = IOIteratorNext(iter), device != 0 {
                let id = Self.registryID(of: device)
                if id != 0, current[id] == nil {
                    current[id] = (Self.deviceName(of: device), Self.isHIDDevice(device))
                }
                IOObjectRelease(device)
            }
            IOObjectRelease(iter)
        }

        if establishBaseline || !baselineEstablished {
            knownDevices = current
            baselineEstablished = true
            return
        }

        // Newly connected
        for (id, info) in current where knownDevices[id] == nil {
            knownDevices[id] = info
            if AppSettings.ignoreHID && info.hid { continue }
            logAndPlay(kind: .connected, device: info.name)
        }
        // Disconnected
        for (id, info) in knownDevices where current[id] == nil {
            knownDevices.removeValue(forKey: id)
            if AppSettings.ignoreHID && info.hid { continue }
            logAndPlay(kind: .disconnected, device: info.name)
        }
    }

    // MARK: - Log & play

    @MainActor
    private func logAndPlay(kind: USBEvent.Kind, device: String) {
        events.insert(USBEvent(date: Date(), kind: kind, deviceName: device), at: 0)
        if events.count > 100 { events.removeLast() }

        guard AppSettings.isEnabled else { return }
        let now = Date()
        if let last = lastPlayed, last.kind == kind, now.timeIntervalSince(last.time) < 0.3 {
            return // debounce duplicate events for the same physical change
        }
        lastPlayed = (kind, now)

        switch kind {
        case .connected: SoundManager.shared.playConnect()
        case .disconnected: SoundManager.shared.playDisconnect()
        }
    }

    func clearLog() {
        events.removeAll()
    }

    // MARK: - IOKit helpers (nonisolated C-friendly)

    private nonisolated static func registryID(of device: io_object_t) -> UInt64 {
        var id: UInt64 = 0
        return IORegistryEntryGetRegistryEntryID(device, &id) == KERN_SUCCESS ? id : 0
    }

    private nonisolated static func deviceName(of device: io_object_t) -> String {
        if let prop = IORegistryEntryCreateCFProperty(device, "USB Product Name" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? String, !prop.isEmpty {
            return prop.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        var name = [CChar](repeating: 0, count: 128)
        IORegistryEntryGetName(device, &name)
        let bytes = name.prefix(max(0, name.count - 1)).map { UInt8(bitPattern: $0) }
        let fallback = String(decoding: bytes, as: UTF8.self)
        return fallback.isEmpty ? "USB Device" : fallback
    }

    /// USB HID class is 3. Direct devices carry bDeviceClass == 3; composite
    /// devices (keyboards with hubs etc.) expose it on a child interface.
    private nonisolated static func isHIDDevice(_ device: io_object_t) -> Bool {
        if intProp(of: device, key: "bDeviceClass") == 3 { return true }
        var iter: io_iterator_t = 0
        guard IORegistryEntryCreateIterator(device, kIOServicePlane, IOOptionBits(kIORegistryIterateRecursively), &iter) == KERN_SUCCESS else { return false }
        defer { IOObjectRelease(iter) }
        while case let child = IOIteratorNext(iter), child != 0 {
            let isHID = intProp(of: child, key: "bInterfaceClass") == 3
            IOObjectRelease(child)
            if isHID { return true }
        }
        return false
    }

    private nonisolated static func intProp(of device: io_object_t, key: String) -> Int? {
        guard let prop = IORegistryEntryCreateCFProperty(device, key as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? NSNumber else { return nil }
        return prop.intValue
    }
}
