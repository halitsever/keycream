import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum DefaultsKey {
        static let enabled = "enabled"
        static let volume = "volume"
        static let launchAtLoginConfigured = "launchAtLoginConfigured"
        static let soundPack = "soundPack"
    }

    /** Titles are string keys so they follow a language change made while the app runs. */
    private let volumeLevels: [(titleKey: String, value: Float)] = [
        ("volume_low", 0.3), ("volume_medium", 0.6), ("volume_high", 1.0),
    ]

    private var statusItem: NSStatusItem!
    private var player: SoundPlayer?
    private var packs: [SoundPack] = []
    private var loadedPackID: String?
    private let monitor = KeyboardMonitor()
    private var permissionTimer: Timer?

    private var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: DefaultsKey.enabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: DefaultsKey.enabled) }
    }

    private var volume: Float {
        get { UserDefaults.standard.object(forKey: DefaultsKey.volume) as? Float ?? 1.0 }
        set { UserDefaults.standard.set(newValue, forKey: DefaultsKey.volume) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let icon = NSImage(named: "MenuBarIconTemplate") ?? NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyCream")
        icon?.isTemplate = true
        statusItem.button?.image = icon

        packs = SoundPack.bundled()
        do {
            let player = try SoundPlayer()
            player.volume = volume
            self.player = player
        } catch {
            print("Failed to start audio: \(error)")
        }
        let savedID = UserDefaults.standard.string(forKey: DefaultsKey.soundPack) ?? SoundPack.defaultID
        if !loadPack(id: savedID), savedID != SoundPack.defaultID {
            loadPack(id: SoundPack.defaultID)
        }

        monitor.onKeyDown = { [weak self] keyCode in
            guard let code = KeyCodeMap.mechvibesCode(for: keyCode) else { return }
            self?.player?.play(code: code)
        }

        enableLaunchAtLoginOnFirstRun()
        if !KeyboardMonitor.hasPermission {
            KeyboardMonitor.requestPermission()
        }
        updateMonitoring()
        rebuildMenu()
    }

    /** The tap can only be created after the user grants Input Monitoring, so poll until then. */
    private func updateMonitoring() {
        guard isEnabled else {
            monitor.stop()
            return
        }
        if monitor.start() {
            permissionTimer?.invalidate()
            permissionTimer = nil
            return
        }
        guard permissionTimer == nil else { return }
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.monitor.start() else { return }
                self.permissionTimer?.invalidate()
                self.permissionTimer = nil
                self.rebuildMenu()
            }
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let toggle = NSMenuItem(title: Localization.string("sounds_enabled"), action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.state = isEnabled ? .on : .off
        menu.addItem(toggle)

        let volumeItem = NSMenuItem(title: Localization.string("volume"), action: nil, keyEquivalent: "")
        let volumeMenu = NSMenu()
        for (index, level) in volumeLevels.enumerated() {
            let item = NSMenuItem(title: Localization.string(level.titleKey), action: #selector(selectVolume(_:)), keyEquivalent: "")
            item.tag = index
            item.state = abs(level.value - volume) < 0.01 ? .on : .off
            volumeMenu.addItem(item)
        }
        volumeItem.submenu = volumeMenu
        menu.addItem(volumeItem)

        let packItem = NSMenuItem(title: Localization.string("sound_pack"), action: nil, keyEquivalent: "")
        let packMenu = NSMenu()
        for pack in packs {
            let item = NSMenuItem(title: pack.name, action: #selector(selectSoundPack(_:)), keyEquivalent: "")
            item.representedObject = pack.id
            item.state = pack.id == loadedPackID ? .on : .off
            packMenu.addItem(item)
        }
        packItem.submenu = packMenu
        menu.addItem(packItem)

        let loginItem = NSMenuItem(title: Localization.string("launch_at_login"), action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        switch SMAppService.mainApp.status {
        case .enabled: loginItem.state = .on
        case .requiresApproval: loginItem.state = .mixed
        default: loginItem.state = .off
        }
        menu.addItem(loginItem)

        let languageItem = NSMenuItem(title: Localization.string("language"), action: nil, keyEquivalent: "")
        let languageMenu = NSMenu()
        let override = Localization.override
        let systemItem = NSMenuItem(title: Localization.string("language_system"), action: #selector(selectLanguage(_:)), keyEquivalent: "")
        systemItem.state = override == nil ? .on : .off
        languageMenu.addItem(systemItem)
        languageMenu.addItem(.separator())
        for language in Localization.languages {
            let item = NSMenuItem(title: language.name, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.representedObject = language.code
            item.state = override == language.code ? .on : .off
            languageMenu.addItem(item)
        }
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

        if loadedPackID == nil {
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: Localization.string("sound_pack_failed"), action: nil, keyEquivalent: ""))
        }
        if isEnabled && !monitor.isRunning {
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: Localization.string("grant_permission"), action: #selector(openPermissionSettings), keyEquivalent: ""))
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: Localization.string("quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        updateMonitoring()
        rebuildMenu()
    }

    @objc private func selectVolume(_ sender: NSMenuItem) {
        volume = volumeLevels[sender.tag].value
        player?.volume = volume
        rebuildMenu()
    }

    @discardableResult
    private func loadPack(id: String) -> Bool {
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

    @objc private func selectSoundPack(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String, loadPack(id: id) else { return }
        UserDefaults.standard.set(id, forKey: DefaultsKey.soundPack)
        rebuildMenu()
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        Localization.override = sender.representedObject as? String
        rebuildMenu()
    }

    /** On by default, but only once, so turning it off from the menu sticks. */
    private func enableLaunchAtLoginOnFirstRun() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: DefaultsKey.launchAtLoginConfigured) else { return }
        do {
            try SMAppService.mainApp.register()
            defaults.set(true, forKey: DefaultsKey.launchAtLoginConfigured)
        } catch {
            print("Launch at login registration failed: \(error)")
        }
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled || service.status == .requiresApproval {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            print("Launch at login change failed: \(error)")
        }
        // The user may have turned the item off in System Settings, which register() cannot override.
        if service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        rebuildMenu()
    }

    @objc private func openPermissionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
}
