---
description: Download KeyCream, open it for the first time and allow keyboard access.
---

# Installation

KeyCream runs on macOS 14 Sonoma or later, on both Apple Silicon and Intel Macs.

## Download

1. Download **KeyCream-x.y.z.zip** from the [latest release](https://github.com/halitsever/keycream/releases/latest).
2. Open the zip file. macOS unzips it next to the download.
3. Drag **KeyCream** into your **Applications** folder.

## Open it for the first time

Double-click KeyCream in Applications. If macOS says it can't check the app for malicious software, confirm it once:

1. Open **System Settings** and go to **Privacy & Security**.
2. Scroll down to the message about KeyCream and click **Open Anyway**.
3. Confirm with your password or Touch ID.

If you prefer Terminal, this does the same:

```bash
xattr -dr com.apple.quarantine /Applications/KeyCream.app
```

After the first launch, KeyCream opens normally.

## Allow keyboard access

KeyCream needs to know when a key is pressed, and macOS only allows that with the **Input Monitoring** permission.

1. When KeyCream asks, click **Open System Settings**. You can also go there yourself: **System Settings → Privacy & Security → Input Monitoring**.
2. Turn on **KeyCream**.

Sounds start within a few seconds, without restarting the app. Until then the menu shows **Grant Input Monitoring Access…**, which takes you to the same place.

::: info
Input Monitoring lets KeyCream know which key was pressed. It can't change, block or send keys. [Privacy](/guide/privacy) explains exactly what it does with key presses.
:::

## Open at login

KeyCream adds itself to your login items the first time it runs, so it's there every time you start your Mac. Turn this off with **Open at Login** in its menu, or under **System Settings → General → Login Items**.

## Update

Download the new release and replace the old KeyCream in Applications. Your settings are kept.

If KeyCream stays silent after an update, macOS wants to confirm Input Monitoring again. Select KeyCream in the Input Monitoring list, remove it with the **−** button, then add it back or reopen KeyCream.

## Uninstall

1. Choose **Quit** from the KeyCream menu.
2. Move KeyCream from Applications to the Trash.

To also remove its settings and permission entry, run:

```bash
defaults delete com.halit.keycream
tccutil reset ListenEvent com.halit.keycream
```
