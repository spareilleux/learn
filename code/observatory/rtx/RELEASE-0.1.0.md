The [Observatory](https://spareilleux.github.io/learn/observatory/) (version 42 of the scene) as a native Windows program, on [NVIDIA's fork of Godot](https://github.com/NVIDIA-RTX/godot): path tracing with DLSS Ray Reconstruction, DLSS and frame generation.

**It needs a GeForce RTX card and Windows 10 or 11.** It was run on one machine only: a GeForce RTX 5080, driver 617.14, Windows 11.

## Start

1. Download `Observatory-RTX-0.1.0-win64.zip` below and extract all of it to a folder of your own.
2. Double-click `Observatory-RTX.cmd`. Windows may say it protected your PC, because the program is not signed: **More info**, then **Run anyway**.
3. The first time, a window asks whether to fetch NVIDIA's DLSS files: press **Enter**.

`README.txt` in the zip says the rest, in English, French and Spanish.

## What is in the zip, and what is not

- The scene, and a release build of NVIDIA's Godot fork (branch `backport/nvidia-pt-dlss-4.6.3`, commit `e1157bf10f`, with the local changes `LICENSES.txt` lists), under the MIT licence.
- **No file of NVIDIA's.** `setup-dlss.ps1` downloads NVIDIA's own [Streamline 2.10.0 release](https://github.com/NVIDIA-RTX/Streamline/releases/tag/v2.10.0) on your machine (203 MB, once), checks its SHA-256 and NVIDIA's signature on each of the twelve DLLs it keeps, and puts them beside the program with NVIDIA's licence texts. They are NVIDIA's software under NVIDIA's licences.

SHA-256 of `Observatory-RTX-0.1.0-win64.zip`: `26ffc57e9edf1d045ff114174bdaee95a96bada8ff3656f474b0618f80742d0b`

## Measured on the author's machine (RTX 5080, window of 3840 × 2054)

| | Frames rendered a second | GPU time a frame |
|---|---|---|
| Path tracing + Ray Reconstruction, DLSS Quality (what it starts at) | 60 | 14.6 ms |
| The same, DLSS Balanced | 60 | 11.7 ms |
| The same, DLAA | 34 | 29.6 ms |
| The same, DLSS Quality, 3 bounces instead of 2 | 55 | 18.3 ms |
| Rasterized, DLAA | 60 | 10.1 ms |

The program aims at 60 frames a second: under 56 it lowers the DLSS setting, and under 20 at the lowest setting it switches path tracing off and says so.

## Not verified

Any other card, any other machine, Windows 10, and a zip downloaded by a browser, which Windows marks as coming from the internet. Switching path tracing off and on again writes `Attempted to free invalid ID` errors to the log; the picture was right afterwards.

NVIDIA, GeForce, RTX and DLSS are trademarks of NVIDIA Corporation, which neither sponsors nor endorses this package.
