param(
    [string]$Buildings = (Join-Path $PSScriptRoot 'art_source/hub_v3/village_source.png'),
    [string]$Props = (Join-Path $PSScriptRoot 'art_source/hub_v3/props_source.png')
)
$ErrorActionPreference = 'Stop'
# Offline packing only: retain original alpha and sample nearest, never color-key.
Add-Type -AssemblyName System.Drawing
$outDir = Join-Path $PSScriptRoot '../assets/art/hub_v3'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
function Pack-Atlas($sourcePath, $name, $width, $height, $items) {
    $source = [System.Drawing.Bitmap]::new($sourcePath)
    $atlas = [System.Drawing.Bitmap]::new($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($atlas)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    foreach ($item in $items) {
        $minX = $source.Width; $minY = $source.Height; $maxX = -1; $maxY = -1
        for ($y=$item[1]; $y -lt [Math]::Min($item[3],$source.Height); $y++) {
            for ($x=$item[0]; $x -lt [Math]::Min($item[2],$source.Width); $x++) {
                if ($source.GetPixel($x,$y).A -gt 32) {
                    $minX=[Math]::Min($minX,$x); $minY=[Math]::Min($minY,$y)
                    $maxX=[Math]::Max($maxX,$x); $maxY=[Math]::Max($maxY,$y)
                }
            }
        }
        $cropW=$maxX-$minX+1; $cropH=$maxY-$minY+1
        $ratio=[Math]::Min($item[6]/$cropW,$item[7]/$cropH)
        $drawW=[int][Math]::Round($cropW*$ratio); $drawH=[int][Math]::Round($cropH*$ratio)
        $target=[System.Drawing.Rectangle]::new([int]($item[4]+($item[6]-$drawW)/2),[int]($item[5]+$item[7]-$drawH),$drawW,$drawH)
        $graphics.DrawImage($source,$target,$minX,$minY,$cropW,$cropH,[System.Drawing.GraphicsUnit]::Pixel)
    }
    $atlas.Save((Join-Path $outDir $name),[System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose(); $atlas.Dispose(); $source.Dispose()
}
Pack-Atlas $Buildings 'village.png' 320 176 @(
    @(0,0,600,540,0,0,96,96),
    @(600,0,1150,540,104,0,96,80),
    @(1150,0,1672,540,208,0,80,72),
    @(0,540,600,941,0,104,56,64),
    @(600,540,1150,941,64,104,56,64),
    @(1150,540,1672,941,128,104,28,24)
)
Pack-Atlas $Props 'props.png' 128 128 @(
    @(0,0,430,495,0,0,32,24),
    @(430,0,840,495,32,0,32,48),
    @(840,0,1250,495,67,8,18,24),
    @(1250,0,1672,495,98,4,24,24),
    @(0,495,430,941,4,76,24,28),
    @(430,495,840,941,36,78,24,42),
    @(840,495,1250,941,64,64,32,24),
    @(1250,495,1672,941,96,64,28,20)
)
