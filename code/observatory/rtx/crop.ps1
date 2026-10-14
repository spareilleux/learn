# A part of a capture at its own pixels, to judge edges (aliasing) rather than the whole picture.
#   pwsh -File crop.ps1 -In logs/sweep2/sweep_f20.png -X 240 -Y 900 -W 960 -H 540 -Out <file.png>
# -Zoom 2 doubles each pixel (nearest neighbour), so a stair step stays a stair step.
param([Parameter(Mandatory)][string]$In, [int]$X = 0, [int]$Y = 0, [int]$W = 960, [int]$H = 540, [int]$Zoom = 1,
  [Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$img = [Drawing.Image]::FromFile((Resolve-Path $In))
$bmp = New-Object Drawing.Bitmap ($W * $Zoom), ($H * $Zoom)
$g = [Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = 'NearestNeighbor'; $g.PixelOffsetMode = 'Half'
$g.DrawImage($img, (New-Object Drawing.Rectangle 0, 0, ($W * $Zoom), ($H * $Zoom)), (New-Object Drawing.Rectangle $X, $Y, $W, $H), 'Pixel')
$g.Dispose(); $img.Dispose()
New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null
$bmp.Save($Out, [Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
"$Out  ($W x $H at $X,$Y of $In, zoom $Zoom)"
