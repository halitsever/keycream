---
title: "Is Mechvibes Safe? Keyboard Sound Apps and Privacy"
titleTemplate: false
description: "Is Mechvibes safe? What a keyboard sound app needs to hear your keys, what Mechvibes 3 sends and stores per its README, and how KeyCream compares."
date: 2026-11-28
faq:
  - q: "Is Mechvibes a keylogger?"
    a: "A keyboard sound app has to know when keys are pressed, which needs the same system access a keylogger would use. Mechvibes is open source under the MIT License, and its README says keystrokes are never sent and never written to its logs. Because the code is public, anyone can check those claims."
  - q: "Does Mechvibes collect data?"
    a: "Its README says it sends one anonymous ping per launch with the OS name and version, the app version and the system language, and checks GitHub for updates once a day. The ping can be turned off in Settings, Privacy."
  - q: "Why does macOS warn me when I open Mechvibes?"
    a: "The Mechvibes 3 macOS build is ad-hoc signed and not notarized by Apple, so Gatekeeper asks you to confirm the first launch. The README explains the steps and calls the macOS build experimental."
  - q: "What permissions does a keyboard sound app need on a Mac?"
    a: "Input Monitoring, so it can hear keys while another app is in front. Mechvibes also asks for Accessibility. KeyCream asks only for Input Monitoring."
---

# Mechvibes and privacy: what a keyboard sound app can see

<p class="post-meta">Halit Sever · 28 November 2026</p>

Any app that plays a sound when you press a key has to know when you press a key. That is the same access a keylogger needs, so the question is fair. This post looks at what a keyboard sound app has to read, what Mechvibes says it does with that access, and how to check it yourself. Facts about Mechvibes come from its [README and source](https://github.com/hainguyents13/mechvibes) for version 3.5.11, checked on 28 November 2026. I build [KeyCream](/), a Mac app in the same category, so its behavior is covered too, with links to its code.

## What any keyboard sound app needs

To play a sound for keys pressed in other apps, the program has to receive keyboard events system-wide:

- **macOS** gates this behind the **Input Monitoring** permission in System Settings > Privacy & Security.
- **Linux on Wayland** has no general way for one app to see another's keys, so apps read the input devices directly, which needs your user in the `input` group.
- **Windows** lets apps install a global keyboard hook.

Receiving key events is unavoidable. What matters is what the app does with them: whether it turns them into text, stores them or sends them anywhere.

## What Mechvibes says it does

From the README's privacy section:

- It sends one anonymous ping per launch to mechvibes.com with the OS name and version, the app version and the system language. The server adds it to a daily count and does not keep the IP address.
- It never sends keystrokes, mouse clicks, sound pack names, file paths or persistent identifiers.
- It checks GitHub for a new version once a day, which "sends nothing about you."
- Logs stay on your device until you export them, and pressed keys show as `***` in them.
- The ping can be turned off under **Settings > Privacy > Share anonymous usage stats**.

Mechvibes is open source under the MIT License, so these statements can be checked against the code rather than taken on trust.

## Platform details worth knowing

**macOS.** The README calls the Mac build experimental. It is ad-hoc signed and not notarized, so macOS asks you to confirm the first launch, and the maintainer has not tested it on real Mac hardware. It asks for both Accessibility and Input Monitoring. After an update, permissions may need to be removed and added again because macOS ties them to the exact binary.

**Windows.** The installer is not signed, so SmartScreen may warn on first run. In-app updates are checked with SHA-256 before they install.

**Linux.** On Wayland the app needs your user in the `input` group. Membership in that group lets any program you run read keyboard and mouse devices directly, not only Mechvibes, so it is a broader permission than it looks.

None of these are signs of anything malicious. They are the normal costs of a free cross-platform app without paid code signing, and the README states them openly.

## How to check any keyboard sound app

1. **Is the source public?** Closed source means trusting the vendor's word.
2. **What does it send?** Look for a privacy section, then check network activity with a tool like Little Snitch on macOS or your firewall's log.
3. **Does it store keys?** Logs and analytics are where keystrokes tend to leak.
4. **Which permissions does it ask for?** On macOS, Input Monitoring is required; anything beyond that should have a reason.
5. **Where do you download it?** Get it from the project's own releases page, not a mirror.

## How KeyCream handles the same

KeyCream is a Mac-only menu bar app, so it only deals with the macOS side:

- It asks only for **Input Monitoring**. macOS tells it which physical key went down, as a number, and it plays the matching sound.
- It does not store key presses, does not assemble them into text, and does not send them anywhere. It cannot change, block or send keys.
- Its only network traffic is the update check against GitHub's API, when it opens and when you choose **Check for Updates…**. That can be turned off.
- Releases are signed with the same certificate from 0.1.5 on, so macOS keeps the permission across updates.

The details, including every setting it saves, are on the [Privacy](/guide/privacy) page, and the update code is in [Updater.swift](https://github.com/halitsever/keycream/blob/main/Sources/KeyCream/Updater.swift).

## FAQ

<Faq />

## Related

- [Mechvibes DX](/blog/mechvibes-dx): the Rust rewrite that became Mechvibes 3
- [Mechvibes custom sounds](/blog/mechvibes-custom-sound-packs): what is inside a sound pack
- [KeyCream vs Klack vs Mechvibes](/guide/keycream-vs-klack-vs-mechvibes): the three apps compared
- [Installation](/guide/installation): granting Input Monitoring to KeyCream
