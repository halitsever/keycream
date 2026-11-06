---
description: Fixes for the most common KeyCream problems.
---

# Troubleshooting

## There's no sound at all

Check these in order:

1. **Input Monitoring.** Open **System Settings → Privacy & Security → Input Monitoring** and make sure KeyCream is turned on. If the KeyCream menu shows **Grant Input Monitoring Access…**, it doesn't have permission yet.
2. **Sounds On.** Open the KeyCream menu and check that **Sounds On** is ticked.
3. **Your Mac's volume.** KeyCream plays through your current output, so a muted Mac or a quiet output device mutes it too.
4. **Output device.** Play a sound from another app. If that is silent too, the problem is the output device, not KeyCream. If you picked a device under **Output Device** in the KeyCream menu, check that it's the one you're listening to.
5. **Lower During Calls and Media.** With this on, key sounds play at 5% while Zoom, Teams, Slack, Spotify or a similar app is open, even in the background. Turn it off in **Settings → Sound** if that's too quiet.

## It went quiet after an update

macOS ties the Input Monitoring permission to the app's signature. Releases from 0.1.5 on share one, but when you update from 0.1.4 or earlier, or run a copy you built yourself, macOS treats KeyCream as a different app while the switch in System Settings still looks on.

Select KeyCream in the Input Monitoring list, remove it with the **−** button, and reopen KeyCream. Allow access when asked. If you prefer Terminal:

```bash
tccutil reset ListenEvent com.halit.keycream
```

## macOS says KeyCream can't be opened

That's the first-launch check for apps from outside the App Store. Go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**. [Installation](/guide/installation#open-it-for-the-first-time) has the details.

## It doesn't start when I log in

Open **Settings…** from the KeyCream menu and check **Open at Login** on the General tab. If it says macOS is waiting for your approval, KeyCream is turned off in your Mac's login items. Click **Open Login Items…** and turn it back on there.

If you moved KeyCream after it added itself to login items, open it once from its new place and toggle **Open at Login** off and on.

## The menu shows "Couldn't load sound pack"

The app's sound files are missing or damaged. Download the latest release again and replace KeyCream in Applications.

## The menu is in the wrong language

Open **Settings…** from the KeyCream menu, choose **Language** on the General tab and pick the one you want. **System Language** follows **System Settings → General → Language & Region**, using the first language there that KeyCream supports.

## Still stuck?

[Open an issue](https://github.com/halitsever/keycream/issues/new/choose) with your macOS version, your Mac's chip and the KeyCream version.
