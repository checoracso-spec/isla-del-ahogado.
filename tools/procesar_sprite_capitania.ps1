param(
    [Parameter(Mandatory = $true)] [string] $Entrada,
    [Parameter(Mandatory = $true)] [string] $Salida,
    [ValidateSet("cuerpo", "tejado", "puerta")] [string] $Pieza
)

Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::new($Entrada)
try {
    $minX = $src.Width
    $minY = $src.Height
    $maxX = -1
    $maxY = -1

    for ($y = 0; $y -lt $src.Height; $y++) {
        for ($x = 0; $x -lt $src.Width; $x++) {
            $c = $src.GetPixel($x, $y)
            $esMagenta = $c.R -gt 205 -and $c.B -gt 185 -and $c.G -lt 90
            if (-not $esMagenta) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if ($maxX -lt $minX -or $maxY -lt $minY) {
        throw "No se encontró contenido fuera del fondo magenta."
    }

    $recorte = [System.Drawing.Rectangle]::new(
        $minX, $minY, $maxX - $minX + 1, $maxY - $minY + 1)

    # Se compone primero en la resolución lógica del proyecto. Godot recibe
    # después el resultado ampliado exactamente x2 con vecino más próximo.
    if ($Pieza -eq "puerta") {
        $anchoLogico = 64
        $altoLogico = 48
    }
    else {
        $anchoLogico = 192
        $altoLogico = 224
    }
    $logico = [System.Drawing.Bitmap]::new($anchoLogico, $altoLogico,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $g = [System.Drawing.Graphics]::FromImage($logico)
        try {
            $g.Clear([System.Drawing.Color]::Transparent)
            $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

            if ($Pieza -eq "cuerpo") {
                $anchoObjetivo = 180
                $yInferior = 192
            }
            elseif ($Pieza -eq "tejado") {
                $anchoObjetivo = 180
                $yInferior = 116
            }
            else {
                $anchoObjetivo = 60
                $yInferior = 40
            }

            $escala = $anchoObjetivo / [double] $recorte.Width
            $altoObjetivo = [Math]::Max(1, [int] [Math]::Round($recorte.Height * $escala))
            $xDestino = [int] [Math]::Round(($anchoLogico - $anchoObjetivo) / 2.0)
            $yDestino = $yInferior - $altoObjetivo
            $destino = [System.Drawing.Rectangle]::new(
                $xDestino, $yDestino, $anchoObjetivo, $altoObjetivo)
            $g.DrawImage($src, $destino, $recorte, [System.Drawing.GraphicsUnit]::Pixel)
        }
        finally {
            $g.Dispose()
        }

        # Limpieza del croma tras el escalado para evitar halos rosados.
        for ($y = 0; $y -lt $logico.Height; $y++) {
            for ($x = 0; $x -lt $logico.Width; $x++) {
                $c = $logico.GetPixel($x, $y)
                if ($c.A -eq 0) { continue }
                $dominancia = [int] $c.R + [int] $c.B - 2 * [int] $c.G
                $rbCercanos = [Math]::Abs([int] $c.R - [int] $c.B) -lt 85
                $bordePurpura = $c.R -gt ($c.G + 20) -and
                    $c.B -gt ($c.G + 20) -and $rbCercanos -and
                    ([int] $c.R + [int] $c.B) -gt 100
                if ($bordePurpura -or
                    ($c.R -gt 175 -and $c.B -gt 155 -and $dominancia -gt 140)) {
                    $logico.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                }
            }
        }

        $anchoFisico = $anchoLogico * 2
        $altoFisico = $altoLogico * 2
        $fisico = [System.Drawing.Bitmap]::new($anchoFisico, $altoFisico,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $gf = [System.Drawing.Graphics]::FromImage($fisico)
            try {
                $gf.Clear([System.Drawing.Color]::Transparent)
                $gf.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $gf.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                $gf.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                $gf.DrawImage($logico, 0, 0, $anchoFisico, $altoFisico)
            }
            finally {
                $gf.Dispose()
            }
            $fisico.Save($Salida, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $fisico.Dispose()
        }
    }
    finally {
        $logico.Dispose()
    }
}
finally {
    $src.Dispose()
}
