# Observatory RTX as an .msi (Observatory-RTX.wxs): the release's package folder, as it is, in a Windows
# Installer package for the current user, then three checks that need no install: WiX's ICE validation,
# an administrative image (msiexec /a only unpacks), and the unpacked files against the package's.
#   pwsh -File build-msi.ps1 -Tree C:/tmp/observatory-rtx-build-4 -Version 0.1.0 [-Out <dir>]
param([Parameter(Mandatory)][string]$Tree, [Parameter(Mandatory)][string]$Version, [string]$Out = '')
$ErrorActionPreference = 'Stop'
$Here = $PSScriptRoot
$Wix = 'C:/tmp/tools/wix5/wix.exe'
$Pkg = "$Tree/package/Observatory-RTX"
if (-not $Out) { $Out = "$Tree/package" }
$Name = "Observatory-RTX-$Version-win64"
$Msi = "$Out/$Name.msi"
if (Test-Path $Msi) { throw "$Msi exists" }
New-Item -ItemType Directory -Force $Out | Out-Null

if (-not (Test-Path $Wix)) {
  # WiX 5 is the last release under MS-RL alone: from WiX 6, its Open Source Maintenance Fee applies.
  dotnet tool install wix --version 5.0.2 --tool-path (Split-Path $Wix)
}
$env:DOTNET_ROLL_FORWARD = 'Major'  # wix 5 targets .NET 6; this machine has 10 and 11
"wix " + (& $Wix --version)

# Nothing of NVIDIA's goes in: the package folder holds no DLL (build-rtx.ps1 checked it; again here).
$dll = @(Get-ChildItem $Pkg -Recurse -File | Where-Object { $_.Extension -eq '.dll' -or $_.Name -match '^(sl\.|nvngx|NvLowLatency)' })
if ($dll.Count) { $dll.Name; throw 'the package must hold no DLL' }

$Ico = "$Out/Observatory.ico"
if (-not (Test-Path $Ico)) {
  py -3.14 "$Here/make_ico.py" 'C:/tmp/observatory-web-build-pub36/out/icon-512.png' $Ico
  if ($LASTEXITCODE -ne 0) { throw "make_ico.py exit $LASTEXITCODE" }
}

& $Wix build "$Here/Observatory-RTX.wxs" -arch x64 -d "PkgDir=$Pkg" -d "Version=$Version" -d "Icon=$Ico" -o $Msi
if ($LASTEXITCODE -ne 0) { throw "wix build exit $LASTEXITCODE" }
Remove-Item -LiteralPath ($Msi -replace '\.msi$', '.wixpdb') -ErrorAction SilentlyContinue
'{0:N0}  {1}' -f (Get-Item $Msi).Length, (Split-Path $Msi -Leaf)
"SHA-256 " + (Get-FileHash $Msi -Algorithm SHA256).Hash.ToLower()

& $Wix msi validate $Msi
"ICE validation exit $LASTEXITCODE"

# An administrative image: the files as the package would install them, unpacked, nothing registered.
$Admin = "$Out/admin-$Version"
if (Test-Path $Admin) { throw "$Admin exists" }
$p = Start-Process msiexec.exe -ArgumentList @('/a', "`"$((Resolve-Path $Msi).Path)`"", '/qn', "TARGETDIR=`"$($Admin -replace '/', '\')`"", '/l*v', "`"$Out\admin-$Version.log`"") -Wait -PassThru
"msiexec /a exit $($p.ExitCode)"
$bad = 0
foreach ($f in Get-ChildItem $Pkg -File) {
  $got = @(Get-ChildItem $Admin -Recurse -File -Filter $f.Name)
  $same = $got.Count -eq 1 -and (Get-FileHash $got[0].FullName).Hash -eq (Get-FileHash $f.FullName).Hash
  if (-not $same) { $bad++ }
  '{0,-22} unpacked={1} same={2}  {3}' -f $f.Name, $got.Count, $same, ($(if ($got.Count) { $got[0].FullName.Substring($Admin.Length) } else { '' }))
}
$extra = @(Get-ChildItem $Admin -Recurse -File | Where-Object { $_.Extension -ne '.msi' -and -not (Test-Path "$Pkg/$($_.Name)") })
"files differing or missing: $bad; extra files: $($extra.Count)"
if ($bad -or $extra.Count) { throw 'the administrative image does not match the package' }
