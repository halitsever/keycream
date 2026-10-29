---
description: The seven bundled sound packs, where they come from, and how to add your own.
---

# Sound packs

A sound pack is a recording of a real mechanical keyboard. KeyCream ships seven of them. Choose one from **Sound Pack** in the menu, or listen to them on the [home page](/#packs).

| Pack | Switch | Recording |
|---|---|---|
| NovelKeys Cream | Linear | One file per key |
| Cherry MX Black | Linear | One take, PBT keycaps |
| Cherry MX Red | Linear | One take, PBT keycaps |
| Cherry MX Brown | Tactile | One take, PBT keycaps |
| Cherry MX Blue | Clicky | One take, PBT keycaps |
| Everglide Crystal Purple | Tactile | One take |
| Everglide Oreo | Tactile | One take |

**Linear** switches move straight down. **Tactile** ones have a small bump you can feel. **Clicky** ones add an audible click to that bump.

## How a key finds its sound

Each pack lists sounds by key. When you press a key, KeyCream looks up that key's sound in the selected pack and plays it. A pack can give every key its own recording, or reuse a few recordings across the keyboard.

When a pack loads, KeyCream decodes all of its sounds into memory and levels them, so playback starts the instant a key goes down.

## Credits and licenses

All bundled packs come from the open-source [Mechvibes](https://github.com/hainguyents13/mechvibes) project and are released under the MIT License. NovelKeys Cream was originally recorded by Ryan.

Each pack folder includes its license, and [THIRD_PARTY_NOTICES.md](https://github.com/halitsever/keycream/blob/main/THIRD_PARTY_NOTICES.md) lists where every pack came from. Switch names belong to their manufacturers and only describe the recorded switch.

## Adding your own pack

KeyCream reads the Mechvibes pack format. To add a pack, [build KeyCream from source](/guide/building) with the pack folder placed in `Resources/SoundPacks/`. It appears in the menu under the `name` from its `config.json`.

A pack folder holds a `config.json` and its audio files. There are two kinds.

**One file per key** (`multi`). Each key points to a file:

```json
{
  "name": "My Keyboard",
  "key_define_type": "multi",
  "sound": "a.wav",
  "defines": {
    "30": "a.wav",
    "57": "space.wav",
    "28": "enter.wav"
  }
}
```

**One recording** (`single`). Each key points to a start time and a length in milliseconds inside one file:

```json
{
  "name": "My Keyboard",
  "key_define_type": "single",
  "sound": "sound.wav",
  "defines": {
    "30": [28961, 164],
    "57": [49628, 230]
  }
}
```

The numbers are PC keyboard scan codes, the same ones Mechvibes uses: `30` is <kbd>A</kbd>, `57` is <kbd>space</kbd> and `28` is <kbd>return</kbd>. Use WAV, AIFF or another format macOS can play. OGG files need converting first.

::: warning
Packs you want to share in a pull request must allow redistribution, for example under the MIT License. See [Contributing](https://github.com/halitsever/keycream/blob/main/CONTRIBUTING.md#sound-packs).
:::
