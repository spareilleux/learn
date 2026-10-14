The [Observatory](https://spareilleux.github.io/learn/observatory/) (version 43 of the scene) as a native Windows program, on [NVIDIA's fork of Godot](https://github.com/NVIDIA-RTX/godot): path tracing with DLSS Ray Reconstruction, DLSS and frame generation.

**It needs a GeForce RTX card and Windows 10 or 11.** It was run on one machine only: a GeForce RTX 5080, driver 617.14, Windows 11.

## New since 0.1.0

- **A column of buttons** on the left, one for each feature, with its state, its key and a line that says what it does.
- **Max out** (F6): path traced DLAA, 3 light bounces, frame generation and everything that moves. It renders 23 frames a second (about 46 shown with frame generation), 40.6 ms of GPU a frame. Press it again to go back to the start. The gilt's metal or flat switch is gone: the gilding stays metal.
- **Light bounces** (F5): 1 to 4 while path tracing.
- **Things that move**:
  - glyphs falling down the green beams of light, 64 original glyphs that a shader draws from strokes at the start (no font, no image);
  - the nine departments' banners as cloth in a draught, which the path tracer sees move;
  - a little dust in the lamps' light.

  The three together cost 0.3 ms a frame.
- **256 lights in the rays** instead of 64 (a change to the fork, listed in `LICENSES.txt`). The reading lamps are three times brighter while path tracing. At the start view, the share of nearly black pixels went from 27 % to 17 %, for the same GPU time.
- **Without NVIDIA's files**, the anti-aliasing is MSAA 4x + TAA instead of MSAA 2x. Measured while the eye turns, MSAA alone flickers about ten times more, even at 8x. The column also offers MSAA 8x + TAA.
- **DLSS Ultra Performance** is no longer in the F7 list: it finds no DLSS mode at this window size.

## Install

**The installer (`Observatory-RTX-0.2.0-win64.msi`)**

1. Download it below and double-click it. It shows a progress bar and asks nothing.
   - It installs for your Windows account only, without administrator rights, into `%LOCALAPPDATA%\Programs\Observatory-RTX`.
   - It adds **Observatory RTX** to the Start menu.
   - Windows may say it protected your PC, because the installer is not signed: **More info**, then **Run anyway**.
2. Start **Observatory RTX** from the Start menu. The first time, a window asks whether to fetch NVIDIA's DLSS files: press **Enter**.
3. To remove it, go to **Settings → Apps → Installed apps**. The DLSS files it fetched go with it.

**Or the zip (`Observatory-RTX-0.2.0-win64.zip`)**

1. Extract all of it to a folder of your own.
2. Double-click `Observatory-RTX.cmd`.
3. The first time, press **Enter** to fetch the DLSS files, as above.

`README.txt`, installed beside the program, says the rest in English, French and Spanish.

## What is in the package, and what is not

- The scene, and a release build of NVIDIA's Godot fork, under the MIT licence: branch `backport/nvidia-pt-dlss-4.6.3`, commit `e1157bf10f`, with the local changes `LICENSES.txt` lists. The installer and the zip hold the same eight files, byte for byte.
- **No file of NVIDIA's.** `setup-dlss.ps1` downloads NVIDIA's own [Streamline 2.10.0 release](https://github.com/NVIDIA-RTX/Streamline/releases/tag/v2.10.0) on your machine (203 MB, once).
  - It checks the archive's SHA-256 and NVIDIA's signature on each of the twelve DLLs it keeps.
  - It puts them beside the program with NVIDIA's licence texts.
  - They are NVIDIA's software under NVIDIA's licences.
- For development only, `--rtx-bridge` opens a port on `127.0.0.1` through which a local agent can move the eye and take pictures. Without that argument, the program opens no port.

`SHA256SUMS.txt` below lists the SHA-256 of both files:

- `Observatory-RTX-0.2.0-win64.msi`: `5141ac97010db3289cf970b0526ea1c253db08f912aa7543f50040e39dc59d01`
- `Observatory-RTX-0.2.0-win64.zip`: `35c6c9eb9881dadf8fa5200dad873ff069150c61744ec6f2369d128e5e2b85b4`

The installer was built with [WiX Toolset](https://wixtoolset.org/) 5.0.2. Its checks on the author's machine:

- WiX's validation passed.
- An administrative image (`msiexec /a`, which only unpacks) gave the eight files, each equal to the zip's.

The zip, unpacked into a new folder, was then run on the author's machine:

- Without NVIDIA's files, it starts rasterized with MSAA 4x + TAA: 60 frames a second, 8.2 ms. The DLSS and path tracing buttons are disabled, and a line says what is missing.
- With NVIDIA's twelve signed DLLs, it starts path traced at DLSS Quality: 60 frames a second, 15.2 ms, and Ray Reconstruction runs.

## Measured on the author's machine (RTX 5080, window of 3840 × 2054)

| | Frames rendered a second | GPU time a frame |
|---|---|---|
| Path tracing + Ray Reconstruction, DLSS Quality (what it starts at) | 60 | 15.3 ms |
| Max out: DLAA, 3 bounces, frame generation | 23 (about 46 shown) | 40.6 ms |
| Rasterized, DLAA | 60 | 10.0 ms |
| Without NVIDIA's files: MSAA 4x + TAA | 60 | 8.2 ms |

The program aims at 60 frames a second. Under 56, it lowers the DLSS setting. Under 20 at the lowest setting, it switches path tracing off and says so. Max out does not hold 60 frames a second.

## Not verified

- An update over 0.1.0. The installer is 0.1.0's with one change: its uninstall now removes only its own registry key. The update itself was tested only from 0.1.0 to a test package, before that change.
- Any other card, any other machine, and Windows 10.
- An installer or a zip downloaded by a browser, which Windows marks as coming from the internet.

The rasterized hall is darker than the path traced one, and its piers look blue-grey.

Switching path tracing off and on again writes `Attempted to free invalid ID` errors to the log; the picture was right afterwards.

NVIDIA, GeForce, RTX and DLSS are trademarks of NVIDIA Corporation, which neither sponsors nor endorses this package.
