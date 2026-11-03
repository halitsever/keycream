import AudioToolbox
import CoreAudio
import Foundation

/** Follows the default output device's volume so key sounds can stay below a chosen system volume. */
final class OutputVolume {
    /** Runs on the main queue when the volume or the output device changes. */
    var onChange: (() -> Void)?

    private static let system = AudioObjectID(kAudioObjectSystemObject)
    private static let defaultDeviceAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    private static let mainVolumeAddress = address(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioObjectPropertyElementMain)

    private var device = AudioObjectID(kAudioObjectUnknown)
    /** nil when the device reports only a 0 to 1 volume and no decibels. */
    private var decibelElement: AudioObjectPropertyElement?
    private var deviceListener: AudioObjectPropertyListenerBlock?
    private var volumeListener: AudioObjectPropertyListenerBlock?

    init() {
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.followDefaultDevice() }
        var address = Self.defaultDeviceAddress
        if AudioObjectAddPropertyListenerBlock(Self.system, &address, .main, listener) == noErr {
            deviceListener = listener
        }
        followDefaultDevice()
    }

    deinit {
        stopListeningToVolume()
        if let deviceListener {
            var address = Self.defaultDeviceAddress
            AudioObjectRemovePropertyListenerBlock(Self.system, &address, .main, deviceListener)
        }
    }

    /** Multiplier that keeps output no louder than at `limit` system volume. 1 when the device has no volume control. */
    func gain(limit: Float) -> Float {
        guard limit < 1, let current = currentDecibels(), let cap = decibels(atVolume: limit), current > cap else { return 1 }
        return pow(10, (cap - current) / 20)
    }

    private func followDefaultDevice() {
        stopListeningToVolume()
        var id = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = Self.defaultDeviceAddress
        AudioObjectGetPropertyData(Self.system, &address, 0, nil, &size, &id)
        device = id
        // Some USB devices only have per-channel volume, so fall back to the first channel.
        decibelElement = [kAudioObjectPropertyElementMain, 1].first { element in
            var address = Self.address(kAudioDevicePropertyVolumeDecibels, element)
            return AudioObjectHasProperty(id, &address)
        }

        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.onChange?() }
        address = Self.mainVolumeAddress
        if AudioObjectAddPropertyListenerBlock(id, &address, .main, listener) == noErr {
            volumeListener = listener
        }
        onChange?()
    }

    private func stopListeningToVolume() {
        guard let volumeListener else { return }
        var address = Self.mainVolumeAddress
        AudioObjectRemovePropertyListenerBlock(device, &address, .main, volumeListener)
        self.volumeListener = nil
    }

    private func currentDecibels() -> Float? {
        if let decibelElement {
            return float(kAudioDevicePropertyVolumeDecibels, decibelElement)
        }
        return float(kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioObjectPropertyElementMain).map(Self.estimatedDecibels)
    }

    /** Inverts DecibelsToScalar, because ScalarToDecibels disagrees with the real level on built-in speakers. */
    private func decibels(atVolume volume: Float) -> Float? {
        guard let decibelElement else { return Self.estimatedDecibels(volume) }
        var range = AudioValueRange()
        var size = UInt32(MemoryLayout<AudioValueRange>.size)
        var address = Self.address(kAudioDevicePropertyVolumeRangeDecibels, decibelElement)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &range) == noErr else { return nil }

        var low = Float(range.mMinimum)
        var high = Float(range.mMaximum)
        for _ in 0..<16 {
            let middle = (low + high) / 2
            guard let scalar = float(kAudioDevicePropertyVolumeDecibelsToScalar, decibelElement, input: middle) else { return nil }
            if scalar < volume { low = middle } else { high = middle }
        }
        return (low + high) / 2
    }

    /** The curve built-in speakers report, used for devices that give no decibels. */
    private static func estimatedDecibels(_ volume: Float) -> Float {
        64 * (volume.squareRoot() - 1)
    }

    /** Converter properties read their input from the same buffer they write to. */
    private func float(_ selector: AudioObjectPropertySelector, _ element: AudioObjectPropertyElement, input: Float32 = 0) -> Float? {
        var address = Self.address(selector, element)
        var value = input
        var size = UInt32(MemoryLayout<Float32>.size)
        return AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr ? value : nil
    }

    private static func address(_ selector: AudioObjectPropertySelector, _ element: AudioObjectPropertyElement) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioDevicePropertyScopeOutput, mElement: element)
    }
}
