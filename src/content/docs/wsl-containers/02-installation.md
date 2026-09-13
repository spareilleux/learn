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
All WSL distributions stop during the update — including those of Docker Desktop and Podman. Save whatever is running in your containers first.
:::

## Verifying

```powershell
wsl --version        # should show 2.9.3 or later
wslc version         # confirms the CLI is available
wslc run --rm hello-world
```

The last test downloads the `hello-world` image if needed and prints a welcome message.

:::tip
If `wslc` can't be found right after the update, open a **new** terminal: the old one doesn't have the updated `PATH`.
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

**Fix** — in an **administrator** terminal:

```powershell
Get-Process "Docker Desktop","com.docker.backend" -ErrorAction SilentlyContinue | Stop-Process -Force
podman machine stop
wsl --shutdown
Stop-Service WSLService -Force
wsl --update --pre-release
wsl --version
```

If the service still refuses to stop: restart Windows and run the update **before** Docker Desktop restarts automatically.

## Rolling back

To leave the pre-release, reinstall a stable version: `wsl --update` (without `--pre-release`) or the stable MSI package from the [WSL GitHub releases](https://github.com/microsoft/WSL/releases). *To verify: the exact rollback behavior from 2.9.x.*

## Exercises

1. How can you tell whether a WSL update really succeeded, even if the command shows no error?

<details>
<summary>Solution</summary>

Run `wsl --version` again and compare the version. If in doubt, read the `MsiInstaller` events: event **1033** gives the final status (`0` = success, `1603` = failure) and event **11708** reports "Installation failed".

</details>

2. Why do you need to stop Docker Desktop before updating WSL?

<details>
<summary>Solution</summary>

Docker Desktop runs its own WSL distro, which keeps the `WSLService` service active. The installer can't replace the files of a service it can't stop.

</details>
