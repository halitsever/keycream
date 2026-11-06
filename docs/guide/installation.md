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

KeyCream adds itself to your login items the first time it runs, so it's there every time you start your Mac. Turn this off with **Open at Login** in its settings, or under **System Settings → General → Login Items**.

## Update

Each time KeyCream opens it looks for a new release on GitHub. When there is one, it asks you first. Choose **Install and Restart** and it downloads the new version, checks that it came from this project, replaces itself and opens again. Your settings are kept. Choose **Later** and it asks again the next time it opens.

To look right away, choose **Check for Updates…** from the menu. To stop the check at launch, turn off **Check for Updates Automatically** on the About tab of its settings.

If KeyCream can't replace itself, for example because it sits in a folder you can't write to, it offers to open the release page. Download the new release there and replace the old KeyCream in Applications.

Every release from 0.1.5 on is signed with the same certificate, so macOS keeps the Input Monitoring permission across updates. Coming from 0.1.4 or earlier, it may ask one more time. If KeyCream stays silent after that update, select it in the Input Monitoring list, remove it with the **−** button, then add it back or reopen KeyCream.

## Uninstall

1. Choose **Quit** from the KeyCream menu.
2. Move KeyCream from Applications to the Trash.

To also remove its settings and permission entry, run:

```bash
defaults delete com.halit.keycream
tccutil reset ListenEvent com.halit.keycream
```
