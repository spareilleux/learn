# What the primary screen shows now, as a PNG: what a reader sees of the running program, its window's
# frame and any dialog of Windows included (the program's own captures cannot show those).
#   pwsh -File screenshot.ps1 -Out <file.png>
param([Parameter(Mandatory)][string]$Out)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
"{0} x {1} -> {2}" -f $b.Width, $b.Height, $Out
