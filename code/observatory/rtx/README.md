# Observatory RTX: the native package's sources

[Observatory RTX](https://github.com/spareilleux/learn/releases?q=observatory-rtx) is the [Observatory](https://spareilleux.github.io/learn/observatory/) on [NVIDIA's Godot fork](https://github.com/NVIDIA-RTX/godot), with DLSS, frame generation and path tracing, for a GeForce RTX card on Windows. The package holds no file of NVIDIA's. `setup-dlss.ps1` fetches them from NVIDIA's own release on the reader's machine, once the reader has accepted NVIDIA's licences.

This folder is a copy of the build tooling, which runs on the author's machine. `sync_rtx_learn.py` refreshes it, and the paths in the scripts are that machine's. The scene itself is `../project/`.

| Path | What it is |
|---|---|
| `rtx_play.gd` | The player, the package's main loop: path traced from the start where DLSS runs, a DLSS setting steered towards 60 frames a second, the bar of buttons, and the lights the path tracer needs. |
| `player-base/` | What `rtx_play.gd` extends: `dlss_play.gd` (keys, badge, settings) and `pt_scene.gd` (the night sky and trees for the path tracer). |
| `rtx_probe.gd`, `test-rtx.ps1`, `sweep-rtx.ps1` | The package run as a reader runs it, with what it shows written down: settings swept, edges at rest and while turning, views of the place. |
| `rtx_bridge.gd` | The scene agent's bridge (`-- --rtx-bridge`): JSON lines on 127.0.0.1, which an MCP server turns into tools. |
| `build-rtx.ps1`, `assemble_rtx.py`, `iterate-rtx.ps1` | The build: the tree, its import, the export from the fork's release template, the package. |
| `msi/` | The `.msi` (WiX Toolset 5.0.2, per user) and its install, update and uninstall test. |
| `fork/` | The local patches to the fork, one script each with why, `local-changes.diff` (the whole `git diff`) and `BASE.txt` (the commit they apply to). |
| `NOTES.md` | The receipts: what was asked, what was measured, what remains to verify. |
| `README.txt`, `ASSETS.txt`, `notices_rtx.py` | What the package carries for its reader: how to start, licences and credits. |
