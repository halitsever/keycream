---
description: Everything in the KeyCream menu and settings window, and the settings it starts with.
---

# Using KeyCream

KeyCream lives in the menu bar, as a small keycap with cream dripping from it. The menu has what you change often. Everything else is in **Settings…**.

## The menu

| Item | What it does | Starts as |
|---|---|---|
| **Sounds On** | Turns key sounds on or off without quitting the app. If you set an [on/off shortcut](#on-off-shortcut), it's shown next to this item. | On |
| **Volume** | A slider and the Low, Medium and High presets. | Medium |
| **Sound Pack** | Chooses which keyboard you hear, grouped by brand. The new pack plays right away. | NovelKeys Cream |
| **Output Device** | Where key sounds play. **System Default** follows your Mac's output. | System Default |
| **Settings…** | Opens the settings window. Shortcut: <kbd>⌘</kbd> <kbd>,</kbd> while the menu is open. | |
| **Check for Updates…** | Looks for a new release right away. | |
| **Quit** | Closes KeyCream until you open it again. Shortcut: <kbd>⌘</kbd> <kbd>Q</kbd> while the menu is open. | |

## Settings

| Tab | Setting | What it does | Starts as |
|---|---|---|---|
| General | **Sounds On** | Same as in the menu. | On |
| General | **On/Off Shortcut** | A key combination that turns sounds on or off from any app. | None |
| General | **Open at Login** | Starts KeyCream when you log in to your Mac. | On |
| General | **Show Name in Menu Bar** | Shows "KeyCream" next to the icon. | Off |
| General | **Dim Menu Bar Icon** | Shows the icon at half strength. | Off |
| General | **Appearance** | Light or dark windows and menus. **System** follows your Mac. | System |
| General | **Language** | **System Language** follows your Mac. Choose a language to use that one instead. | System Language |
| Sound | **Sound Pack** | Every switch as a card, grouped into linear, tactile and clicky. Click one to switch to it and hear a few keys. | NovelKeys Cream |
| Sound | **Volume**, **Output Device** | Same as in the menu. The slider shows the exact level and plays a few keys when you let go. | |
| Sound | **Lower During Calls and Media** | Plays key sounds at 5% volume while a call or media app is open. | Off |
| About | **Check for Updates Automatically** | Looks for a new release on GitHub each time KeyCream opens, and asks before installing it. | On |

Every choice is saved as soon as you make it and is still there after you restart your Mac.

## What makes a sound

- **A key going down.** Releasing a key is silent.
- **Modifier keys** such as <kbd>shift</kbd>, <kbd>command</kbd>, <kbd>option</kbd> and <kbd>control</kbd> when you press them. Left and right keys are told apart.
- **Caps Lock**, each time you press it.

Holding a key down plays one sound. The repeated characters macOS types while you hold it stay silent.

## Volume

The KeyCream volume works on top of your Mac's volume. At 100%, or **High**, KeyCream plays each sound at the level the pack was leveled to. **Medium** and **Low** play it at 60% and 30% of that, and the slider picks any level in between.

Every pack is leveled when it loads, so switching packs doesn't make your keyboard suddenly louder or quieter.

## Output device

With **System Default**, key sounds go wherever the rest of your Mac's audio goes. Pick a device to keep them there, for example on your speakers while music plays in your headphones. If that device is unplugged, KeyCream plays through the system default and goes back to your device when it returns. The menu then lists it as "Not Connected".

## Lower during calls and media

With **Lower During Calls and Media** on, key sounds drop to 5% of their volume while any of these apps is open: Zoom, Microsoft Teams, Skype, Webex, Slack, Tencent Meeting, VooV Meeting, Lark, Spotify, Music, TIDAL, SoundCloud, QQ Music, NetEase Cloud Music, Podcasts, Pocket Casts, Castro, Overcast, Netflix, QuickTime Player and VLC. They come back to full volume when you quit the last one.

KeyCream checks which apps are running when one opens or quits. It doesn't look at what they play.

## On/off shortcut

In **Settings → General**, click the shortcut button and press the keys you want. Use <kbd>⌘</kbd>, <kbd>⌥</kbd> or <kbd>⌃</kbd> together with a key, or a function key such as <kbd>F13</kbd> on its own. <kbd>esc</kbd> cancels, and <kbd>delete</kbd> or the clear button removes the shortcut.

The shortcut works in every app, even while sounds are off, because KeyCream keeps listening for it. It needs the same Input Monitoring permission as the sounds.

## Languages

KeyCream is available in English, Türkçe, Deutsch, Français, Español, Português, Русский, 日本語, 한국어, 简体中文, العربية and हिन्दी.

With **System Language** it uses the first language in **System Settings → General → Language & Region** that it supports, and Turkish if none of them is. You can also set KeyCream's language there, under **Applications**, and the settings window shows the same choice.
