---
description: Build KeyCream yourself, run the website locally and understand how releases are made.
---

# Building from source

## Requirements

- macOS 14 or later
- Xcode 15.3 or later, or a Swift 5.10 toolchain

## Build the app

```bash
git clone https://github.com/halitsever/keycream.git
cd keycream
./build.sh
open build/KeyCream.app
```

`build.sh` compiles a release build and assembles `build/KeyCream.app` with its sound packs, translations and icons. It reads a few optional environment variables:

| Variable | Effect |
|---|---|
| `UNIVERSAL=1` | Builds for Apple Silicon and Intel together. Releases use this. |
| `VERSION=0.2.0` | Sets the version shown in Finder. |
| `BUILD_NUMBER=12` | Sets the build number. |
| `SIGN_IDENTITY="…"` | Signs with this certificate. By default a Developer ID Application certificate from your keychain is used if you have one. `-` forces an ad-hoc signature. |

::: tip
With an ad-hoc signature, macOS sees every new build as a different app and drops its Input Monitoring permission. Reset the entry after rebuilding, or build with a Developer ID certificate so the permission sticks.

```bash
tccutil reset ListenEvent com.halit.keycream
```
:::

## Project layout

| Path | What's there |
|---|---|
| `Sources/KeyCream/` | The app: menu, keyboard listener, audio engine, sound pack loading and translations lookup |
| `Resources/SoundPacks/` | Bundled sound packs, each with its license |
| `Resources/Localization/` | Menu text and the permission prompt, one folder per language |
| `Resources/Icons/` | App icon and menu bar icon |
| `docs/` | This website |

## Releases

Every push to `main` that changes the app builds a universal release and publishes it on GitHub. Version numbers come from the `VERSION` file: with `0.1` in it, releases count up as `0.1.0`, `0.1.1`, `0.1.2` and so on. Change the file to `0.2` or `1.0` to start a new series.

Pushes that only touch documentation or this website don't create a release.

## The website

The site lives in `docs/` and is published to GitHub Pages on every push to `main` that changes it.

```bash
cd docs
npm install
npm run dev
```

The **Listen** samples on the home page are rendered from the bundled packs. After changing a pack, render them again from the repository root:

```bash
swift docs/scripts/make-samples.swift Resources/SoundPacks docs/public/samples
```
