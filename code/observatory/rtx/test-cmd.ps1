# The reader's own path, from the extracted zip (artpass/publish/rtx/NOTES.md): the .cmd files as a
# double-click runs them, with the answer to setup-dlss.ps1's question piped in.
#   pwsh -File test-cmd.ps1 -Dir C:/tmp/observatory-rtx-test-3/Observatory-RTX -Answer N -Name cmd-declined
#   pwsh -File test-cmd.ps1 -Dir ... -Setup -Name cmd-setup        Setup-DLSS.cmd, Enter
#   pwsh -File test-cmd.ps1 -Dir ... -Name cmd-dlss                Observatory-RTX.cmd, nothing to answer
# The program runs with no argument, so it does not quit by itself: after -Seconds it is stopped by its own
# PID, found by its path under -Dir. Only cmd's own exit is waited for: the program it starts inherits its
# output, and a pipeline on that output would wait for the program too (it did, 2026-10-13).
param([Parameter(Mandatory)][string]$Dir, [Parameter(Mandatory)][string]$Name, [string]$Answer = '', [switch]$Setup, [int]$Seconds = 25)
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Out = "$Here/logs/$Name"
if (Test-Path $Out) { throw "$Out exists" }
New-Item -ItemType Directory -Force $Out | Out-Null
$others = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(godot|Observatory-RTX)' })
if ($others.Count) { $others | ForEach-Object { "running: $($_.ProcessId) $($_.Name)" }; throw 'another Godot is running' }
$full = (Resolve-Path $Dir).Path
$file = if ($Setup) { 'Setup-DLSS.cmd' } else { 'Observatory-RTX.cmd' }
$echo = if ($Answer) { "echo $Answer" } else { 'echo.' }
$sw = [Diagnostics.Stopwatch]::StartNew()
$c = Start-Process -FilePath "$env:SystemRoot/System32/cmd.exe" -ArgumentList "/c `"$echo| `"$full\$file`"`"" -WorkingDirectory $full -PassThru `
  -RedirectStandardOutput "$Out/cmd.out.txt" -RedirectStandardError "$Out/cmd.err.txt" -WindowStyle Hidden
if (-not $c.WaitForExit(240000)) { "$file still running after 240 s (PID $($c.Id)): left for a look" } else { "$file exit $($c.ExitCode) after {0:N0} s" -f $sw.Elapsed.TotalSeconds }
Get-Content "$Out/cmd.out.txt" | Where-Object { $_.Trim() -and $_ -notmatch '^\s*#' } | Select-Object -First 30
"DLLs: " + @(Get-ChildItem $full -Filter '*.dll').Count + "; declined marker: " + (Test-Path "$full/dlss-declined.txt") + "; licences: " + @(Get-ChildItem "$full/nvidia-licenses" -ErrorAction SilentlyContinue).Count
if ($Setup) { return }
Start-Sleep -Seconds $Seconds
$mine = @(Get-CimInstance Win32_Process -Filter "Name = 'Observatory-RTX.exe'" | Where-Object { $_.ExecutablePath -and $_.ExecutablePath.StartsWith($full, [StringComparison]::OrdinalIgnoreCase) })
"programs started from the folder: $($mine.Count)"
foreach ($p in $mine) {
  "command line: $($p.CommandLine); working set {0:N0} MB after $Seconds s" -f ($p.WorkingSetSize / 1MB)
  $loaded = @((Get-Process -Id $p.ProcessId).Modules | Where-Object { $_.ModuleName -match '^(sl\.|nvngx|NvLowLatency)' } | ForEach-Object ModuleName)
  "NVIDIA modules loaded from the folder: $($loaded.Count) ($($loaded -join ', '))"
  Stop-Process -Id $p.ProcessId -Force; "stopped PID $($p.ProcessId)"
}
