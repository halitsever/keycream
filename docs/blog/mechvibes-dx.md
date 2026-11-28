---
title: "Mechvibes DX: What It Is and a Native Mac Option"
titleTemplate: false
description: "MechvibesDX was the Rust rewrite of Mechvibes, now released as Mechvibes 3. What changed, how to move from DX, what it means on a Mac, and where KeyCream fits."
date: 2026-11-28
faq:
  - q: "What is Mechvibes DX?"
    a: "MechvibesDX was the Rust rewrite of Mechvibes, built with the Dioxus UI framework. Its first beta came out in June 2025. In October 2026 it became Mechvibes 3, the official Mechvibes app, which replaces both MechvibesDX and the Electron-based Mechvibes 2."
  - q: "Is MechvibesDX still being updated?"
    a: "Under a new name. The same repository now publishes Mechvibes 3, and its README tells MechvibesDX users how to update. The last MechvibesDX release, 0.8.4, came out on 15 October 2026."
  - q: "Does Mechvibes DX work on Mac?"
    a: "Mechvibes 3 has macOS builds for Apple Silicon and Intel. Its README calls them experimental: ad-hoc signed, not notarized, and not tested on real hardware by the maintainer. It needs Accessibility and Input Monitoring permissions."
  - q: "Can KeyCream use Mechvibes sound packs?"
    a: "KeyCream reads classic Mechvibes packs (the V1 config.json format) and its seven bundled packs come from the Mechvibes project. It does not read the V2 format that Mechvibes 3 uses, and a new pack goes in when you build KeyCream from source."
---

# Mechvibes DX: what it is and a native Mac option

<p class="post-meta">Halit Sever · 28 November 2026</p>

If you searched for Mechvibes DX, you probably saw the name on a download page or in an old app on your machine and want to know whether it is still the one to use. The short answer: MechvibesDX was the Rust rewrite of the Mechvibes keyboard sound app, and it now ships as Mechvibes 3, the official Mechvibes. Everything below comes from the [Mechvibes repository](https://github.com/hainguyents13/mechvibes), its README and release list, checked on 28 November 2026.

## Where the name came from

Mechvibes started as an Electron app. MechvibesDX was a rewrite in Rust using [Dioxus](https://dioxuslabs.com), a Rust UI framework, which is where the "DX" comes from. Its release history:

| Date | Release |
| --- | --- |
| 8 June 2025 | MechvibesDX 0.1.0 beta |
| June 2025 | MechvibesDX 0.2 and 0.3 |
| August to October 2026 | MechvibesDX 0.5.2 to 0.8.4 |
| 30 October 2026 | Mechvibes 3.0.0 |
| 24 November 2026 | Mechvibes 3.5.11, the latest at the time of writing |

The repository that hosted MechvibesDX is now `hainguyents13/mechvibes`; the old `mechvibes-dx` address redirects there. The Electron version moved to `hainguyents13/mechvibes-electron`, which is archived and described as "no longer maintained."

The README states the relationship directly: "This is Mechvibes 3, the official Mechvibes app. It replaces Mechvibes 2 (the original Electron app) and MechvibesDX."

## What Mechvibes 3 does

From its feature list:

- Keyboard and mouse sounds, with separate packs and volumes. It ships 10 keyboard packs (Cherry MX, EG, Topre) and 4 mouse packs.
- Up to 32 overlapping sounds on their own audio thread.
- `Ctrl+Alt+M` mutes everything.
- An output device picker, 10 ambient sounds such as rain and coffee shop, and themes.
- Packs from the [mechvibes.com](https://mechvibes.com/sound-packs) library and a web [sound pack editor](https://editor.mechvibes.com).
- Classic Mechvibes packs are converted to its V2 format when they load.

It runs on Windows (installer), Linux (`.deb` and AppImage) and macOS (`.dmg`).

## Moving from MechvibesDX

The README has a short section for this:

- **Windows**: click **Update now** in MechvibesDX, or run the new installer. Settings and packs carry over. It says not to uninstall MechvibesDX first.
- **Linux**: install the new `.deb`; it replaces MechvibesDX.
- **macOS**: drag the new app to Applications and choose **Replace**. macOS may ask for Accessibility and Input Monitoring again. From 3.0.1, Mechvibes offers to move the old MechvibesDX app to the Trash.

On macOS, the app's bundle ID is still `com.hainguyents13.mechvibesdx`, which is why the README's permission reset commands use that name.

## Mechvibes DX on a Mac

The Mac build is where the README is most careful. It calls macOS support experimental: the app is ad-hoc signed, not notarized, and "not tested on real hardware by the maintainer." That means:

- The first launch needs **Open** from the right-click menu, or **Open Anyway** in Privacy & Security.
- It needs both **Accessibility** and **Input Monitoring**. Without Input Monitoring it is silent when another app is in front.
- After installing a new build, macOS ties permissions to the exact binary, so the README tells you to remove and re-add Mechvibes in both lists.
- One-click installs from the pack library work on Windows and Linux. On macOS you download a pack's ZIP and add it yourself.

None of that makes it unusable. It does mean a little upkeep on each update.

## A native Mac option

[KeyCream](/) is a free, open-source menu bar app written in Swift, only for the Mac. It does one thing: plays a real switch recording for every key you press. It asks only for Input Monitoring, has no window, and updates itself from GitHub with one click. It runs on macOS 14 Sonoma or later.

Its seven bundled packs come from the Mechvibes project under the MIT License: NovelKeys Cream, Cherry MX Black, Red, Brown and Blue, Everglide Crystal Purple and Everglide Oreo. You can hear them right now:

<PackSample id="NovelKeys-cream" />
<PackSample id="CherryMX-brown-pbt" />

Or type on the [switch sound board](/sounds) to hear each one under your own fingers.

What KeyCream does not do, so you can decide: no mouse sounds, no key-release sounds, no ambient sounds, no themes, and no pack import button. It reads the classic Mechvibes `config.json`, not the V2 format, and adding a pack means [building from source](/guide/building). If you want hundreds of community packs, Mechvibes is the better fit. [KeyCream vs Klack vs Mechvibes](/guide/keycream-vs-klack-vs-mechvibes) compares the three in a table.

## FAQ

<Faq />

## Related

- [Is Mechvibes safe?](/blog/is-mechvibes-safe): permissions, telemetry and what each app reads
- [Mechvibes custom sounds](/blog/mechvibes-custom-sound-packs): how sound packs work, V1 and V2
- [Keyboard switch sounds](/sounds): try all seven packs in the browser
- [Installation](/guide/installation): KeyCream in about a minute
