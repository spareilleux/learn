# The .msi for the current user, as a reader gets it: install, the program started headless from where
# the package put it, an update to a second package numbered one patch up, then an uninstall; after each
# step, a check of the folder, the Start menu shortcut, the HKCU key and the uninstall entry.
#   pwsh -File test-msi.ps1 -Msi <msi> -MsiUp <same files, a higher version> -ExportDir <dir> -Work <dir>
# Nothing of the Observatory may be installed before it starts.
param([Parameter(Mandatory)][string]$Msi, [Parameter(Mandatory)][string]$MsiUp,
  [Parameter(Mandatory)][string]$ExportDir, [Parameter(Mandatory)][string]$Work)
$ErrorActionPreference = 'Stop'
$Dir = "$env:LOCALAPPDATA\Programs\Observatory"
$Lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Observatory.lnk"
$Reg = 'HKCU:\Software\spareilleux\Observatory'
New-Item -ItemType Directory -Force $Work | Out-Null
$Work = (Resolve-Path $Work).Path  # msiexec's logs: it does not run in this folder
$fail = [System.Collections.Generic.List[string]]::new()

function Get-Entries {
  $roots = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  @(foreach ($r in $roots) { if (Test-Path $r) { Get-ChildItem $r | ForEach-Object { $p = Get-ItemProperty $_.PSPath; if ($p.DisplayName -eq 'Observatory') { $p.DisplayVersion } } } })
}
function Check([string]$label, [bool]$installed, [string]$version) {
  $same = @(Get-ChildItem $ExportDir -File | Where-Object { (Test-Path "$Dir\$($_.Name)") -and (Get-FileHash "$Dir\$($_.Name)").Hash -eq (Get-FileHash $_.FullName).Hash }).Count
  $entries = @(Get-Entries)
  $state = [ordered]@{ folder = (Test-Path $Dir); same = $same; shortcut = (Test-Path $Lnk); registry = (Test-Path $Reg); entries = ($entries -join ',') }
  if ($state.shortcut) { $state.target = (New-Object -ComObject WScript.Shell).CreateShortcut($Lnk).TargetPath }
  "{0}: {1}" -f $label, ($state | ConvertTo-Json -Compress)
  if ($installed) {
    if ($same -ne @(Get-ChildItem $ExportDir -File).Count) { $fail.Add("${label}: files") }
    if (-not $state.shortcut -or $state.target -ne "$Dir\Observatory.exe") { $fail.Add("${label}: shortcut") }
    if (-not $state.registry) { $fail.Add("${label}: registry") }
    if ($entries.Count -ne 1 -or $entries[0] -ne $version) { $fail.Add("${label}: uninstall entries '$($entries -join ',')'") }
  } elseif ($state.folder -or $state.shortcut -or $state.registry -or $entries.Count) { $fail.Add("${label}: something is left") }
}
function Invoke-Msi([string]$verb, [string]$file, [string]$log) {
  (Start-Process msiexec.exe -ArgumentList @($verb, "`"$((Resolve-Path $file).Path)`"", '/qn', '/l*v', "`"$Work\$log`"") -Wait -PassThru).ExitCode
}
function Version-Of([string]$file) {
  $i = New-Object -ComObject WindowsInstaller.Installer
  $db = $i.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $null, $i, @((Resolve-Path $file).Path, 0))
  $v = $db.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $db, @("SELECT Value FROM Property WHERE Property='ProductVersion'"))
  # Execute returns null, and a function would output it beside the version.
  $null = $v.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $v, $null)
  $r = $v.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $v, $null)
  [string]$r.GetType().InvokeMember('StringData', 'GetProperty', $null, $r, 1)
}

Check 'before' $false ''
if ($fail.Count) { $fail; throw 'the Observatory is already installed' }
$v1 = Version-Of $Msi; $v2 = Version-Of $MsiUp
"versions: $v1 then $v2"
"elevated: " + ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$code = Invoke-Msi '/i' $Msi 'install.log'; "install exit $code"; if ($code -ne 0) { $fail.Add("install exit $code") }
Check 'installed' $true $v1

$out = "$Work\run.out.txt"; $err = "$Work\run.err.txt"
$p = Start-Process "$Dir\Observatory.exe" -ArgumentList '--headless', '--quit-after', '30' -WorkingDirectory $Dir -RedirectStandardOutput $out -RedirectStandardError $err -PassThru
if (-not $p.WaitForExit(300000)) { Stop-Process -Id $p.Id; $fail.Add('run: timeout') } elseif ($p.ExitCode -ne 0) { $fail.Add("run exit $($p.ExitCode)") }
"run exit $($p.ExitCode); first line: " + (Get-Content $out -TotalCount 1)
$errors = @(Get-Content $out, $err | Where-Object { $_ -match 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' })
"run error lines: $($errors.Count)"; $errors | Select-Object -First 8 | ForEach-Object { '   ' + $_ }
if ($errors.Count) { $fail.Add("run: $($errors.Count) error lines") }

$code = Invoke-Msi '/i' $MsiUp 'update.log'; "update exit $code"; if ($code -ne 0) { $fail.Add("update exit $code") }
Check 'updated' $true $v2

$code = Invoke-Msi '/x' $MsiUp 'uninstall.log'; "uninstall exit $code"; if ($code -ne 0) { $fail.Add("uninstall exit $code") }
Check 'uninstalled' $false ''

if ($fail.Count) { 'FAILED:'; $fail; exit 1 }
'all checks passed'
