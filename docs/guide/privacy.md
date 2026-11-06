---
description: What KeyCream does with your key presses, what it stores, and what this website loads.
---

# Privacy

KeyCream turns key presses into sounds. To do that it needs to know when a key goes down. Here is exactly what happens with that information.

## The app

**What it receives.** With the Input Monitoring permission, macOS tells KeyCream which physical key went down, as a number. KeyCream uses that number to pick a sound and play it.

**What it doesn't do.**

- It doesn't store key presses, anywhere.
- It doesn't put key presses together into text.
- It doesn't send key presses or settings anywhere.
- It can't change, block or send keys. It only listens.

**Other apps.** With **Lower During Calls and Media** on, KeyCream asks macOS for the bundle IDs of running apps, such as `us.zoom.xos`, each time an app opens or quits. It compares them with a fixed list and keeps only the answer: whether one of them is open. It doesn't store the list or look at what the apps do.

**What it stores.** Your settings, in `~/Library/Preferences/com.halit.keycream.plist`:

| Setting | Example |
|---|---|
| Sounds on or off | `enabled = 1` |
| Volume | `volume = 0.6` |
| Selected sound pack | `soundPack = NovelKeys-cream` |
| Output device you chose, by its ID and name | `outputDeviceUID = BuiltInSpeakerDevice` |
| Lower during calls and media | `backgroundMode = 1` |
| On/off shortcut, as a key code and modifiers | `toggleShortcut = <data>` |
| Name in the menu bar, dimmed icon | `showsNameInMenuBar = 1`, `dimsMenuBarIcon = 1` |
| Appearance | `appearance = dark` |
| Language you chose in settings | `AppleLanguages = (en)` |
| That KeyCream already added itself to login items | `launchAtLoginConfigured = 1` |
| Check for updates when it opens | `checksForUpdates = 1` |

Nothing else is written to disk.

**What it sends.** Only update checks. When KeyCream opens, and when you choose **Check for Updates…**, it asks GitHub's API for the latest release. If you install it, the new version is downloaded from GitHub. Those requests carry nothing about you or your keys, but GitHub sees your IP address like any server would. Turn off **Check for Updates Automatically** and KeyCream only connects when you ask it to. All of this is in [Updater.swift](https://github.com/halitsever/keycream/blob/main/Sources/KeyCream/Updater.swift).

## This website

- No analytics, no tracking, no cookies.
- Fonts and sounds are served from this site. Nothing is loaded from font or ad services.
- The download button asks GitHub's API for the latest release, so your browser sends one request to `api.github.com`.
- Your browser remembers whether you muted the keyboard demo, in its local storage on your device.
- The site is hosted on GitHub Pages, which may keep server logs. See the [GitHub Privacy Statement](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement).
