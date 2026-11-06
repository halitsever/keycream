import AppKit

/** Tells when a call, music or video app is running, so key sounds can step back while it does. */
@MainActor
final class BackgroundAudioApps {
    static let bundleIDs: Set<String> = [
        "us.zoom.xos", "com.microsoft.teams", "com.microsoft.teams2", "com.skype.skype",
        "com.cisco.webexmeetingsapp", "com.tinyspeck.slackmacgap", "com.tencent.meeting",
        "com.tencent.VooVMeeting", "com.bytedance.lark", "com.ss.lark", "com.spotify.client",
        "com.apple.Music", "com.tidal.desktop", "com.soundcloud.SoundCloud", "com.tencent.QQMusic",
        "com.tencent.qqmusic", "com.netease.cloudmusic", "com.netease.music", "com.apple.podcasts",
        "com.pocketcasts.pocketcasts", "com.castrohq.Castro", "com.overcast.Overcast",
        "com.netflix.Netflix", "com.apple.QuickTimePlayerX", "org.videolan.vlc",
    ]

    var onChange: (() -> Void)?
    /** Names of the watched apps that are open, empty while turned off. */
    private(set) var activeAppNames: [String] = []
    var isActive: Bool { !activeAppNames.isEmpty }

    var isEnabled = false {
        didSet {
            guard isEnabled != oldValue else { return }
            isEnabled ? startObserving() : stopObserving()
            refresh()
        }
    }

    private var observers: [NSObjectProtocol] = []

    /** Launch and quit notifications keep this current without polling the process list. */
    private func startObserving() {
        let center = NSWorkspace.shared.notificationCenter
        observers = [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification].map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
    }

    private func stopObserving() {
        observers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
        observers = []
    }

    private func refresh() {
        // A quitting app can still be listed when its terminate notification arrives.
        let watched = NSWorkspace.shared.runningApplications.filter { app in
            !app.isTerminated && (app.bundleIdentifier.map(Self.bundleIDs.contains) ?? false)
        }
        let names = isEnabled ? watched.compactMap(\.localizedName) : []
        guard names != activeAppNames else { return }
        activeAppNames = names
        onChange?()
    }
}
