# The .msi on this machine, for the current user, as a reader would get it: install, start the program
# headless, an update to a newer package over files setup-dlss.ps1 would have written (empty stand-ins with
# the same names: none of NVIDIA's files is used), then an uninstall, after each a check of what is there.
#   pwsh -File test-msi.ps1 -Msi <0.1.0.msi> -MsiUp <0.1.1 test .msi> -Pkg <package folder> -Work <dir>
# The install folder, the Start menu shortcut and the uninstall entry must be absent before it starts.
param([Parameter(Mandatory)][string]$Msi, [Parameter(Mandatory)][string]$MsiUp,
  [Parameter(Mandatory)][string]$Pkg, [Parameter(Mandatory)][string]$Work)
$ErrorActionPreference = 'Stop'
$Dir = "$env:LOCALAPPDATA\Programs\Observatory-RTX"
$Lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Observatory RTX.lnk"
$Reg = 'HKCU:\Software\Observatory'
$Dlls = 'sl.interposer', 'sl.common', 'sl.dlss', 'sl.dlss_g', 'sl.dlss_d', 'sl.reflex', 'sl.pcl', 'sl.nis',
  'nvngx_dlss', 'nvngx_dlssg', 'nvngx_dlssd', 'NvLowLatencyVk'
New-Item -ItemType Directory -Force $Work | Out-Null
$report = [ordered]@{}
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$report.elevated = $admin

function Get-Entries {
  $roots = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  @(foreach ($r in $roots) { if (Test-Path $r) { Get-ChildItem $r | ForEach-Object { $p = Get-ItemProperty $_.PSPath; if ($p.DisplayName -eq 'Observatory RTX') { '{0} {1} {2}' -f ($r -replace ':.*', ''), $p.DisplayVersion, $_.PSChildName } } } })
}
function Get-State([string]$label) {
  $s = [ordered]@{}
  $s.folder = Test-Path $Dir
  if ($s.folder) {
    $s.same = @(Get-ChildItem $Pkg -File | Where-Object { (Test-Path "$Dir\$($_.Name)") -and (Get-FileHash "$Dir\$($_.Name)").Hash -eq (Get-FileHash $_.FullName).Hash }).Count
    $s.files = @(Get-ChildItem $Dir -Recurse -File | ForEach-Object { $_.FullName.Substring($Dir.Length + 1) })
  }
  $s.shortcut = Test-Path $Lnk
  if ($s.shortcut) { $l = (New-Object -ComObject WScript.Shell).CreateShortcut($Lnk); $s.target = $l.TargetPath; $s.workdir = $l.WorkingDirectory; $s.icon = $l.IconLocation }
  $s.registry = Test-Path $Reg
  if ($s.registry) { $s.values = (Get-ItemProperty "$Reg\Observatory RTX" | Select-Object InstallFolder, NoticesFolder, StartMenuShortcut, Version | ConvertTo-Json -Compress) }
  $s.entries = Get-Entries
  $s.programs_dir = Test-Path "$env:LOCALAPPDATA\Programs"
  $report[$label] = $s
}
function Invoke-Msi([string]$verb, [string]$file, [string]$log) {
  $p = Start-Process msiexec.exe -ArgumentList @($verb, "`"$((Resolve-Path $file).Path)`"", '/qn', '/l*v', "`"$Work\$log`"") -Wait -PassThru
  $p.ExitCode
}

Get-State 'before'
if ($report.before.folder -or $report.before.shortcut -or $report.before.entries.Count) { $report | ConvertTo-Json -Depth 4; throw 'something of Observatory RTX is already installed' }

$report.install_exit = Invoke-Msi '/i' $Msi 'install.log'
Get-State 'installed'

# The program from where the package put it: headless, ten frames, then it quits.
$out = "$Work\run.out.txt"; $err = "$Work\run.err.txt"
$p = Start-Process "$Dir\Observatory-RTX.exe" -ArgumentList '--headless', '--quit-after', '10' -WorkingDirectory $Dir -RedirectStandardOutput $out -RedirectStandardError $err -PassThru
if (-not $p.WaitForExit(180000)) { Stop-Process -Id $p.Id; $report.run = 'timeout' } else { $report.run_exit = $p.ExitCode }
$report.run_head = @(Get-Content $out -TotalCount 4)
$report.run_errors = @(Get-Content $out, $err | Where-Object { $_ -match 'ERROR|error' } | Select-Object -First 8)

# What setup-dlss.ps1 leaves after the user's yes (stand-ins), and a README the user edited.
foreach ($d in $Dlls) { Set-Content -LiteralPath "$Dir\$d.dll" -Value '' }
New-Item -ItemType Directory -Force "$Dir\nvidia-licenses" | Out-Null
Set-Content -LiteralPath "$Dir\nvidia-licenses\streamline.license.txt" -Value 'stand-in'
Set-Content -LiteralPath "$Dir\dlss-declined.txt" -Value 'stand-in'
Add-Content -LiteralPath "$Dir\README.txt" -Value 'edited by the user'

$report.update_exit = Invoke-Msi '/i' $MsiUp 'update.log'
Get-State 'updated'
$report.updated_standins = @($Dlls | Where-Object { Test-Path "$Dir\$_.dll" }).Count

$report.uninstall_exit = Invoke-Msi '/x' $MsiUp 'uninstall.log'
Get-State 'uninstalled'
$report | ConvertTo-Json -Depth 4 | Tee-Object "$Work\report.json"
