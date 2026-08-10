param(
    [Parameter(Mandatory = $true)] [string] $Entrada,
    [Parameter(Mandatory = $true)] [string] $SalidaNorte,
    [Parameter(Mandatory = $true)] [string] $SalidaOeste
)

Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::new($Entrada)

function Es-Croma([System.Drawing.Color] $c) {
    $rb = [Math]::Abs([int] $c.R - [int] $c.B) -lt 85
    return $c.R -gt ($c.G + 20) -and $c.B -gt ($c.G + 20) -and
        $rb -and ([int] $c.R + [int] $c.B) -gt 90
}

function Guardar-Muro($fuente, [string] $salida, [bool] $norte) {
    $logico = [System.Drawing.Bitmap]::new(64, 56,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $g = [System.Drawing.Graphics]::FromImage($logico)
        $g.Clear([System.Drawing.Color]::Transparent)
        $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        if ($norte) {
            $puntos = [System.Drawing.Point[]] @(
                [System.Drawing.Point]::new(32, 0),
                [System.Drawing.Point]::new(64, 16),
                [System.Drawing.Point]::new(32, 32))
        }
        else {
            $puntos = [System.Drawing.Point[]] @(
                [System.Drawing.Point]::new(0, 16),
                [System.Drawing.Point]::new(32, 0),
                [System.Drawing.Point]::new(0, 48))
        }
        $g.DrawImage($fuente, $puntos)
        $g.Dispose()

        for ($y = 0; $y -lt $logico.Height; $y++) {
            for ($x = 0; $x -lt $logico.Width; $x++) {
                if (Es-Croma $logico.GetPixel($x, $y)) {
                    $logico.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                }
            }
        }

        $fisico = [System.Drawing.Bitmap]::new(128, 112,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $gf = [System.Drawing.Graphics]::FromImage($fisico)
            $gf.Clear([System.Drawing.Color]::Transparent)
            $gf.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $gf.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $gf.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $gf.DrawImage($logico, 0, 0, 128, 112)
            $gf.Dispose()
            $fisico.Save($salida, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally { $fisico.Dispose() }
    }
    finally { $logico.Dispose() }
}

try {
    # Recorta la pieza frontal generada antes de proyectarla sobre cada plano.
    $minX=$src.Width; $minY=$src.Height; $maxX=0; $maxY=0
    for ($y=0; $y -lt $src.Height; $y += 4) {
        for ($x=0; $x -lt $src.Width; $x += 4) {
            if (-not (Es-Croma $src.GetPixel($x,$y))) {
                $minX=[Math]::Min($minX,$x); $maxX=[Math]::Max($maxX,$x)
                $minY=[Math]::Min($minY,$y); $maxY=[Math]::Max($maxY,$y)
            }
        }
    }
    $minX=[Math]::Max(0,$minX-4); $minY=[Math]::Max(0,$minY-4)
    $maxX=[Math]::Min($src.Width-1,$maxX+4); $maxY=[Math]::Min($src.Height-1,$maxY+4)
    $r=[System.Drawing.Rectangle]::new($minX,$minY,$maxX-$minX+1,$maxY-$minY+1)
    $recorte=$src.Clone($r,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        Guardar-Muro $recorte $SalidaNorte $true
        Guardar-Muro $recorte $SalidaOeste $false
    }
    finally { $recorte.Dispose() }
}
finally { $src.Dispose() }
