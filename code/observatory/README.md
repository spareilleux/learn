# Observatory: the scene's sources and native installers

The [Observatory](https://spareilleux.github.io/learn/observatory/) is a Godot 4.6 scene: a library and its gardens at night. Its web build is served from `public/demos/observatory/`. This folder holds what that build is made from, and what turns it into programs for Windows, Linux and macOS.

| Path | What it is |
|---|---|
| `project/` | The Godot project of the published web build, version 43 of the scene: `project.godot`, `main.tscn`, `scripts/` and `assets/`. It holds what that build holds and nothing more: the web preset's `exclude_filter` (the Prime Radiant, the unused steel portal, the metal gilding's shader) applies to this copy too. |
| `packaging/native.py` | Prepares a desktop build tree from `project/`: Forward+, the name "Observatory", export presets for Windows, Linux and macOS. It also writes the notices beside each export. |
| `packaging/windows/` | The `.msi` (WiX Toolset 5.0.2, per user, no administrator rights), and its install, update and uninstall test. |
| `packaging/linux/` | The `.deb` and the `.rpm`, their menu entry, and their install, run and remove test. |
| `packaging/macos/` | The `.dmg` (the app signed ad hoc, not notarized), and its test. |
| `packaging/godot/` | Godot 4.6.1's `LICENSE.txt` and `COPYRIGHT.txt`, at the tag `4.6.1-stable`. |
| `packaging/ASSETS.txt` | Where each of the scene's assets comes from. |
| `packaging/icons/` | The installers' icons, drawn from the project's own `icon.svg`. |

## Build

`.github/workflows/observatory-native.yml` runs on every pull request that touches this folder:
1. It downloads Godot 4.6.1's official Linux editor and export templates, and checks them against the SHA-512 sums Godot publishes.
2. It imports the scene, runs its selftest, and exports it for the three systems.
3. Each system builds its own packages, installs them, starts them headless and removes them.

A tag `observatory-v<version>` publishes the packages on a GitHub release. The version is the scene's: `scripts/build_info.gd`'s `VERSION` as `<n>.0.0`.

To build locally with Godot 4.6.1 and its export templates:

```sh
python packaging/native.py prepare project ../build-tree     # --templates <dir> without installed templates
cd ../build-tree
godot --headless --import
godot --headless --export-release "Linux" out/linux/observatory.x86_64
python ../observatory/packaging/native.py stage out/linux
bash ../observatory/packaging/linux/build-linux.sh out/linux 43.0.0 dist
```

## Where the scene is edited

The author works on the scene elsewhere and publishes the web build from there. Each publication copies its build tree here. Changes made here directly are overwritten by the next copy.

## Licences

The Godot Engine is under the MIT licence (`packaging/godot/LICENSE.txt`), and its third-party components are listed in `packaging/godot/COPYRIGHT.txt`. `packaging/ASSETS.txt` says how each of the scene's assets was made, with which tools and models, under which licences, and which credits it carries. No other licence is granted for the scene's scripts and assets.

The repository has no licence of its own, so they remain the author's. Each package carries these notices as `LICENSES.txt` and `GODOT_COPYRIGHT.txt`.
