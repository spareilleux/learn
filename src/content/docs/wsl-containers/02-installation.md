---
title: 2. Installation
description: Switch WSL to pre-release, verify wslc and troubleshoot a failed update.
sidebar:
  order: 2
---

## Which version do you need?

`wslc.exe` requires **WSL 2.9.3 or later**. For now this branch only exists as a **pre-release**: the stable version (2.7.x in September 2026) does not include `wslc`.

Check your version:

```powershell
wsl --version
```

## Updating

```powershell
wsl --update --pre-release
```

:::caution[The update stops WSL]
All WSL distributions stop during the update — including those of [Docker Desktop](https://docs.docker.com/desktop/) and [Podman](https://podman.io/). Save whatever is running in your containers first.
:::

## Verifying

```powershell
wsl --version        # should show 2.9.3 or later
wslc --version       # confirms the CLI is available (wslc version works too)
wslc run --rm hello-world
```

```text
WSL version: 2.9.11.0
Kernel version: 6.18.40.1-1
...
wslc 2.9.11.0
Image 'hello-world' not found, pulling
...
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

The last test downloads the `hello-world` image and prints its welcome message. "Hello from Docker!" is just the text baked into the image: Docker Desktop plays no part, the container runs under `wslc`.

:::caution[`wslc` is not recognized]
`wslc.exe` is installed in `C:\Program Files\WSL\`, which is on the machine `PATH`, but a program receives a copy of the environment when it starts. A new tab of a [Windows Terminal](https://learn.microsoft.com/windows/terminal/) started **before** the update inherits the old `PATH`. Close every Windows Terminal window, or reload the `PATH` in the current PowerShell:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
```

The same applies to an IDE opened before the update: MSBuild then fails with `WSLC0001` (see [lesson 9](../09-csharp-api/)).
:::

## Troubleshooting: the installation fails (error 1921 / 1603)

This is what happened to me (see the [journal](../journal/)). The command shows the progress bar, then returns — but `wsl --version` still shows the old version.

**Diagnosis** — the Windows *Application* log contains:

```text
Error 1921. Service 'WSL Service' (WSLService) could not be stopped.
Installation success or error status: 1603.
```

To find it:

```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='MsiInstaller'; StartTime=(Get-Date).AddHours(-1)} |
  Select-Object TimeCreated, Id, Message
```

**Cause** — the MSI installer needs to stop the `WSLService` service, but processes keep it busy: Docker Desktop, Podman, open WSL terminals…

**Fix** — the sequence that worked for me. First, from a normal terminal:

```powershell
docker desktop stop
podman machine stop
wsl --shutdown
wsl -l -v   # every distro must be Stopped
```

Then, in an **administrator** terminal:

```powershell
wsl --shutdown
Get-Process wsl, wslhost, wslrelay -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Service WSLService -Force
wsl --update --pre-release
wsl --version
```

If the service still refuses to stop: restart Windows and run the update **before** Docker Desktop restarts automatically.

## Rolling back

To leave the pre-release, reinstall a stable version: `wsl --update` (without `--pre-release`) or the stable MSI package from the [WSL GitHub releases](https://github.com/microsoft/WSL/releases). *To verify: the exact rollback behavior from 2.9.x.*

## Key takeaways

- `wslc` needs WSL 2.9.3 or later, which for now only exists as a pre-release: `wsl --update --pre-release`.
- The update stops every WSL distribution, including those of Docker Desktop and Podman.
- A terminal or an IDE opened before the update keeps the old `PATH` and doesn't find `wslc`.
- An update can fail without an error: check `wsl --version` again, and look for error 1921 or status 1603 in the `MsiInstaller` events.
- If the WSL service won't stop, stop Docker Desktop, Podman and the WSL processes, then update from an administrator terminal.

## Exercises

1. How can you tell whether a WSL update really succeeded, even if the command shows no error?

<details>
<summary>Solution</summary>

Run `wsl --version` again and compare the version. If in doubt, read the `MsiInstaller` events: event **1033** gives the final status (`0` = success, `1603` = failure), event **11707** reports "Installation completed successfully" and event **11708** "Installation failed". After my successful attempt:

```text
TimeCreated               Id Message
2026-09-13 12:25:19 PM  1033 Windows Installer installed the product. Product Name: Windows Subsystem for Linux. Product Version: 2.9.11.0. ...
2026-09-13 12:25:19 PM 11707 Product: Windows Subsystem for Linux -- Installation completed successfully.
```

</details>

2. Why do you need to stop Docker Desktop before updating WSL?

<details>
<summary>Solution</summary>

Docker Desktop runs its own WSL distro, which keeps the `WSLService` service active. The installer can't replace the files of a service it can't stop.

</details>

3. You open a new tab in Windows Terminal after the update. `wsl --version` shows 2.9.11, but `Get-Command wslc` answers that the term `wslc` is not recognized. Explain, then give a fix that works in that tab and a fix that lasts.

<details>
<summary>Solution</summary>

`wsl.exe` was already on the `PATH` before the update, `wslc.exe` wasn't. The Windows Terminal process started before the update, with the old `PATH`, and each new tab inherits a copy of it. In that tab, reload the `PATH` from the machine and user values with the `$env:Path = …` line above, or call the full path, `& "C:\Program Files\WSL\wslc.exe" --version`. The lasting fix is to close **every** Windows Terminal window, so that no `WindowsTerminal.exe` process is left, and start it again. In `cmd.exe`, the equivalent check is `where wslc`.

</details>

## Sources

- [WSL container — Microsoft Learn](https://learn.microsoft.com/windows/wsl/wsl-container)
- [WSL release notes — GitHub](https://github.com/microsoft/WSL/releases)
- [Event logging — Windows Installer](https://learn.microsoft.com/windows/win32/msi/event-logging)
