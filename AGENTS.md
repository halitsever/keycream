# KeyCream

macOS menu bar app (Swift, AppKit, SwiftUI settings window) that plays mechanical keyboard sounds for every keystroke, used by Mac owners who download it from GitHub Releases.

## Verify a change

- CI runs on `macos-15` for every pull request: `UNIVERSAL=1 ./build.sh`. Run the same before pushing app changes.
- The app only builds on macOS 14+ with Xcode 15.3 or a Swift 5.10 toolchain. There is no test target.
- For website changes: `cd docs && npm ci && npm run build`. The site deploys with `npm ci`, so keep `docs/package-lock.json` in sync with `docs/package.json`.

## Gotchas

- Every push to `main` that touches app files cuts a signed GitHub release. Pushes that only change `**.md`, `docs/**`, `assets/**` and a few config paths are skipped (see `paths-ignore` in `.github/workflows/release.yml`).
- `VERSION` holds only `major.minor`. The release workflow derives the patch number from existing `v*` tags, so never write a full version into it.
- Ad-hoc signed local builds lose the Input Monitoring permission on every rebuild: `tccutil reset ListenEvent com.halit.keycream`.
- UI strings live in 12 `Resources/Localization/*.lproj` folders. A new string needs an entry in every `Localizable.strings`, and a new language also goes into `CFBundleLocalizations` in `Info.plist` and `Localization.languages`.
- `docs/public/samples/*.wav` are generated from the bundled packs. After changing a pack, rerun `swift docs/scripts/make-samples.swift Resources/SoundPacks docs/public/samples`.
- Bundled sound packs keep their own licenses. Record any new pack in `THIRD_PARTY_NOTICES.md`.

## Docs and site

- VitePress site in `docs/`, base path `/keycream/`, deployed to https://halitsever.github.io/keycream/ by `.github/workflows/docs.yml` on pushes to `main` that touch `docs/**`.
- SEO head tags, canonical URLs and JSON-LD are set in `docs/.vitepress/config.mts`. `docs/public/llms.txt` lists the docs pages; update it when a page is added or renamed.

## Conventions

- Conventional-commit subject lines only, in English, with no body and no trailer.
- Work on a branch and open a pull request. The owner merges.
- No emoji in new text. Code comments are short, one line where possible, and explain why.
- The README follows the owner's template. Every image served from `halitsever-api.vercel.app` stays byte-for-byte; only the `title=` value of `api/repo-title` and the issue wrapper link may be corrected.
- Version series changes and releases are decided by the owner.
