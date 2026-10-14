# The Observatory's Windows export as an .msi (Observatory.wxs), then the checks that need no install:
# WiX's ICE validation, and an administrative image (msiexec /a only unpacks) whose files must equal the
# export's.
#   pwsh -File build-msi.ps1 -ExportDir <dir with Observatory.exe, .pck and the notices> -Version 43.0.0 -Out <dir>
param([Parameter(Mandatory)][string]$ExportDir, [Parameter(Mandatory)][string]$Version,
  [Parameter(Mandatory)][string]$Out, [string]$ToolDir = "$env:RUNNER_TEMP\wix5")
$ErrorActionPreference = 'Stop'
if (-not $env:RUNNER_TEMP -and $ToolDir -eq '\wix5') { $ToolDir = 'C:\tmp\tools\wix5' }
$Here = $PSScriptRoot
$Wix = Join-Path $ToolDir 'wix.exe'
if (-not (Test-Path $Wix)) {
  # WiX 5 is the last release under MS-RL alone: from WiX 6, its Open Source Maintenance Fee applies.
  dotnet tool install wix --version 5.0.2 --tool-path $ToolDir
  if ($LASTEXITCODE -ne 0) { throw "dotnet tool install exit $LASTEXITCODE" }
}
$env:DOTNET_ROLL_FORWARD = 'Major'  # wix 5 targets .NET 6
"wix " + (& $Wix --version)

$files = 'Observatory.exe', 'Observatory.pck', 'README.txt', 'LICENSES.txt', 'GODOT_COPYRIGHT.txt'
foreach ($f in $files) { if (-not (Test-Path (Join-Path $ExportDir $f))) { throw "$ExportDir has no $f" } }
$extra = @(Get-ChildItem $ExportDir -File | Where-Object { $files -notcontains $_.Name })
if ($extra.Count) { throw "unexpected files in ${ExportDir}: $($extra.Name -join ', ')" }

New-Item -ItemType Directory -Force $Out | Out-Null
$Msi = Join-Path $Out "Observatory-$Version-windows-x64.msi"
& $Wix build (Join-Path $Here 'Observatory.wxs') -arch x64 -d "ExportDir=$((Resolve-Path $ExportDir).Path)" -d "Version=$Version" -d "Icon=$(Join-Path $Here '..\icons\observatory.ico')" -o $Msi
if ($LASTEXITCODE -ne 0) { throw "wix build exit $LASTEXITCODE" }
Remove-Item -LiteralPath ($Msi -replace '\.msi$', '.wixpdb') -ErrorAction SilentlyContinue
'{0:N0}  {1}' -f (Get-Item $Msi).Length, (Split-Path $Msi -Leaf)

# ICE40 (REINSTALLMODE is set on purpose) and ICE91 (files in a per-user folder, the point) are warnings.
& $Wix msi validate $Msi
if ($LASTEXITCODE -ne 0) { throw "ICE validation exit $LASTEXITCODE" }

$Admin = Join-Path $Out "admin-$Version"
if (Test-Path $Admin) { throw "$Admin exists" }
$p = Start-Process msiexec.exe -ArgumentList @('/a', "`"$((Resolve-Path $Msi).Path)`"", '/qn', "TARGETDIR=`"$Admin`"", '/l*v', "`"$Out\admin-$Version.log`"") -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "msiexec /a exit $($p.ExitCode)" }
$bad = 0
foreach ($f in $files) {
  $got = @(Get-ChildItem $Admin -Recurse -File -Filter $f)
  $same = $got.Count -eq 1 -and (Get-FileHash $got[0].FullName).Hash -eq (Get-FileHash (Join-Path $ExportDir $f)).Hash
  if (-not $same) { $bad++ }
  '{0,-22} unpacked={1} same={2}' -f $f, $got.Count, $same
}
if ($bad) { throw "$bad files differ in the administrative image" }
Remove-Item -LiteralPath $Admin -Recurse -Force
"SHA-256 " + (Get-FileHash $Msi -Algorithm SHA256).Hash.ToLower()
