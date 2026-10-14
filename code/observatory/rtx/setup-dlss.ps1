# Observatory RTX: fetches NVIDIA's own runtime for DLSS, once.
#
# Nothing of NVIDIA's is in this package. This script downloads the Streamline SDK 2.10.0 as NVIDIA
# publishes it on GitHub, checks the archive (SHA-256), takes the 12 run-time DLLs out of it (DLSS, DLSS Ray
# Reconstruction, DLSS Frame Generation, Reflex, NIS and Streamline's loader), checks that each one is signed
# by NVIDIA Corporation, and puts them beside Observatory-RTX.exe with NVIDIA's licence texts. Those files are
# NVIDIA's, under NVIDIA's licences: by downloading them you accept those, not ours.
#
# Run by Observatory-RTX.cmd when the DLLs are not there, and by Setup-DLSS.cmd. Works with the Windows
# PowerShell 5.1 every Windows 10 and 11 has.  -Yes: no question.  -Remove: takes the DLLs away again.
param([switch]$Yes, [switch]$Remove)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -le 5) {
  # Windows PowerShell started from a PowerShell 7 window inherits its module path and loads none of its
  # own modules (Get-AuthenticodeSignature is in one): its own path, for this process only.
  $env:PSModulePath = "$env:ProgramFiles\WindowsPowerShell\Modules;$PSHOME\Modules"
}
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$url = 'https://github.com/NVIDIA-RTX/Streamline/releases/download/v2.10.0/streamline-sdk-v2.10.0.zip'
$sha = 'b0cc810c86b0335d4fd76a02d35fff53e528d2fb66c29860565130f76c9383b0'
$dlls = 'sl.interposer', 'sl.common', 'sl.dlss', 'sl.dlss_g', 'sl.dlss_d', 'sl.reflex', 'sl.pcl', 'sl.nis',
  'nvngx_dlss', 'nvngx_dlssg', 'nvngx_dlssd', 'NvLowLatencyVk'
$texts = 'nvngx_dlss.license.txt', 'reflex.license.txt', 'nis.license.txt'
$notices = Join-Path $here 'nvidia-licenses'

function Test-Nvidia([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return $false }
  $sig = Get-AuthenticodeSignature -LiteralPath $path
  return ($sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -match 'CN=NVIDIA Corporation')
}

if ($Remove) {
  foreach ($d in $dlls) { $p = Join-Path $here "$d.dll"; if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force } }
  if (Test-Path -LiteralPath $notices) { Remove-Item -LiteralPath $notices -Recurse -Force }
  Write-Host 'NVIDIA DLLs removed.'
  exit 0
}

$missing = @($dlls | Where-Object { -not (Test-Nvidia (Join-Path $here "$_.dll")) })
if ($missing.Count -eq 0) { exit 0 }

Write-Host ''
Write-Host 'Observatory RTX - NVIDIA DLSS'
Write-Host '-----------------------------'
Write-Host 'EN  DLSS, Ray Reconstruction and Frame Generation need NVIDIA''s own files, which are not in this'
Write-Host '    package. They will be downloaded from NVIDIA (github.com/NVIDIA-RTX/Streamline, 203 MB, once).'
Write-Host 'FR  DLSS, Ray Reconstruction et Frame Generation ont besoin des fichiers de NVIDIA, absents de ce'
Write-Host '    paquet. Ils seront telecharges chez NVIDIA (github.com/NVIDIA-RTX/Streamline, 203 Mo, une fois).'
Write-Host 'ES  DLSS, Ray Reconstruction y Frame Generation necesitan los archivos de NVIDIA, que no estan en'
Write-Host '    este paquete. Se descargaran de NVIDIA (github.com/NVIDIA-RTX/Streamline, 203 MB, una vez).'
Write-Host ''
Write-Host 'They are NVIDIA''s software, under NVIDIA''s licences (kept in the nvidia-licenses folder):'
Write-Host '  https://github.com/NVIDIA-RTX/Streamline/blob/v2.10.0/license.txt'
Write-Host '  NVIDIA RTX SDKs License (nvngx_dlss.license.txt)'
Write-Host ''
if (-not $Yes) {
  $answer = Read-Host 'Enter: download / telecharger / descargar     N: start without DLSS / sans DLSS / sin DLSS'
  if ($answer -match '^\s*[nN]') {
    # Remembered, so that the question is not asked at every start: Setup-DLSS.cmd asks it again.
    Set-Content -LiteralPath (Join-Path $here 'dlss-declined.txt') -Encoding ASCII -Value @(
      'NVIDIA DLSS was declined: the Observatory starts without it, and without path tracing.',
      'Run Setup-DLSS.cmd to install it after all.')
    Write-Host 'Starting without DLSS. Setup-DLSS.cmd installs it later.'
    exit 2
  }
}

$tmp = Join-Path $env:TEMP ("observatory-rtx-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$zip = Join-Path $tmp 'streamline-sdk-v2.10.0.zip'
try {
  $curl = Join-Path $env:SystemRoot 'System32\curl.exe'
  if (Test-Path -LiteralPath $curl) {
    & $curl -L --fail --retry 3 -# -o $zip $url
    if ($LASTEXITCODE -ne 0) { throw "download failed (curl exit $LASTEXITCODE)" }
  } else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
  }
  $stream = [IO.File]::OpenRead($zip)
  try { $got = -join ([Security.Cryptography.SHA256]::Create().ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) }
  finally { $stream.Dispose() }
  if ($got -ne $sha) { throw "the archive is not the one expected (SHA-256 $got)" }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [IO.Compression.ZipFile]::OpenRead($zip)
  try {
    New-Item -ItemType Directory -Force -Path $notices | Out-Null
    foreach ($d in $dlls) {
      $entry = $archive.GetEntry("bin/x64/$d.dll")
      if ($null -eq $entry) { throw "$d.dll is not in the archive" }
      $staged = Join-Path $tmp "$d.dll"
      [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $staged, $true)
      if (-not (Test-Nvidia $staged)) { throw "$d.dll is not signed by NVIDIA Corporation" }
    }
    foreach ($t in $texts) {
      $entry = $archive.GetEntry("bin/x64/$t")
      if ($null -ne $entry) { [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $notices $t), $true) }
    }
    $entry = $archive.GetEntry('license.txt')
    if ($null -ne $entry) { [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $notices 'streamline.license.txt'), $true) }
    $entry = $archive.GetEntry('3rd-party-licenses.md')
    if ($null -ne $entry) { [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $notices 'streamline.3rd-party-licenses.md'), $true) }
  } finally {
    $archive.Dispose()
  }
  # Every DLL is checked before any is put in place: either all twelve, or none.
  foreach ($d in $dlls) { Copy-Item -LiteralPath (Join-Path $tmp "$d.dll") -Destination (Join-Path $here "$d.dll") -Force }
  Write-Host ''
  Write-Host 'DLSS is installed. / DLSS est installe. / DLSS esta instalado.'
  exit 0
} catch {
  Write-Host ''
  Write-Host ("DLSS was not installed: " + $_.Exception.Message)
  Write-Host 'The Observatory starts without it. Start Observatory-RTX.cmd again to retry.'
  Start-Sleep -Seconds 4
  exit 1
} finally {
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
