The [Observatory](https://spareilleux.github.io/learn/observatory/) as a native program for Windows, Linux and macOS: version {version}, on the [Godot Engine](https://godotengine.org/) 4.6.1. It renders with Godot's Forward+ renderer (Vulkan, Metal or Direct3D 12), and falls back to OpenGL where none of those is available. Built and tested by GitHub Actions from [`code/observatory`](https://github.com/spareilleux/learn/tree/main/code/observatory).

## Install

- **Windows 10 or 11**: download `Observatory-{version}-windows-x64.msi` and double-click it.
  - It installs for your account only, without administrator rights, into `%LOCALAPPDATA%\Programs\Observatory`, and adds **Observatory** to the Start menu.
  - The installer is not signed, so Windows may say it protected your PC: **More info**, then **Run anyway**.
  - To remove it: **Settings → Apps → Installed apps**.
- **Debian, Ubuntu**: download `observatory_{version}_amd64.deb`, then run `sudo apt install ./observatory_{version}_amd64.deb`. **Observatory** appears among your applications. To remove it: `sudo apt remove observatory`.
- **Fedora, openSUSE**: download `observatory-{version}-1.x86_64.rpm`, then run `sudo dnf install ./observatory-{version}-1.x86_64.rpm`. To remove it: `sudo dnf remove observatory`.
- **macOS 11 or later (Apple silicon or Intel)**: download `Observatory-{version}-macos.dmg`, open it and drag **Observatory** onto **Applications**.
  - The app is signed ad hoc but not notarized, which needs a paid Apple Developer account.
  - The first time, Control-click it and choose **Open**. On macOS 15, use **System Settings → Privacy & Security → Open Anyway** instead.

## Tested by the workflow that built them

Each package was installed, then started headless for thirty frames with no error line, then removed:
- the `.msi` on Windows Server 2025, for one account, including an update to a test package one patch up;
- the `.deb` on Ubuntu 24.04 and Debian 12;
- the `.rpm` on Fedora 41;
- the `.dmg` on macOS 15 (Apple silicon).

Before that, the scene passed its selftest under Forward+.

The workflow has no graphics card, so the picture itself, a real window and a real install on a reader's machine remain *to verify* on each system.

`LICENSES.txt`, in each package, gives the engine's licence and where each of the scene's assets comes from.

## SHA-256

