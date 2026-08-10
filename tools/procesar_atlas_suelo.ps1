param(
    [Parameter(Mandatory = $true)] [string] $Entrada,
    [Parameter(Mandatory = $true)] [string] $Salida,
    [int] $Celdas = 2,
    [int] $AnchoCelda = 128,
    [int] $AltoCelda = 64
)

Add-Type -AssemblyName System.Drawing

function Es-Croma([System.Drawing.Color] $c) {
    if ($c.A -eq 0) { return $true }
    $rb = [Math]::Abs([int]$c.R - [int]$c.B) -lt 85
    return $c.R -gt ($c.G + 20) -and $c.B -gt ($c.G + 20) -and $rb
}

function Limites-Contenido([System.Drawing.Bitmap] $bmp,
        [System.Drawing.Rectangle] $zona) {
    $minX = $zona.Right
    $minY = $zona.Bottom
    $maxX = $zona.Left
    $maxY = $zona.Top
    for ($y = $zona.Top; $y -lt $zona.Bottom; $y += 2) {
        for ($x = $zona.Left; $x -lt $zona.Right; $x += 2) {
            if (-not (Es-Croma $bmp.GetPixel($x, $y))) {
                $minX = [Math]::Min($minX, $x)
                $minY = [Math]::Min($minY, $y)
                $maxX = [Math]::Max($maxX, $x)
                $maxY = [Math]::Max($maxY, $y)
            }
        }
    }
    if ($maxX -lt $minX -or $maxY -lt $minY) {
        throw "No se encontró contenido en $zona"
    }
    return [System.Drawing.Rectangle]::new(
        [Math]::Max($zona.Left, $minX - 2),
        [Math]::Max($zona.Top, $minY - 2),
        [Math]::Min($zona.Right - 1, $maxX + 2) - [Math]::Max($zona.Left, $minX - 2) + 1,
        [Math]::Min($zona.Bottom - 1, $maxY + 2) - [Math]::Max($zona.Top, $minY - 2) + 1)
}

$src = [System.Drawing.Bitmap]::new($Entrada)
try {
    $lw = [int]($AnchoCelda / 2)
    $lh = [int]($AltoCelda / 2)
    $logical = [System.Drawing.Bitmap]::new($lw * $Celdas, $lh,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $g = [System.Drawing.Graphics]::FromImage($logical)
        $g.Clear([System.Drawing.Color]::Transparent)
        $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $franja = [int]($src.Width / $Celdas)
        for ($i = 0; $i -lt $Celdas; $i++) {
            $zona = [System.Drawing.Rectangle]::new($i * $franja, 0,
                $(if ($i -eq $Celdas - 1) { $src.Width - $i * $franja } else { $franja }),
                $src.Height)
            $recorte = Limites-Contenido $src $zona
            $destino = [System.Drawing.Rectangle]::new($i * $lw, 0, $lw, $lh)
            $g.DrawImage($src, $destino, $recorte, [System.Drawing.GraphicsUnit]::Pixel)
        }
        $g.Dispose()

        for ($y = 0; $y -lt $logical.Height; $y++) {
            for ($x = 0; $x -lt $logical.Width; $x++) {
                if (Es-Croma $logical.GetPixel($x, $y)) {
                    $logical.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                }
            }
        }

        $physical = [System.Drawing.Bitmap]::new($AnchoCelda * $Celdas, $AltoCelda,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $gp = [System.Drawing.Graphics]::FromImage($physical)
            $gp.Clear([System.Drawing.Color]::Transparent)
            $gp.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $gp.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $gp.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $gp.DrawImage($logical, 0, 0, $physical.Width, $physical.Height)
            $gp.Dispose()
            $physical.Save($Salida, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $physical.Dispose()
        }
    } finally {
        $logical.Dispose()
    }
} finally {
    $src.Dispose()
}
