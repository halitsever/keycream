import CoreAudio
import Foundation

struct OutputDevice: Hashable, Identifiable {
    let id: AudioObjectID
    /** Unlike `id`, stays the same across restarts and reconnects. */
    let uid: String
    let name: String
}

/** The Mac's audio outputs, refreshed when one is plugged in or removed or the default output changes. */
final class OutputDevices {
    /** Runs on the main queue. */
    var onChange: (() -> Void)?
    private(set) var all: [OutputDevice] = []

    private static let system = AudioObjectID(kAudioObjectSystemObject)
    private static let watchedAddresses = [
        AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain),
        AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain),
    ]
    private var listener: AudioObjectPropertyListenerBlock?

    init() {
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.refresh()
            self?.onChange?()
        }
        for var address in Self.watchedAddresses {
            AudioObjectAddPropertyListenerBlock(Self.system, &address, .main, listener)
        }
        self.listener = listener
        refresh()
    }

    deinit {
        guard let listener else { return }
        for var address in Self.watchedAddresses {
            AudioObjectRemovePropertyListenerBlock(Self.system, &address, .main, listener)
        }
    }

    static var defaultDeviceID: AudioObjectID {
        var address = watchedAddresses[1]
        var id = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(system, &address, 0, nil, &size, &id)
        return id
    }

    private func refresh() {
        var address = Self.watchedAddresses[0]
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(Self.system, &address, 0, nil, &size) == noErr else { return }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(Self.system, &address, 0, nil, &size, &ids) == noErr else { return }
        all = ids.compactMap { id in
            guard Self.hasOutputStreams(id), !Self.isHidden(id),
                  let uid = Self.string(id, kAudioDevicePropertyDeviceUID),
                  let name = Self.string(id, kAudioObjectPropertyName) else { return nil }
            return OutputDevice(id: id, uid: uid, name: name)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func hasOutputStreams(_ device: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreams, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr && size > 0
    }

    private static func isHidden(_ device: AudioObjectID) -> Bool {
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyIsHidden, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var hidden: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(device, &address, 0, nil, &size, &hidden) == noErr && hidden != 0
    }

    private static func string(_ device: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr, let value else { return nil }
        return value.takeRetainedValue() as String
    }
}
