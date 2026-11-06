import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let app = AppController()
    private let settingsWindow = SettingsWindowController()
    private var statusItem: NSStatusItem!
    /** Kept so dragging the volume slider moves the checkmark while the menu is open. */
    private var volumePresetItems: [NSMenuItem] = []

    private var preferences: Preferences { app.preferences }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let icon = NSImage(named: "MenuBarIconTemplate") ?? NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyCream")
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.button?.imagePosition = .imageLeading
        // Filled in each time it opens, so it never shows a stale state.
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        app.onMenuBarIconChange = { [weak self] in self?.updateStatusButton() }
        app.onLanguageChange = { [weak self] in self?.settingsWindow.updateTitle() }
        app.start()
        updateStatusButton()
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }
        statusItem.length = preferences.showsNameInMenuBar ? NSStatusItem.variableLength : NSStatusItem.squareLength
        button.title = preferences.showsNameInMenuBar ? " KeyCream" : ""
        button.alphaValue = preferences.dimsMenuBarIcon ? 0.5 : 1
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === statusItem.menu else { return }
        menu.removeAllItems()

        let shortcut = preferences.toggleShortcut
        let toggle = item("sounds_enabled", #selector(toggleEnabled), key: shortcut?.characters ?? "")
        toggle.keyEquivalentModifierMask = shortcut?.modifierFlags ?? []
        toggle.state = preferences.isEnabled ? .on : .off
        menu.addItem(toggle)
        menu.addItem(.separator())

        menu.addItem(submenu("volume", volumeMenu()))
        menu.addItem(submenu("sound_pack", soundPackMenu()))
        menu.addItem(submenu("output_device", outputDeviceMenu()))

        if app.loadedPackID == nil {
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: Localization.string("sound_pack_failed"), action: nil, keyEquivalent: ""))
        }
        if preferences.isEnabled && !app.isMonitoring {
            menu.addItem(.separator())
            menu.addItem(item("grant_permission", #selector(openPermissionSettings)))
        }

        menu.addItem(.separator())
        menu.addItem(item("settings_open", #selector(openSettings), key: ","))
        // An item without an action is shown disabled while a check or download runs.
        switch app.updateState {
        case .idle: menu.addItem(item("check_for_updates", #selector(checkForUpdates)))
        case .checking: menu.addItem(item("check_for_updates", nil))
        case .downloading: menu.addItem(item("update_downloading", nil))
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: Localization.string("quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func volumeMenu() -> NSMenu {
        let menu = NSMenu()
        let sliderItem = NSMenuItem()
        sliderItem.view = MenuVolumeSlider(value: preferences.volume) { [weak self] value in
            self?.preferences.volume = value
            self?.updateVolumePresetStates()
        }
        menu.addItem(sliderItem)
        menu.addItem(.separator())

        volumePresetItems = Preferences.volumeLevels.enumerated().map { index, level in
            let presetItem = item(level.titleKey, #selector(selectVolume(_:)))
            presetItem.tag = index
            return presetItem
        }
        volumePresetItems.forEach(menu.addItem)
        updateVolumePresetStates()
        return menu
    }

    private func updateVolumePresetStates() {
        for (index, presetItem) in volumePresetItems.enumerated() {
            presetItem.state = abs(Preferences.volumeLevels[index].value - preferences.volume) < 0.01 ? .on : .off
        }
    }

    private func soundPackMenu() -> NSMenu {
        let menu = NSMenu()
        for group in SoundPack.groupedByBrand(app.packs) {
            if menu.numberOfItems > 0 { menu.addItem(.separator()) }
            menu.addItem(.sectionHeader(title: group.title))
            for pack in group.packs {
                let packItem = NSMenuItem(title: pack.switchName, action: #selector(selectSoundPack(_:)), keyEquivalent: "")
                packItem.target = self
                packItem.representedObject = pack.id
                packItem.state = pack.id == app.loadedPackID ? .on : .off
                menu.addItem(packItem)
            }
        }
        return menu
    }

    private func outputDeviceMenu() -> NSMenu {
        let menu = NSMenu()
        let systemItem = item("output_device_system", #selector(selectOutputDevice(_:)))
        systemItem.state = preferences.outputDeviceUID == nil ? .on : .off
        menu.addItem(systemItem)
        menu.addItem(.separator())
        for device in app.outputDevices {
            let deviceItem = NSMenuItem(title: device.name, action: #selector(selectOutputDevice(_:)), keyEquivalent: "")
            deviceItem.target = self
            deviceItem.representedObject = device.uid
            deviceItem.state = device.uid == preferences.outputDeviceUID ? .on : .off
            menu.addItem(deviceItem)
        }
        if let name = preferences.outputDeviceName, app.chosenOutputDevice == nil {
            let missing = NSMenuItem(title: String(format: Localization.string("output_device_disconnected"), name), action: nil, keyEquivalent: "")
            missing.state = .on
            menu.addItem(missing)
        }
        return menu
    }

    private func item(_ titleKey: String, _ action: Selector?, key: String = "") -> NSMenuItem {
        let menuItem = NSMenuItem(title: Localization.string(titleKey), action: action, keyEquivalent: key)
        menuItem.target = action == nil ? nil : self
        return menuItem
    }

    private func submenu(_ titleKey: String, _ submenu: NSMenu) -> NSMenuItem {
        let menuItem = NSMenuItem(title: Localization.string(titleKey), action: nil, keyEquivalent: "")
        menuItem.submenu = submenu
        return menuItem
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        app.toggleEnabled()
    }

    @objc private func selectVolume(_ sender: NSMenuItem) {
        preferences.volume = Preferences.volumeLevels[sender.tag].value
    }

    @objc private func selectSoundPack(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        preferences.soundPackID = id
    }

    @objc private func selectOutputDevice(_ sender: NSMenuItem) {
        let uid = sender.representedObject as? String
        preferences.selectOutputDevice(app.outputDevices.first { $0.uid == uid })
    }

    @objc private func openSettings() {
        settingsWindow.show(app)
    }

    @objc private func checkForUpdates() {
        app.checkForUpdates()
    }

    @objc private func openPermissionSettings() {
        app.openPermissionSettings()
    }
}

/** Menus can only host a slider through a custom view. */
private final class MenuVolumeSlider: NSView {
    private let slider: NSSlider
    private let onChange: (Float) -> Void

    init(value: Float, onChange: @escaping (Float) -> Void) {
        self.onChange = onChange
        slider = NSSlider(value: Double(value), minValue: 0, maxValue: 1, target: nil, action: nil)
        super.init(frame: NSRect(x: 0, y: 0, width: 240, height: 28))

        let quiet = NSImageView(image: NSImage(systemSymbolName: "speaker.fill", accessibilityDescription: nil) ?? NSImage())
        let loud = NSImageView(image: NSImage(systemSymbolName: "speaker.wave.3.fill", accessibilityDescription: nil) ?? NSImage())
        for icon in [quiet, loud] {
            icon.contentTintColor = .secondaryLabelColor
            icon.translatesAutoresizingMaskIntoConstraints = false
            addSubview(icon)
        }
        slider.target = self
        slider.action = #selector(sliderMoved)
        slider.isContinuous = true
        slider.setAccessibilityLabel(Localization.string("volume"))
        slider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(slider)

        NSLayoutConstraint.activate([
            quiet.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            quiet.centerYAnchor.constraint(equalTo: centerYAnchor),
            slider.leadingAnchor.constraint(equalTo: quiet.trailingAnchor, constant: 8),
            slider.centerYAnchor.constraint(equalTo: centerYAnchor),
            loud.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 8),
            loud.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            loud.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    @objc private func sliderMoved() {
        onChange(slider.floatValue)
    }
}
