# Observatory RTX: the native package for readers elsewhere

Receipt, 2026-10-13. The author's requests, as written:

- "je veux pouvoir lancer la version fork depuis https://spareilleux.github.io/learn/observatory/ avec le raytracing et tout les features (RTX 5080 requise_"
- "Il faut que ca puisse marcher pour des utilisateurs distant", "assure toi que les utilisateurs distant peuvent faire la setup des dependencies de la maniere le plus simple possible"
- Licence choice (asked, answered): "Zip sans DLL NVIDIA (Recommended)".
- "Les Buttons toggle devraient être évident sur version Desktop avec rtx", "On devrait être en photorealistic si la carte le permet", "Vérifie si on a de l'anti alias au max que la carte permet", "La bibliothèque paraît sombre", "on vise 60 images par seconde", "Sur une 5080", "En path tracing on veut s'assurer de beaux effets ombre et lumière et reflections", "Va y au meilleur rapport qualité/fps", "Rajoute des sources de lumière au besoin", "Analyse les problémes d'aliasing".

## What the package is

`Observatory-RTX-0.1.0-win64.zip` (79,970,397 bytes, SHA-256 `26ffc57e9edf1d045ff114174bdaee95a96bada8ff3656f474b0618f80742d0b`, build tree 4): the scene at version 42 (Foundation copy at `5ae71ee`), a release template of NVIDIA's Godot fork (`backport/nvidia-pt-dlss-4.6.3`, `e1157bf10f`, 19 files changed locally), the player (`rtx/`), two `.cmd`, `setup-dlss.ps1`, `README.txt` (EN/FR/ES), `LICENSES.txt`, `GODOT_COPYRIGHT.txt`. No DLL and no file signed by NVIDIA: `build-rtx.ps1 -Stage package` refuses either.

- `build-rtx.ps1 -N <n> -Stage tree|import|export|package` builds it from scratch (192 s for the four stages).
- `iterate-rtx.ps1` re-exports the player alone into an imported tree; `test-rtx.ps1`, `test-cmd.ps1` and `sweep-rtx.ps1` run the package from a folder of its own, with `rtx_probe.gd` (in the pack) writing down what the run shows; `crop.ps1` cuts a capture at its own pixels.
- A release template takes no `--script` (`main/main.cpp` clears it without `OVERRIDE_PATH_ENABLED`): the project names `ObservatoryRtx` as its main loop and an empty scene as its main scene, and the program needs no argument.

## Measured (RTX 5080, driver 617.14, Windows 11, window of 3840 x 2054, the hall's start view)

From `logs/sweep1`, `sweep2`, `sweep3` (2026-10-13), each figure 5 s after its setting, GPU time from the viewport's own measure:

| Path traced, Ray Reconstruction | fps rendered | GPU ms | mean luma | nearly black |
|---|---|---|---|---|
| DLSS Quality, 3 bounces, fill 1 (the player before these runs) | 55 | 18.0 | 0.091 | 61 % |
| DLSS Quality, 3 bounces, fill 20 | 55 | 18.3 | 0.160 | 25 % |
| DLSS Quality, 2 bounces, fill 20 (the package) | 60 | 14.6 | 0.158 | 27 % |
| DLSS Balanced, 2 bounces | 60 | 11.7 | 0.159 | 26 % |
| DLSS Performance, 2 bounces | 60 | 9.5 | 0.158 | 26 % |
| DLAA, 2 bounces | 34 | 29.6 | 0.155 | 27 % |
| DLAA, 3 bounces | 28 | 35.9 | 0.158 | 26 % |
| Rasterized, DLAA | 60 | 10.1 | 0.176 | 10 % |
| Rasterized, DLSS Quality | 60 | 7.0 | 0.174 | 10 % |

60 is the most any run showed: the window follows the screen.

- **The dark hall.** Rasterized, an ambient colour reaches everywhere; in the rays (patch `rt_ambient_fill`) only where a bounce leaves the scene. The three soft fill lights of `observatory.gd` at 20 times their energy bring the start view from 0.091 to 0.158. Twice the exposure reached 0.151 by blooming the lamps and the beams, and left the books dark; six times the ambient energy, 0.098.
- **Bounces.** One bounce costs 2 to 3.6 ms; the mean luma moves by under 1 % between 2, 3 and 4. A change of bounces or samples compiles a new variant of the hit shaders: for some seconds the frame is cheaper and wrong (9 ms read at 5 s in `sweep1`), so `sweep2` held each for 40 s.
- **Lights cost where they reach.** Sixteen lamps of 6.5 m on the wing's gallery took the wing's views from 14.0 to 17.3 ms (the fork draws candidates among the lights and traces a shadow ray for a valid one: `raytracing_lights_inc.glsl`). At 4.5 m and energy 4 the same views take 14.2 to 14.6 ms, and the gallery view's mean luma goes from 0.085 to 0.212 (`logs/views-gallery1`, `views-gallery2`).
- **Edges** (`--rtx-motion`, a region of shelves and a pier's gilt edge, 339 x 330 pixels). At rest, two frames in a row differ by 0.0003 of full scale when nothing in the region moves (a beam's pulse crosses its corner in some captures: 0.003 to 0.004), in every DLSS setting, path traced or not. Sharpness (mean step between neighbouring pixels): DLAA 0.0255, Quality 0.0241, Balanced 0.0232, Performance 0.0226; while the camera turns 2 degrees a second, 0.0242, 0.0221, 0.0215, 0.0207. No stair step was seen in the crops at 100 % (`crop.ps1`). Without NVIDIA's files the program runs the scene's own MSAA 2x: that case was not measured for edges.
- **Views** (`logs/sweep3`, `views-gallery2`, DLSS Quality, 2 bounces): hall 15.2 ms, wing 14.2 to 14.6, the portal 15.6, terrace 8.1, basin 8.0, palace 7.8, roof and city 10.2; 60 fps in each.

## Tested from the zip (build 4, `C:/tmp/observatory-rtx-test-5`)

`logs/nodlss-b4`, `cmd-declined-b4`, `cmd-setup-b4`, `cmd-dlss-b4`, `dlss-b4`, `ladder-b4`:

- no NVIDIA file: starts rasterized, MSAA 2x, 60 fps, 8.7 ms, the DLSS and path tracing buttons disabled, a line saying what is missing;
- `Observatory-RTX.cmd` answered N: the marker is written, the program starts, no NVIDIA module loaded;
- `Setup-DLSS.cmd`: 12 DLLs and 5 licence texts in 20 s;
- `Observatory-RTX.cmd` with them: 9 NVIDIA modules loaded from the folder;
- the probe: starts path traced at DLSS Quality and stays there (60 fps, 14.7 ms, mean luma 0.158); a real click on the frame generation button switches it on (Streamline's status says so); a click on the path tracing button gives DLAA rasterized; the mouse mode stays 0 after each click.

## Not verified

- Any other card, any other machine, Windows 10.
- A zip downloaded by a browser (Mark of the Web, SmartScreen) and a machine without the Visual C++ runtime.
- Whether frame generation runs on RTX 20 and 30 series cards.

## Known

- Switching the path tracer off and on again writes about 420 `Attempted to free invalid ID` errors (`rendering_device.cpp:7824`) to the log; the views taken afterwards were right (`logs/sweep3`).
- `ERROR: Formatting error in string "RT Material UBO falling back to dedicated buffer (%s)…"` once a run: the fork's own message, misformatted.
- Rasterized, DLSS Ultra Performance finds no mode ("Couldn't find an appropriate DLSS mode"): the player stops at Performance there.

## The installer (2026-10-14)

The author: « Peut on avoir un .msi sous Windows et leur équivalent sur Linux ou macOS », then « On a dit qu'on voulait un .msi pas un zip ??? ». `msi/Observatory-RTX.wxs`, built by `msi/build-msi.ps1` with WiX Toolset 5.0.2 (MS-RL; from WiX 6 the Open Source Maintenance Fee applies), a local .NET tool in `C:/tmp/tools/wix5`, never a global one.

- The zip's eight files, for the current user (`Scope="perUser"`), into `%LOCALAPPDATA%\Programs\Observatory-RTX`; a Start menu shortcut to `Observatory-RTX.cmd`; the icon drawn from `icon.svg` (`msi/make_ico.py`; the exe as icon source would have copied its 67 MB into the Icon table). No NVIDIA file. 71,016,448 bytes against the zip's 79,970,397.
- Uninstalling removes what `setup-dlss.ps1` writes (the twelve DLLs, `nvidia-licenses\`, `dlss-declined.txt`). An update must not: `MajorUpgrade Schedule="afterInstallExecute"`, so the older package's removal leaves the shared components and their RemoveFile rows do not run; `REINSTALLMODE=amus`, because the exe keeps Godot's file version 4.6.3 from one package to the next and an equal version is not replaced by default (ICE40 warns about it; ICE91 warns that the files go to a per-user folder, which is the point).
- `build-msi.ps1`: `wix msi validate` exit 0 (ICE40, ICE91 warnings only); `msiexec /a` unpacks the eight files, each equal to the package's.
- `test-msi.ps1` on this machine, not elevated (`C:/tmp/observatory-msi-test-1/report.json`): install exit 0, eight files equal, the shortcut's target and folder, the uninstall entry 0.1.0; the installed exe headless for ten frames exit 0, no error line; an update to a test package numbered 0.1.1 over twelve empty stand-ins named as NVIDIA's DLLs, a notice and the marker: exit 0, the stand-ins kept, the edited README rewritten, one uninstall entry (0.1.1); uninstall exit 0: no folder, shortcut, HKCU key or uninstall entry left, `%LOCALAPPDATA%\Programs` kept.
- Published on the release `observatory-rtx-0.1.0` beside the zip, SHA-256 `3c8aabc666f91583e6a96a80481fee8704e12cf3e3df0a0a611bbf09ae42741b` (downloaded back, equal); installed on the author's machine in place of the zip's copy, which is kept in `C:/tmp/rtx-host-install/manual-backup`.
- *To verify*: an installer downloaded by a browser (Mark of the Web, SmartScreen), Windows 10, another account. `README.txt` still opens on the zip's steps.