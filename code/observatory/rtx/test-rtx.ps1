# The package run from a folder of its own, as a reader's (artpass/publish/rtx/NOTES.md): the program with
# no argument but the probe's (rtx_probe.gd, in the pack), which writes what the run shows and quits.
#   pwsh -File test-rtx.ps1 -Dir C:/tmp/observatory-rtx-test-3/Observatory-RTX -Name dlss
#   pwsh -File test-rtx.ps1 -Dir ... -Name ladder -Ladder      the step-down, forced: no card renders 1000 a second
#   pwsh -File test-rtx.ps1 -Dir ... -Name raster -More '--rtx-raster'
# One windowed run, not hidden, not minimised; stopped by its own PID if it outlives -TimeoutS. Refuses to
# start while another Godot runs (the author's demo, or a test).
param([Parameter(Mandatory)][string]$Dir, [Parameter(Mandatory)][string]$Name, [switch]$Ladder,
  [string[]]$More = @(), [int]$TimeoutS = 180)
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Out = "$Here/logs/$Name"
if (Test-Path $Out) { throw "$Out exists" }
New-Item -ItemType Directory -Force $Out | Out-Null
$others = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(godot|Observatory-RTX)' })
if ($others.Count) { $others | ForEach-Object { "running: $($_.ProcessId) $($_.Name)" }; throw 'another Godot is running' }
$a = @('--log-file', "$Out/godot.log", '--', "--rtx-probe=$Out")
if ($Ladder) { $a += '--rtx-ladder', '--rtx-slow-fps=1000' }
$a += $More
$dlls = @(Get-ChildItem $Dir -Filter '*.dll')
"folder: $Dir; DLLs beside the program: $($dlls.Count); arguments: $($a -join ' ')"
$t0 = Get-Date
$p = Start-Process -FilePath "$Dir/Observatory-RTX.exe" -ArgumentList $a -WorkingDirectory $Dir -PassThru
if (-not $p.WaitForExit($TimeoutS * 1000)) { Stop-Process -Id $p.Id -Force; "TIMEOUT after $TimeoutS s: stopped PID $($p.Id)" }
else { "exit $($p.ExitCode) after {0:N0} s" -f ((Get-Date) - $t0).TotalSeconds }
if (Test-Path "$Out/godot.log") {
  $log = Get-Content "$Out/godot.log"
  $log | Select-Object -First 3 | ForEach-Object { $_.Substring(0, [Math]::Min(200, $_.Length)) }
  $log | Where-Object { $_ -match '^(RTXPLAY|DLSSPLAY)' } | ForEach-Object { $_.Substring(0, [Math]::Min(600, $_.Length)) }
  $err = @($log | Where-Object { $_ -match 'SCRIPT ERROR|SHADER ERROR|Parse Error|^ERROR|^WARNING' })
  "error and warning lines: $($err.Count)"
  $err | Group-Object | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object { '{0,5} x {1}' -f $_.Count, $_.Name.Substring(0, [Math]::Min(230, $_.Name.Length)) }
} else { 'no log' }
if (Test-Path "$Out/report.json") { (Get-Content "$Out/report.json" -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 6) } else { 'no report.json' }
Get-ChildItem $Out -Filter '*.png' | ForEach-Object { '{0,12:N0}  {1}' -f $_.Length, $_.Name }
