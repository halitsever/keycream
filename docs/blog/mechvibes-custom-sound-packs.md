---
title: "Mechvibes Custom Sounds: How Sound Packs Work"
titleTemplate: false
description: "How Mechvibes custom sound packs work: the folder, config.json in the classic V1 and new V2 formats, and adding a pack to Mechvibes 3 or KeyCream."
date: 2026-11-28
faq:
  - q: "How do I add custom sounds to Mechvibes?"
    a: "In Mechvibes 3, open Sound packs, pick the Keyboard or Mouse tab, click Add and select the pack's ZIP file. On Windows and Linux you can also click Install in Mechvibes on a pack's page in the mechvibes.com library."
  - q: "What is in a Mechvibes sound pack?"
    a: "A folder with a config.json that names the pack and maps keys to sounds, one or more audio files (OGG, WAV, MP3 or FLAC), and optionally an icon.png."
  - q: "What is the difference between V1 and V2 Mechvibes packs?"
    a: "V1 packs use numeric key codes and give start time and length in milliseconds. V2 packs use browser key names such as KeyA and give start and end times. Mechvibes 3 converts V1 packs to V2 when they load and keeps a backup of the old config."
  - q: "Can I use Mechvibes packs in KeyCream?"
    a: "Classic V1 packs, yes: KeyCream reads that format and its bundled packs come from Mechvibes. It does not read V2, has no import button, and needs WAV or another format macOS plays. A new pack is added by building KeyCream from source."
---

# Mechvibes custom sounds: how sound packs work

<p class="post-meta">Halit Sever · 28 November 2026</p>

A Mechvibes sound pack is a small folder: a recording of a keyboard and a file that says which part of the recording each key plays. Once you know the two formats, you can read, fix or make one by hand. This post explains both formats from the Mechvibes [README](https://github.com/hainguyents13/mechvibes) and its [V2 format guide](https://github.com/hainguyents13/mechvibes/blob/main/docs/soundpack-config-v2.md), checked on 28 November 2026, and shows how KeyCream reads the classic one.

## What is in a pack

```txt
my-keyboard-pack/
├── config.json        name, author and key mappings (required)
├── sound.ogg          the audio (OGG, WAV, MP3 or FLAC)
└── icon.png           optional thumbnail
```

There are two ways to map keys to audio:

- **single**: one recording, and each key plays a slice of it.
- **multi**: one file per key.

## The classic format (V1)

This is the format the original Electron Mechvibes used, and the one most older packs are in. Keys are numeric scan codes, and in a `single` pack each value is a start time and a length in milliseconds:

```json
{
  "name": "My Keyboard",
  "key_define_type": "single",
  "sound": "sound.ogg",
  "defines": {
    "30": [28961, 164],
    "57": [49628, 230]
  }
}
```

`30` is the A key, `57` is space and `28` is return. In a `multi` pack the value is a file name instead: `"30": "a.wav"`.

## The new format (V2)

Mechvibes 3 uses a second format. The main changes, from its guide:

| | V1 | V2 |
| --- | --- | --- |
| Key names | numeric codes | browser `KeyboardEvent.code` names, such as `KeyA` |
| Timing | `[start, length]` | `[start, end]` in a `timing` list |
| Audio field | `sound` | `audio_file` |

```json
{
  "name": "Typewriter",
  "author": "You",
  "config_version": "2",
  "definition_method": "single",
  "audio_file": "typewriter-click.ogg",
  "definitions": {
    "KeyA": { "timing": [[0, 50]] },
    "KeyB": { "timing": [[50, 100]] }
  },
  "options": { "recommended_volume": 0.8, "random_pitch": false },
  "soundpack_type": "Keyboard"
}
```

The app rejects a V2 config without `name`, `author` and `definitions`. With two timing segments, the second plays when the key comes up, which gives key-release sounds. `soundpack_type` can also be `Mouse`. `random_pitch` varies the pitch of each keystroke slightly.

## Converting old packs

You do not need to rewrite V1 packs for Mechvibes 3. When it loads one, it converts the config to V2, keeps the original as `config.json.v1.backup` and leaves the audio files alone. Multi packs are converted to single packs on the way.

## Adding a pack to Mechvibes 3

- **From the library**: on [mechvibes.com/sound-packs](https://mechvibes.com/sound-packs), click **Install in Mechvibes** on a pack's page. This works on Windows and Linux. On macOS, download the ZIP instead.
- **From a ZIP**: in the app, **Sound packs**, then the **Keyboard** or **Mouse** tab, **Add**, **Select file**.
- **From a folder**: **Sound packs > Manage** opens the custom packs folder. Copy the folder in and click **Refresh**.
- **Make one**: the [sound pack editor](https://editor.mechvibes.com) builds the config for you.

Custom packs live in `~/Library/Application Support/Mechvibes/soundpacks/` on macOS, `~/.local/share/mechvibes/soundpacks/` on Linux and `%APPDATA%\Mechvibes\soundpacks\` on Windows.

## How KeyCream reads packs

[KeyCream](/) is a Mac menu bar app that reads the classic V1 format. Its seven bundled packs come from the Mechvibes project under the MIT License, and you can hear each of them on the [switch sound board](/sounds).

When a pack loads, KeyCream decodes every sound into memory and levels it, so no key is much louder than another. Then, for each key press, it looks up the key's scan code in the pack and plays that slice or file.

Limits worth knowing before you try your own pack:

- V1 only. V2 packs from Mechvibes 3 are not read.
- Audio has to be a format macOS plays, such as WAV or AIFF. OGG files need converting first.
- There is no import button. You place the folder in `Resources/SoundPacks/` and [build from source](/guide/building); the pack appears in the menu under its `name`.

The full example configs are on [Sound packs](/guide/sound-packs#adding-your-own-pack). If you want to share a pack in a pull request, its license has to allow redistribution.

## FAQ

<Faq />

## Related

- [Mechvibes DX](/blog/mechvibes-dx): what it was and what Mechvibes 3 changed
- [Is Mechvibes safe?](/blog/is-mechvibes-safe): permissions and data for both apps
- [Sound packs](/guide/sound-packs): KeyCream's packs and credits
- [Keyboard switch sounds](/sounds): hear every bundled pack
