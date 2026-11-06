import AppKit
import ServiceManagement

/** Holds the app's state and applies each preference change to audio, keyboard monitoring and the menu bar. */
@MainActor @Observable
final class AppController {
    let preferences = Preferences()
    private(set) var packs: [SoundPack] = []
    private(set) var loadedPackID: String?
    private(set) var outputDevices: [OutputDevice] = []
    private(set) var isMonitoring = false
    private(set) var isRecordingShortcut = false
    private(set) var launchAtLoginStatus = SMAppService.mainApp.status
    private(set) var updateState = Updater.State.idle
    /** Apps that are keeping key sounds quiet right now. */
    private(set) var backgroundAppNames: [String] = []

    @ObservationIgnored var onMenuBarIconChange: (() -> Void)?
    @ObservationIgnored var onLanguageChange: (() -> Void)?

    @ObservationIgnored private var player: SoundPlayer?
    @ObservationIgnored private let devices = OutputDevices()
    @ObservationIgnored private let monitor = KeyboardMonitor()
    @ObservationIgnored private let backgroundApps = BackgroundAudioApps()
    @ObservationIgnored private let updater = Updater()
    @ObservationIgnored private var healthTimer: Timer?
    @ObservationIgnored private var shortcutRecorder: Any?
    @ObservationIgnored private var lastToggle = Date.distantPast

    private static let launchAtLoginConfiguredKey = "launchAtLoginConfigured"

    /** nil while the chosen device is unplugged, so sounds go to the system default until it is back. */
    var chosenOutputDevice: OutputDevice? {
        preferences.outputDeviceUID.flatMap { uid in outputDevices.first { $0.uid == uid } }
    }

    var isLaunchAtLoginOn: Bool {
        launchAtLoginStatus == .enabled || launchAtLoginStatus == .requiresApproval
    }

    func start() {
        packs = SoundPack.bundled()
        outputDevices = devices.all
        do {
            player = try SoundPlayer()
        } catch {
            print("Failed to start audio: \(error)")
        }

        preferences.onChange = { [weak self] in self?.apply($0) }
        backgroundApps.onChange = { [weak self] in
            guard let self else { return }
            backgroundAppNames = backgroundApps.activeAppNames
            applyVolume()
        }
        devices.onChange = { [weak self] in
            guard let self else { return }
            outputDevices = devices.all
            applyOutputDevice()
        }
        updater.onStateChange = { [weak self] in
            guard let self else { return }
            updateState = updater.state
        }
        monitor.onKeyDown = { [weak self] keyCode, flags in self?.handleKeyDown(keyCode, flags: flags) }

        applyOutputDevice()
        backgroundApps.isEnabled = preferences.backgroundMode
        applyVolume()
        loadSelectedPack()
        applyAppearance()

        enableLaunchAtLoginOnFirstRun()
        if !KeyboardMonitor.hasPermission {
            KeyboardMonitor.requestPermission()
        }
        updateMonitoring()
        // The tap can only be created once Input Monitoring is granted, and macOS may turn it off later.
        healthTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateMonitoring() }
        }
        if preferences.checksForUpdates {
            updater.check(userInitiated: false)
        }
    }

    // MARK: - Actions

    /** The menu's key equivalent and the keyboard tap both see the shortcut, so a second toggle right after is the same press. */
    func toggleEnabled() {
        guard Date().timeIntervalSince(lastToggle) > 0.3 else { return }
        lastToggle = Date()
        preferences.isEnabled.toggle()
    }

    /** A few keys in a row, so choosing a pack or a volume lets you hear it. Plays even while sounds are off. */
    func playPreview() {
        for (index, code) in ["30", "31", "57"].enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.11 * Double(index)) { [weak self] in
                self?.player?.play(code: code)
            }
        }
    }

    func setLaunchAtLogin(_ isOn: Bool) {
        let service = SMAppService.mainApp
        do {
            if isOn {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print("Launch at login change failed: \(error)")
        }
        // The user may have turned the item off in System Settings, which register() cannot override.
        if service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        refreshLaunchAtLoginStatus()
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginStatus = SMAppService.mainApp.status
    }

    func checkForUpdates() {
        updater.check(userInitiated: true)
    }

    func openPermissionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    /** Records the next key combination typed in the settings window. Esc cancels, Delete clears. */
    func startRecordingShortcut() {
        guard shortcutRecorder == nil else { return }
        isRecordingShortcut = true
        shortcutRecorder = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated { self?.record(event) }
            return nil
        }
    }

    func stopRecordingShortcut() {
        if let shortcutRecorder {
            NSEvent.removeMonitor(shortcutRecorder)
        }
        shortcutRecorder = nil
        isRecordingShortcut = false
    }

    private func record(_ event: NSEvent) {
        let hasModifiers = !event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty
        switch event.keyCode {
        case 53 where !hasModifiers:
            stopRecordingShortcut()
        case 51 where !hasModifiers, 117 where !hasModifiers:
            preferences.toggleShortcut = nil
            stopRecordingShortcut()
        default:
            guard let shortcut = Shortcut(event: event) else {
                NSSound.beep()
                return
            }
            preferences.toggleShortcut = shortcut
            stopRecordingShortcut()
        }
    }

    // MARK: - Applying preferences

    private func apply(_ setting: Preferences.Setting) {
        switch setting {
        case .enabled, .toggleShortcut: updateMonitoring()
        case .volume: applyVolume()
        case .soundPack: loadSelectedPack()
        case .outputDevice: applyOutputDevice()
        case .backgroundMode: backgroundApps.isEnabled = preferences.backgroundMode
        case .menuBarIcon: onMenuBarIconChange?()
        case .appearance: applyAppearance()
        case .language: onLanguageChange?()
        case .checksForUpdates: break
        }
    }

    private func applyVolume() {
        let background = backgroundApps.isActive ? Preferences.backgroundVolume : 1
        player?.volume = preferences.volume * background
    }

    private func applyOutputDevice() {
        player?.setOutputDevice(chosenOutputDevice?.id)
    }

    private func loadSelectedPack() {
        let id = preferences.soundPackID
        guard id != loadedPackID else { return }
        if load(id) { return }
        if loadedPackID == nil, id != SoundPack.defaultID {
            load(SoundPack.defaultID)
        }
        // Keeps the menu and settings on the pack that is actually playing.
        if let loadedPackID, loadedPackID != id {
            preferences.soundPackID = loadedPackID
        }
    }

    @discardableResult
    private func load(_ id: String) -> Bool {
        guard let player, let pack = packs.first(where: { $0.id == id }) else { return false }
        do {
            try player.load(pack)
            loadedPackID = pack.id
            return true
        } catch {
            print("Failed to load sound pack \(id): \(error)")
            return false
        }
    }

    private func applyAppearance() {
        switch preferences.appearance {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    /** The tap also runs while sounds are off when a shortcut is set, so the shortcut can turn them back on. */
    private func updateMonitoring() {
        let isNeeded = preferences.isEnabled || preferences.toggleShortcut != nil
        if !isNeeded || !KeyboardMonitor.hasPermission {
            monitor.stop()
        } else if !monitor.isHealthy {
            monitor.stop()
            _ = monitor.start()
        }
        if isMonitoring != monitor.isRunning {
            isMonitoring = monitor.isRunning
        }
    }

    private func handleKeyDown(_ keyCode: Int64, flags: CGEventFlags?) {
        if !isRecordingShortcut, let flags, preferences.toggleShortcut?.matches(keyCode: keyCode, flags: flags) == true {
            toggleEnabled()
            return
        }
        guard preferences.isEnabled, let code = KeyCodeMap.mechvibesCode(for: keyCode) else { return }
        player?.play(code: code)
    }

    /** On by default, but only once, so turning it off sticks. */
    private func enableLaunchAtLoginOnFirstRun() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.launchAtLoginConfiguredKey) else { return }
        do {
            try SMAppService.mainApp.register()
            defaults.set(true, forKey: Self.launchAtLoginConfiguredKey)
        } catch {
            print("Launch at login registration failed: \(error)")
        }
        refreshLaunchAtLoginStatus()
    }
}
