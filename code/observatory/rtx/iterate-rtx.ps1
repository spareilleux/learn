# One turn of work on the player (artpass/publish/rtx/NOTES.md): rtx_play.gd and rtx_probe.gd into a build
# tree that is already imported, parse checks, export, the pack into a test folder that already has the
# program (and NVIDIA's files, if the turn needs them).
#   pwsh -File iterate-rtx.ps1 -N 3 -Dir C:/tmp/observatory-rtx-test-4/Observatory-RTX
# The package itself is always built from scratch (build-rtx.ps1, all four stages).
param([int]$N = 3, [Parameter(Mandatory)][string]$Dir)
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Tree = "C:/tmp/observatory-rtx-build-$N"
$Ed = 'C:/tmp/godot-nvidia-dlss/godot/bin/godot.windows.editor.x86_64.console.exe'
Copy-Item "$Here/rtx_play.gd", "$Here/rtx_probe.gd", "$Here/rtx_bridge.gd" "$Tree/rtx/" -Force
$bad = 0
foreach ($rel in 'rtx/rtx_play.gd', 'rtx/rtx_probe.gd', 'rtx/rtx_bridge.gd') {
  $o = & $Ed --headless --path $Tree --check-only --script "res://$rel" 2>&1 | ForEach-Object { "$_" }
  $code = $LASTEXITCODE
  "check-only $rel exit $code"
  if ($code -ne 0) { $bad++; $o | Where-Object { $_ -match 'ERROR|Parse|at:' } | Select-Object -First 8 | ForEach-Object { '   ' + $_.Substring(0, [Math]::Min(240, $_.Length)) } }
}
if ($bad) { throw 'a script does not parse: nothing exported' }
pwsh -NoProfile -File "$Here/build-rtx.ps1" -N $N -Stage export
Copy-Item "$Tree/out/Observatory-RTX.pck" $Dir -Force
"pack in $Dir"
