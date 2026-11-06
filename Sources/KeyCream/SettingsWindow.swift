import AppKit
import ServiceManagement
import SwiftUI

/** The settings window, with toolbar tabs like the settings of Apple's own apps. */
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private static let tabs = [
        (titleKey: "settings_general", symbol: "gearshape"),
        (titleKey: "settings_sound", symbol: "speaker.wave.2"),
        (titleKey: "settings_about", symbol: "info.circle"),
    ]

    private var window: NSWindow?
    private var tabController: NSTabViewController?
    private weak var app: AppController?

    func show(_ app: AppController) {
        self.app = app
        let window = self.window ?? makeWindow(app)
        self.window = window
        app.refreshLaunchAtLoginStatus()
        // A menu bar app is never frontmost by itself, so the window would open behind other windows.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    /** Tab labels live in AppKit, so they miss the rebuild the SwiftUI pages get on a language change. */
    func updateTitle() {
        guard let tabController else { return }
        for (item, tab) in zip(tabController.tabViewItems, Self.tabs) {
            item.label = Localization.string(tab.titleKey)
            item.viewController?.title = item.label
        }
    }

    func windowWillClose(_ notification: Notification) {
        app?.stopRecordingShortcut()
    }

    private func makeWindow(_ app: AppController) -> NSWindow {
        let tabController = NSTabViewController()
        tabController.tabStyle = .toolbar
        let pages: [AnyView] = [
            AnyView(SettingsPage(app: app) { GeneralSettings(app: app, preferences: app.preferences) }),
            AnyView(SettingsPage(app: app) { SoundSettings(app: app, preferences: app.preferences) }),
            AnyView(SettingsPage(app: app) { AboutSettings(app: app, preferences: app.preferences) }),
        ]
        for (tab, page) in zip(Self.tabs, pages) {
            let hosting = NSHostingController(rootView: page)
            // Lets the tab controller resize the window to each page.
            hosting.sizingOptions = .preferredContentSize
            let item = NSTabViewItem(viewController: hosting)
            item.image = NSImage(systemSymbolName: tab.symbol, accessibilityDescription: nil)
            tabController.addTabViewItem(item)
        }
        self.tabController = tabController
        updateTitle()

        let window = NSWindow(contentViewController: tabController)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }
}

private func L(_ key: String) -> String {
    Localization.string(key)
}

private let pageWidth: CGFloat = 520

/** Localization.string isn't observable, so a language change rebuilds the page. */
private struct SettingsPage<Content: View>: View {
    let app: AppController
    @ViewBuilder let content: () -> Content

    var body: some View {
        content().id(app.preferences.language ?? "")
    }
}

// MARK: - General

private struct GeneralSettings: View {
    let app: AppController
    @Bindable var preferences: Preferences

    var body: some View {
        Form {
            Section {
                StatusHeader(app: app, preferences: preferences)
            }

            Section {
                LabeledContent {
                    ShortcutField(app: app)
                } label: {
                    RowLabel(L("toggle_shortcut"), detail: L("shortcut_hint"))
                }
                Toggle(L("launch_at_login"), isOn: Binding(get: { app.isLaunchAtLoginOn }, set: { app.setLaunchAtLogin($0) }))
                if app.launchAtLoginStatus == .requiresApproval {
                    HStack {
                        Text(L("launch_at_login_needs_approval")).foregroundStyle(.secondary)
                        Spacer()
                        Button(L("open_login_items")) { SMAppService.openSystemSettingsLoginItems() }
                    }
                }
            }

            Section(L("menu_bar")) {
                Toggle(L("menu_bar_show_name"), isOn: $preferences.showsNameInMenuBar)
                Toggle(L("menu_bar_dim_icon"), isOn: $preferences.dimsMenuBarIcon)
            }

            Section {
                Picker(L("appearance"), selection: $preferences.appearance) {
                    ForEach(Preferences.Appearance.allCases, id: \.self) { appearance in
                        Text(L(appearance.titleKey)).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
                Picker(L("language"), selection: $preferences.language) {
                    Text(L("language_system")).tag(String?.none)
                    Divider()
                    ForEach(Localization.languages, id: \.code) { language in
                        Text(language.name).tag(Optional(language.code))
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: pageWidth, height: 500)
    }
}

/** The one switch most people need, with what KeyCream is doing right now. */
private struct StatusHeader: View {
    let app: AppController
    @Bindable var preferences: Preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "KeyCream").font(.headline)
                    Text(L(statusKey))
                        .font(.subheadline)
                        .foregroundStyle(needsPermission ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
                }
                Spacer()
                Toggle(L("sounds_enabled"), isOn: $preferences.isEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            if needsPermission {
                HStack {
                    Spacer()
                    Button(L("grant_permission")) { app.openPermissionSettings() }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var needsPermission: Bool { preferences.isEnabled && !app.isMonitoring }

    private var statusKey: String {
        if needsPermission { return "status_needs_permission" }
        return preferences.isEnabled ? "status_on" : "status_off"
    }
}

private struct ShortcutField: View {
    let app: AppController

    var body: some View {
        HStack(spacing: 6) {
            Button {
                if app.isRecordingShortcut {
                    app.stopRecordingShortcut()
                } else {
                    app.startRecordingShortcut()
                }
            } label: {
                Text(title)
                    .foregroundStyle(app.isRecordingShortcut ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                    .frame(minWidth: 130)
            }
            if app.preferences.toggleShortcut != nil, !app.isRecordingShortcut {
                Button {
                    app.preferences.toggleShortcut = nil
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help(L("shortcut_clear"))
                .accessibilityLabel(L("shortcut_clear"))
            }
        }
    }

    private var title: String {
        if app.isRecordingShortcut { return L("shortcut_recording") }
        return app.preferences.toggleShortcut?.displayString ?? L("shortcut_record")
    }
}

// MARK: - Sound

private struct SoundSettings: View {
    let app: AppController
    @Bindable var preferences: Preferences

    var body: some View {
        Form {
            Section {
                PackPicker(app: app, preferences: preferences)
            } header: {
                Text(L("sound_pack"))
            } footer: {
                Footnote(L("sound_pack_hint"))
            }

            Section {
                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                    Slider(value: volume, in: 0...1) { editing in
                        if !editing { app.playPreview() }
                    }
                    .labelsHidden()
                    .accessibilityLabel(L("volume"))
                    Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                    Text(preferences.volume.formatted(.percent.precision(.fractionLength(0)).locale(Localization.locale)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                }
                Picker(L("volume"), selection: volumePreset) {
                    ForEach(Preferences.volumeLevels.indices, id: \.self) { index in
                        Text(L(Preferences.volumeLevels[index].titleKey)).tag(Optional(index))
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Picker(L("output_device"), selection: outputDeviceUID) {
                    Text(L("output_device_system")).tag(String?.none)
                    Divider()
                    ForEach(app.outputDevices) { device in
                        Text(device.name).tag(Optional(device.uid))
                    }
                    if let name = preferences.outputDeviceName, app.chosenOutputDevice == nil {
                        Text(String(format: L("output_device_disconnected"), name)).tag(preferences.outputDeviceUID)
                    }
                }
                Toggle(isOn: $preferences.backgroundMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        RowLabel(L("background_mode"), detail: L("background_mode_hint"))
                        if !app.backgroundAppNames.isEmpty {
                            let names = app.backgroundAppNames.formatted(.list(type: .and).locale(Localization.locale))
                            Label(String(format: L("background_mode_active"), names), systemImage: "speaker.wave.1.fill")
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    }
                }
            } header: {
                Text(L("volume"))
            }
        }
        .formStyle(.grouped)
        .frame(width: pageWidth, height: 590)
    }

    private var volume: Binding<Double> {
        Binding(get: { Double(preferences.volume) }, set: { preferences.volume = Float($0) })
    }

    /** nil while the slider sits between presets, so no segment looks chosen. */
    private var volumePreset: Binding<Int?> {
        Binding(get: {
            Preferences.volumeLevels.firstIndex { abs($0.value - preferences.volume) < 0.01 }
        }, set: { index in
            guard let index else { return }
            preferences.volume = Preferences.volumeLevels[index].value
            app.playPreview()
        })
    }

    /** Choosing the unplugged device's own entry keeps it chosen. */
    private var outputDeviceUID: Binding<String?> {
        Binding(get: { preferences.outputDeviceUID }, set: { uid in
            guard uid != preferences.outputDeviceUID else { return }
            preferences.selectOutputDevice(app.outputDevices.first { $0.uid == uid })
        })
    }
}

/** Packs as switch cards, one row per feel, so similar sounds sit together. */
private struct PackPicker: View {
    let app: AppController
    @Bindable var preferences: Preferences

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(groups, id: \.title) { group in
                VStack(alignment: .leading, spacing: 6) {
                    if !group.title.isEmpty {
                        Text(group.title).font(.caption).foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                        ForEach(group.packs, id: \.id) { pack in
                            PackCard(pack: pack, isSelected: pack.id == app.loadedPackID) {
                                preferences.soundPackID = pack.id
                                app.playPreview()
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    /** A pack KeyCream doesn't ship has no feel, so it goes last without a heading. */
    private var groups: [(title: String, packs: [SoundPack])] {
        var groups = SoundPack.Feel.allCases.compactMap { feel -> (title: String, packs: [SoundPack])? in
            let packs = app.packs.filter { $0.look?.feel == feel }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return packs.isEmpty ? nil : (L(feel.titleKey), packs)
        }
        let others = app.packs.filter { $0.look == nil }
        if !others.isEmpty { groups.append(("", others)) }
        return groups
    }
}

private struct PackCard: View {
    let pack: SoundPack
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                SwitchDrawing(look: pack.look)
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(pack.switchName).font(.callout.weight(.medium)).lineLimit(1)
                    if let brand = pack.brand {
                        Text(brand).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pack.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/** A switch seen from above, drawn like the ones on the KeyCream website. Coordinates follow its 120 by 120 SVG. */
private struct SwitchDrawing: View {
    let look: SoundPack.Look?

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 120
            func box(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
                CGRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
            }
            func rounded(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ radius: CGFloat) -> Path {
                Path(roundedRect: box(x, y, width, height), cornerRadius: radius * scale)
            }
            let housing = Color(rgb: look?.housing ?? 0x2B2A2C)
            let stem = Color(rgb: look?.stem ?? 0x8E8E93)

            context.fill(rounded(15, 19, 90, 90, 14), with: .color(.black.opacity(0.45)))
            context.fill(rounded(11, 42, 8, 20, 2.5), with: .color(housing))
            context.fill(rounded(101, 42, 8, 20, 2.5), with: .color(housing))
            context.fill(rounded(15, 14, 90, 90, 14), with: .color(housing.opacity(look?.isClear == true ? 0.7 : 1)))
            // Keeps dark housings visible on a dark card.
            context.stroke(rounded(15, 14, 90, 90, 14), with: .color(.primary.opacity(0.18)), lineWidth: 2 * scale)
            let shine = UnevenRoundedRectangle(topLeadingRadius: 14 * scale, topTrailingRadius: 14 * scale).path(in: box(15, 14, 90, 22))
            context.fill(shine, with: .color(.white.opacity(0.08)))
            context.fill(rounded(48, 21, 24, 9, 2.5), with: .color(.black.opacity(0.35)))
            context.fill(Path(ellipseIn: box(33, 34, 54, 54)), with: .color(.black.opacity(0.3)))
            context.fill(rounded(43, 47, 34, 30, 6), with: .color(stem))
            context.fill(rounded(43, 47, 34, 30, 6), with: .color(.black.opacity(0.16)))
            context.fill(rounded(48, 57.5, 24, 7, 1.5), with: .color(stem))
            context.fill(rounded(56.5, 49, 7, 24, 1.5), with: .color(stem))
            context.fill(rounded(48, 57.5, 24, 2, 1), with: .color(.white.opacity(0.25)))
        }
        .accessibilityHidden(true)
    }
}

// MARK: - About

private struct AboutSettings: View {
    let app: AppController
    @Bindable var preferences: Preferences

    var body: some View {
        VStack(spacing: 0) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text(verbatim: "KeyCream")
                .font(.title.weight(.semibold))
                .padding(.top, 8)
            Text(String(format: L("version_format"), version))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            Text(L("about_tagline"))
                .padding(.top, 12)

            VStack(spacing: 10) {
                Button(L(app.updateState == .downloading ? "update_downloading" : "check_for_updates")) {
                    app.checkForUpdates()
                }
                .controlSize(.large)
                .disabled(app.updateState != .idle)
                Toggle(L("check_updates_automatically"), isOn: $preferences.checksForUpdates)
                    .toggleStyle(.checkbox)
            }
            .padding(.top, 20)

            HStack(spacing: 20) {
                Link(L("website"), destination: URL(string: "https://halitsever.github.io/keycream/")!)
                Link(L("source_code"), destination: URL(string: "https://github.com/halitsever/keycream")!)
                Link(L("privacy"), destination: URL(string: "https://halitsever.github.io/keycream/guide/privacy")!)
            }
            .padding(.top, 24)

            Text(L("license_note"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 32)
        .frame(width: pageWidth)
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}

// MARK: - Shared

/** A row title with an explanation under it, like the rows in System Settings. */
private struct RowLabel: View {
    let title: String
    let detail: String

    init(_ title: String, detail: String) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct Footnote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .multilineTextAlignment(.leading)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension Color {
    init(rgb: UInt32) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
