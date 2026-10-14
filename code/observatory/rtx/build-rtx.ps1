# The Observatory's native package for readers elsewhere (artpass/publish/rtx/NOTES.md): a zip with the
# scene, a release build of NVIDIA's Godot fork and no file of NVIDIA's DLSS (setup-dlss.ps1 fetches those
# from NVIDIA on the reader's machine).
#   pwsh -File build-rtx.ps1 -N 1 -Stage tree      assemble_rtx.py, the build stamp, the export preset
#   pwsh -File build-rtx.ps1 -N 1 -Stage import    the fork's editor imports the tree; check-only; selftest
#   pwsh -File build-rtx.ps1 -N 1 -Stage export    Observatory-RTX.exe and .pck from the release template
#   pwsh -File build-rtx.ps1 -N 1 -Stage package   the folder as a reader gets it, and its zip
# The fork's executables run on the build tree only, never on the Foundation copy.
param([int]$N = 1, [Parameter(Mandatory)][ValidateSet('tree', 'import', 'export', 'package')][string]$Stage,
  [string]$Version = '0.1.0', [int]$Scene = 42)
$ErrorActionPreference = 'Stop'
$Fdn = 'C:/tmp/observatory-foundation'
$Rtx = 'C:/tmp/observatory-foundation-rtx'
$Fork = 'C:/tmp/godot-nvidia-dlss'
$Tree = "C:/tmp/observatory-rtx-build-$N"
$Here = "$Fdn/artpass/publish/rtx"
$Ed = "$Fork/godot/bin/godot.windows.editor.x86_64.console.exe"
$Template = "$Fork/godot/bin/godot.windows.template_release.x86_64.exe"
$Bad = 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR: '

if ($Stage -eq 'tree') {
  if (git -C $Fdn status --porcelain -- scripts assets) { throw "$Fdn has uncommitted scripts or assets" }
  "Foundation copy at $(git -C $Fdn rev-parse --short HEAD)"
  py -3.14 "$Here/assemble_rtx.py" $Fdn $Rtx $Tree
  if ($LASTEXITCODE -ne 0) { throw "assemble_rtx.py exit $LASTEXITCODE" }
  py -3.14 "$Fdn/artpass/publish/stamp_build.py" $Tree $Scene
  Copy-Item "$Here/export_presets.cfg" "$Tree/export_presets.cfg"
  return
}

if ($Stage -eq 'import') {
  & $Ed --headless --path $Tree --import *> "$Tree/import-rtx.log"
  "import exit $LASTEXITCODE; error lines: " + @(Select-String -Path "$Tree/import-rtx.log" -Pattern $Bad).Count
  Select-String -Path "$Tree/import-rtx.log" -Pattern $Bad | Select-Object -First 12 | ForEach-Object { $_.Line.Substring(0, [Math]::Min(240, $_.Line.Length)) }
  foreach ($rel in 'rtx/rtx_play.gd', 'rtx/dlss_play.gd', 'rtx/pt_scene.gd', 'scripts/observatory.gd', 'scripts/palace_gardens.gd', 'scripts/fountain_show.gd') {
    & $Ed --headless --path $Tree --check-only --script "res://$rel" *> "$env:TEMP/check-rtx.log"
    "check-only {0} exit {1}" -f $rel, $LASTEXITCODE
    Select-String -Path "$env:TEMP/check-rtx.log" -Pattern $Bad | Select-Object -First 4 | ForEach-Object { '   ' + $_.Line.Substring(0, [Math]::Min(240, $_.Line.Length)) }
  }
  $line = & $Ed --headless --path $Tree --rendering-method forward_plus -- --selftest 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -match "^SELFTEST|$Bad" }
  'selftest:'; $line | ForEach-Object { $_.Substring(0, [Math]::Min(600, $_.Length)) }
  return
}

if ($Stage -eq 'export') {
  if (-not (Test-Path $Template)) { throw "no release template: $Template" }
  New-Item -ItemType Directory -Force "$Tree/out" | Out-Null
  Push-Location $Tree
  & $Ed --headless --path . --export-release 'Windows RTX' out/Observatory-RTX.exe *> export-rtx.log
  $code = $LASTEXITCODE
  Pop-Location
  "export exit $code; error lines: " + @(Select-String -Path "$Tree/export-rtx.log" -Pattern $Bad).Count
  Select-String -Path "$Tree/export-rtx.log" -Pattern $Bad | Select-Object -First 12 | ForEach-Object { $_.Line.Substring(0, [Math]::Min(240, $_.Line.Length)) }
  Get-ChildItem "$Tree/out" -File | ForEach-Object { '{0,14:N0}  {1}' -f $_.Length, $_.Name }
  "the exe is the template: " + ((Get-FileHash "$Tree/out/Observatory-RTX.exe").Hash -eq (Get-FileHash $Template).Hash)
  return
}

# package
$Name = "Observatory-RTX-$Version-win64"
$Pkg = "$Tree/package/Observatory-RTX"
if (Test-Path "$Tree/package") { throw "$Tree/package exists" }
New-Item -ItemType Directory -Force $Pkg | Out-Null
Copy-Item "$Tree/out/Observatory-RTX.exe", "$Tree/out/Observatory-RTX.pck" $Pkg
Copy-Item "$Here/setup-dlss.ps1" $Pkg
# Text a reader opens in Notepad, and cmd's own files: CRLF; the texts in UTF-8 with a byte-order mark.
foreach ($cmd in 'Observatory-RTX.cmd', 'Setup-DLSS.cmd') {  # not $n: that is -N, an integer
  $t = (Get-Content "$Here/$cmd" -Raw) -replace "`r`n", "`n" -replace "`n", "`r`n"
  [IO.File]::WriteAllText("$Pkg/$cmd", $t, [Text.Encoding]::ASCII)
}
$notices = py -3.14 "$Here/notices_rtx.py" $Fdn $Fork $Version $Scene
if ($LASTEXITCODE -ne 0) { throw "notices_rtx.py exit $LASTEXITCODE" }
foreach ($pair in @(@('README.txt', "$Here/README.txt"), @('LICENSES.txt', "$Here/out/LICENSES.txt"))) {
  $t = (Get-Content $pair[1] -Raw -Encoding UTF8) -replace "`r`n", "`n" -replace "`n", "`r`n"
  [IO.File]::WriteAllText("$Pkg/$($pair[0])", $t, [Text.UTF8Encoding]::new($true))
}
Copy-Item "$Fork/godot/COPYRIGHT.txt" "$Pkg/GODOT_COPYRIGHT.txt"
$notices
# Nothing of NVIDIA's: no DLL at all, and no file carrying its signature.
$dll = @(Get-ChildItem $Pkg -Recurse -File | Where-Object { $_.Extension -eq '.dll' -or $_.Name -match '^(sl\.|nvngx|NvLowLatency)' })
if ($dll.Count) { $dll.Name; throw 'the package must hold no DLL' }
foreach ($f in Get-ChildItem $Pkg -Recurse -File -Include '*.exe') {
  $sig = Get-AuthenticodeSignature -LiteralPath $f.FullName
  "{0}: signature {1}" -f $f.Name, $sig.Status
  if ($sig.SignerCertificate -and $sig.SignerCertificate.Subject -match 'NVIDIA') { throw "$($f.Name) is NVIDIA's" }
}
$zip = "$Tree/package/$Name.zip"
Compress-Archive -Path $Pkg -DestinationPath $zip -CompressionLevel Optimal
Get-ChildItem $Pkg -File | ForEach-Object { '{0,14:N0}  {1}' -f $_.Length, $_.Name }
'{0,14:N0}  {1}' -f (Get-Item $zip).Length, (Split-Path $zip -Leaf)
"SHA-256 " + (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
