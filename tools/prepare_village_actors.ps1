param(
    [string]$People = (Join-Path $PSScriptRoot 'art_source/actors_v4/people.png'),
    [string]$Monsters = (Join-Path $PSScriptRoot 'art_source/actors_v4/monsters.png'),
    [string]$Pickups = (Join-Path $PSScriptRoot 'art_source/actors_v4/pickups.png')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$actorAtlasOutput = Join-Path $PSScriptRoot '../assets/art/actors_v4'
New-Item -ItemType Directory -Force -Path $actorAtlasOutput | Out-Null
# Offline nearest packing only. Original alpha is copied, never color-keyed.
# All frames of a family share one crop/scale and source-cell registration.
function Pack-Sheet($sourcePath,$name,$rows,$cellW,$cellH,$fitW,$fitH,$groups) {
    $source = [System.Drawing.Bitmap]::new($sourcePath)
    $atlas = [System.Drawing.Bitmap]::new(4*$cellW,$rows*$cellH)
    $graphics = [System.Drawing.Graphics]::FromImage($atlas)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $tiles = @()
    for ($row=0;$row -lt $rows;$row++) {
        for ($col=0;$col -lt 4;$col++) {
            $sx=[int][Math]::Round($col*$source.Width/4.0)
            $sy=[int][Math]::Round($row*$source.Height/$rows)
            $ex=[int][Math]::Round(($col+1)*$source.Width/4.0)
            $ey=[int][Math]::Round(($row+1)*$source.Height/$rows)
            $bounds=@(99999,99999,-1,-1)
            for($y=$sy;$y -lt $ey;$y++) { for($x=$sx;$x -lt $ex;$x++) {
                if($source.GetPixel($x,$y).A -gt 32) {
                    $bounds[0]=[Math]::Min($bounds[0],$x-$sx); $bounds[1]=[Math]::Min($bounds[1],$y-$sy)
                    $bounds[2]=[Math]::Max($bounds[2],$x-$sx); $bounds[3]=[Math]::Max($bounds[3],$y-$sy)
                }
            } }
            if ($bounds[2] -lt 0) { throw "Empty tile $name $row $col" }
            $tiles += ,@($sx,$sy,$bounds,$row,$col)
        }
    }
    foreach ($group in $groups) {
        $selected=@($tiles | Where-Object { $group -contains $_[3] })
        $left=99999; $top=99999; $right=-1; $bottom=-1
        foreach($tile in $selected) {
            $left=[Math]::Min($left,$tile[2][0]); $top=[Math]::Min($top,$tile[2][1])
            $right=[Math]::Max($right,$tile[2][2]); $bottom=[Math]::Max($bottom,$tile[2][3])
        }
        $width=$right-$left+1; $height=$bottom-$top+1
        $ratio=[Math]::Min($fitW/$width,$fitH/$height)
        $dw=[int][Math]::Round($width*$ratio); $dh=[int][Math]::Round($height*$ratio)
        foreach($tile in $selected) {
            $destination=[System.Drawing.Rectangle]::new([int]($tile[4]*$cellW+($cellW-$dw)/2),[int]($tile[3]*$cellH+$cellH-2-$dh),$dw,$dh)
            $graphics.DrawImage($source,$destination,[int]($tile[0]+$left),[int]($tile[1]+$top),$width,$height,[System.Drawing.GraphicsUnit]::Pixel)
        }
    }
    $atlas.Save((Join-Path $actorAtlasOutput $name),[System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose(); $atlas.Dispose(); $source.Dispose()
}
Pack-Sheet $People 'people.png' 6 32 40 28 32 @(@(0),@(1),@(2),@(3),@(4),@(5))
Pack-Sheet $Monsters 'monsters.png' 3 32 32 28 28 @(@(0),@(1),@(2))
# Props share a square crop: opening chest lids must never resize the chest base.
Pack-Sheet $Pickups 'pickups.png' 2 32 32 26 26 @(,@(0,1))
