import Foundation
import Observation

/** Settings shared by the menu and the settings window, saved as soon as they change. */
@MainActor @Observable
final class Preferences {
    enum Setting {
        case enabled, volume, soundPack, outputDevice, backgroundMode
        case toggleShortcut, menuBarIcon, appearance, checksForUpdates, language
    }

    enum Appearance: String, CaseIterable {
        case system, light, dark

        var titleKey: String { "appearance_\(rawValue)" }
    }

    private enum Key {
        static let enabled = "enabled"
        static let volume = "volume"
        static let soundPack = "soundPack"
        static let outputDeviceUID = "outputDeviceUID"
        static let outputDeviceName = "outputDeviceName"
        static let backgroundMode = "backgroundMode"
        static let toggleShortcut = "toggleShortcut"
        static let showsNameInMenuBar = "showsNameInMenuBar"
        static let dimsMenuBarIcon = "dimsMenuBarIcon"
        static let appearance = "appearance"
        static let checksForUpdates = "checksForUpdates"
    }

    /** Menu presets. Titles are string keys so they follow a language change made while the app runs. */
    static let volumeLevels: [(titleKey: String, value: Float)] = [
        ("volume_low", 0.3), ("volume_medium", 0.6), ("volume_high", 1.0),
    ]

    /** New installs start at Medium. */
    static let defaultVolume = volumeLevels[1].value

    /** Key sounds play at this share of the volume while a call or media app runs. */
    static let backgroundVolume: Float = 0.05

    @ObservationIgnored var onChange: ((Setting) -> Void)?
    @ObservationIgnored private let defaults = UserDefaults.standard

    var isEnabled: Bool {
        didSet { save(isEnabled, Key.enabled, .enabled) }
    }

    var volume: Float {
        didSet { save(volume, Key.volume, .volume) }
    }

    var soundPackID: String {
        didSet { save(soundPackID, Key.soundPack, .soundPack) }
    }

    /** The UID survives reboots and reconnects. The name labels the device while it is unplugged. */
    private(set) var outputDeviceUID: String?
    private(set) var outputDeviceName: String?

    var backgroundMode: Bool {
        didSet { save(backgroundMode, Key.backgroundMode, .backgroundMode) }
    }

    var toggleShortcut: Shortcut? {
        didSet {
            let data = toggleShortcut.flatMap { try? JSONEncoder().encode($0) }
            save(data, Key.toggleShortcut, .toggleShortcut)
        }
    }

    var showsNameInMenuBar: Bool {
        didSet { save(showsNameInMenuBar, Key.showsNameInMenuBar, .menuBarIcon) }
    }

    var dimsMenuBarIcon: Bool {
        didSet { save(dimsMenuBarIcon, Key.dimsMenuBarIcon, .menuBarIcon) }
    }

    var appearance: Appearance {
        didSet { save(appearance.rawValue, Key.appearance, .appearance) }
    }

    var checksForUpdates: Bool {
        didSet { save(checksForUpdates, Key.checksForUpdates, .checksForUpdates) }
    }

    /** nil follows the system. Stored by Localization in the key System Settings uses. */
    var language: String? {
        didSet {
            // Rewriting an unchanged value would replace the user's whole AppleLanguages list.
            guard language != Localization.override else { return }
            Localization.override = language
            onChange?(.language)
        }
    }

    init() {
        isEnabled = defaults.object(forKey: Key.enabled) as? Bool ?? true
        if let savedVolume = defaults.object(forKey: Key.volume) as? Float {
            volume = savedVolume
        } else {
            // Saved right away so a later change to the default never moves an existing install.
            volume = Self.defaultVolume
            defaults.set(Self.defaultVolume, forKey: Key.volume)
            print("Set default volume to Medium: \(Self.defaultVolume)")
        }
        soundPackID = defaults.string(forKey: Key.soundPack) ?? SoundPack.defaultID
        backgroundMode = defaults.bool(forKey: Key.backgroundMode)
        showsNameInMenuBar = defaults.bool(forKey: Key.showsNameInMenuBar)
        dimsMenuBarIcon = defaults.bool(forKey: Key.dimsMenuBarIcon)
        appearance = defaults.string(forKey: Key.appearance).flatMap(Appearance.init(rawValue:)) ?? .system
        checksForUpdates = defaults.object(forKey: Key.checksForUpdates) as? Bool ?? true
        // Optionals default to nil, so these run didSet. Nothing listens to onChange yet.
        outputDeviceUID = defaults.string(forKey: Key.outputDeviceUID)
        outputDeviceName = defaults.string(forKey: Key.outputDeviceName)
        toggleShortcut = defaults.data(forKey: Key.toggleShortcut).flatMap { try? JSONDecoder().decode(Shortcut.self, from: $0) }
        language = Localization.override
    }

    /** nil plays through the system default output. */
    func selectOutputDevice(_ device: OutputDevice?) {
        outputDeviceUID = device?.uid
        outputDeviceName = device?.name
        defaults.set(device?.uid, forKey: Key.outputDeviceUID)
        defaults.set(device?.name, forKey: Key.outputDeviceName)
        onChange?(.outputDevice)
    }

    private func save(_ value: Any?, _ key: String, _ setting: Setting) {
        defaults.set(value, forKey: key)
        onChange?(setting)
    }
}
