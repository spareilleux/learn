# Looks of the hall compared in one run of the package (rtx_probe.gd's --rtx-sweep), and the table of what
# each measured: the line's figures, the capture's mean luma, the share of it nearly black; with -Motion,
# the edges of one place of the picture at rest and while the camera turns; with -Views, views of the place.
#   pwsh -File sweep-rtx.ps1 -Dir C:/tmp/observatory-rtx-test-4/Observatory-RTX -Name sweep1 -Variants 'f0,f1,f4,f1e2'
#   pwsh -File sweep-rtx.ps1 -Dir ... -Name views1 -Views all           no sweep: the views as the player steers
# -Small <folder> also writes each whole capture there as a 1280 px JPEG, to look at.
param([Parameter(Mandatory)][string]$Dir, [Parameter(Mandatory)][string]$Name, [string]$Variants = '',
  [switch]$Motion, [string]$Views = '', [string]$Small = '', [string[]]$More = @(), [int]$TimeoutS = 240)
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Out = "$Here/logs/$Name"
$a = @()
if ($Variants) { $a += "--rtx-sweep=$Variants" }
if ($Motion) { $a += '--rtx-motion' }
if ($Views -eq 'all') { $a += '--rtx-views' } elseif ($Views) { $a += "--rtx-views=$Views" }
& "$Here/test-rtx.ps1" -Dir $Dir -Name $Name -More ($a + $More) -TimeoutS $TimeoutS |
  Where-Object { $_ -match '^(exit|TIMEOUT|folder|error and warning|\s+\d+ x |RTXPLAY)' } | ForEach-Object { "$_".Substring(0, [Math]::Min(220, "$_".Length)) }
if (-not (Test-Path "$Out/report.json")) { throw 'no report.json' }
$r = Get-Content "$Out/report.json" -Raw | ConvertFrom-Json
"window $($r.window); fill $($r.fill), exposure $($r.exposure), bounces $($r.bounces); sweep base $($r.sweep_base | ConvertTo-Json -Compress)"
function Row($key, $label) {
  $s = $r.$key; $p = $r."${key}_png"
  if ($null -eq $s) { return ('{0,-16} missing' -f $label) }
  $line = ("$($s.line)" -split "`n")[0] -replace 'Path tracing \+ Ray Reconstruction', 'PT+RR' -replace ' rendered', '' -replace '\s+·\s+', ' · '
  $e = ''
  if ($p.rest) { $e = '  rest: differs {0:N4}, over {1:P1}, sharp {2:N4}' -f $p.rest.diff, $p.rest.over, $p.rest.sharp }
  if ($p.move) { $e += '  turning: sharp {0:N4}' -f $p.move.sharp }
  '{0,-16} luma {1:N4} dark {2,4:P0} white {3,5:P1} | {4} | bounces {5}{6}' -f $label, $p.mean_luma, $p.dark_share, $p.bright_share, $line.Substring(0, [Math]::Min(90, $line.Length)), $s.env.bounces, $e
}
if ($Variants) { foreach ($v in $Variants -split ',') { Row "sweep_$v" $v } }
foreach ($prop in $r.PSObject.Properties.Name | Where-Object { $_ -like 'view_*' -and $_ -notlike '*_png' }) { Row $prop $prop }
if ($Small) {
  Add-Type -AssemblyName System.Drawing
  New-Item -ItemType Directory -Force $Small | Out-Null
  $codec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
  $q = New-Object Drawing.Imaging.EncoderParameters 1
  $q.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality, [long]82)
  foreach ($f in Get-ChildItem $Out -Filter '*.png' | Where-Object { $_.Name -notmatch '-(rest|move)\.png$' }) {
    $img = [Drawing.Image]::FromFile($f.FullName)
    $w = 1280; $h = [int]($img.Height * $w / $img.Width)
    $bmp = New-Object Drawing.Bitmap $w, $h
    $g = [Drawing.Graphics]::FromImage($bmp); $g.InterpolationMode = 'HighQualityBicubic'; $g.DrawImage($img, 0, 0, $w, $h); $g.Dispose(); $img.Dispose()
    $bmp.Save("$Small/$Name-$($f.BaseName).jpg", $codec, $q); $bmp.Dispose()
  }
  "small copies in $Small"
}
