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
- It doesn't connect to the internet. The app contains no networking code, and you can check that in the [source code](https://github.com/halitsever/keycream/tree/main/Sources/KeyCream).
- It can't change, block or send keys. It only listens.

**What it stores.** Your settings, in `~/Library/Preferences/com.halit.keycream.plist`:

| Setting | Example |
|---|---|
| Sounds on or off | `enabled = 1` |
| Volume | `volume = 1` |
| Selected sound pack | `soundPack = NovelKeys-cream` |
| Language you chose in the menu | `AppleLanguages = (en)` |
| That KeyCream already added itself to login items | `launchAtLoginConfigured = 1` |

Nothing else is written to disk.

## This website

- No analytics, no tracking, no cookies.
- Fonts and sounds are served from this site. Nothing is loaded from font or ad services.
- The download button asks GitHub's API for the latest release, so your browser sends one request to `api.github.com`.
- Your browser remembers whether you muted the keyboard demo, in its local storage on your device.
- The site is hosted on GitHub Pages, which may keep server logs. See the [GitHub Privacy Statement](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement).
