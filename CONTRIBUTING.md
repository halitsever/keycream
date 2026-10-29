# Contributing to KeyCream

Thanks for your interest in KeyCream. Bug reports, ideas, translations, sound packs and code are all welcome.

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting bugs and asking for features

Open an [issue](https://github.com/halitsever/keycream/issues/new/choose) and pick the matching form. For a bug, include your macOS version, your Mac's chip (Apple Silicon or Intel), the KeyCream version from the release you installed, and the steps that trigger it.

Security problems should not go in a public issue. See [SECURITY.md](SECURITY.md).

## Building from source

You need macOS 14 or later and Xcode 15.3 or later (or a Swift 5.10 toolchain).

```bash
git clone https://github.com/halitsever/keycream.git
cd keycream
./build.sh
open build/KeyCream.app
```

`UNIVERSAL=1 ./build.sh` builds for both Apple Silicon and Intel, which is what releases use.

Each build gets a new ad-hoc signature, and macOS ties the Input Monitoring permission to that signature. After rebuilding, reset the old entry and grant access again:

```bash
tccutil reset ListenEvent com.halit.keycream
```

## Making a change

1. Fork the repository and create a branch from `main`.
2. Keep the change focused. One fix or feature per pull request is easiest to review.
3. Match the style of the surrounding code. Comments explain why something is done, not what the code already says.
4. Build with `./build.sh` and check the change in the running app.
5. Open a pull request and fill in the template.

Every push to `main` builds a new release automatically, so `main` should always build.

## Translations

Strings live in `Resources/Localization/<language>.lproj/`. `Localizable.strings` holds the menu text and `InfoPlist.strings` holds the Input Monitoring prompt. To add a language, copy the `en.lproj` folder, translate the values, add the language code to `CFBundleLocalizations` in `Info.plist` and to `Localization.languages` in `Sources/KeyCream/Localization.swift`.

Corrections from native speakers are especially welcome. The current translations outside English and Turkish have not been reviewed by one.

## Sound packs

KeyCream reads [Mechvibes](https://github.com/hainguyents13/mechvibes)-format packs from `Resources/SoundPacks/`. Both `multi` (one file per key) and `single` (one recording, each key a time range) packs work.

A new pack must come with a license that allows redistribution, such as MIT. Add its `LICENSE.txt` to the pack folder and a row to [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) stating where it came from. Packs without a clear license can't be accepted.
