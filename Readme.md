<p align="center" class="logo-section">
<img src="Resources/Icons/AppIcon-1024.png" height="80" width="80"/>
</br>
<img src="https://halitsever-api.vercel.app/api/repo-title?title=KeyCream">

<p align="center">
⌨️ Mechanical keyboard sounds for your Mac, right from the menu bar.<br>
<br/>
<br/>
<img src="https://img.shields.io/github/sponsors/halitsever"/>
</p>
<p align="center">
<a align="center" href="https://halitsever.github.io/keycream/">Documentation</a>
  </p>
</p>

<p align="center">
<img src="https://halitsever-api.vercel.app/api/details"/>
</p>

- 🎧 [**Seven sound packs**](https://halitsever.github.io/keycream/#packs) - NovelKeys Cream, Cherry MX Black, Red, Brown and Blue, Everglide Crystal Purple and Oreo, each a recording of a real keyboard.
- ⌨️ [**Every key sounds right**](https://halitsever.github.io/keycream/#how) - letters, Space, Return, Delete, the modifiers and the function row each play their own recording.
- 🎚️ [**Even volume**](https://halitsever.github.io/keycream/#how) - every key is leveled when a pack loads, so no single key is suddenly louder than the rest.
- 🖐️ [**Natural typing**](https://halitsever.github.io/keycream/#how) - holding a key plays one click, and fast typing overlaps instead of cutting off.
- 🧭 [**Menu bar only**](https://halitsever.github.io/keycream/#using) - no Dock icon, it opens at login and remembers your settings.
- 🌍 [**12 languages**](https://halitsever.github.io/keycream/guide/usage#languages) - follows your Mac's language, or pick one from the menu.
- 🔒 [**Private**](https://halitsever.github.io/keycream/guide/privacy) - reads only which key went down, never what you type, and makes no network connections.
- 📦 [**Your own packs**](https://halitsever.github.io/keycream/guide/sound-packs#adding-your-own-pack) - KeyCream reads the Mechvibes pack format, so you can add any pack you like.

<p align="center" >
<img src="https://halitsever-api.vercel.app/api/installation"/>
</p>

Download **KeyCream-x.y.z.zip** from the [latest release](https://github.com/halitsever/keycream/releases/latest), unzip it and move KeyCream to Applications. It needs macOS 14 or later and runs on Apple Silicon and Intel Macs.

If macOS blocks the first launch, click **Open Anyway** under **System Settings → Privacy & Security**, or run:

```sh
xattr -dr com.apple.quarantine /Applications/KeyCream.app
```

Then turn on KeyCream under **Privacy & Security → Input Monitoring**. The [installation guide](https://halitsever.github.io/keycream/guide/installation) covers every step.

To build it yourself you need Xcode 15.3 or later:

```sh
./build.sh
open build/KeyCream.app
```

<p align="center" href="https://github.com/halitsever/keycream/issues">
<img src="https://halitsever-api.vercel.app/api/issue"/>
</p>

<p align="center">
<img src="https://halitsever-api.vercel.app/api/sponsor"/>
</p>

<p align="center">
<img src="https://halitsever-api.vercel.app/api/license"/>
</p>

<p align="center">
MIT. The bundled sound packs come from <a href="https://github.com/hainguyents13/mechvibes">Mechvibes</a> and keep their own licenses, listed in <a href="THIRD_PARTY_NOTICES.md">THIRD_PARTY_NOTICES.md</a>.
</p>
