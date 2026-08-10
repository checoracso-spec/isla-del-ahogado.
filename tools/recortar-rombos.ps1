# Recorta los rombos de las hojas de tiles isométricos.
#
# POR QUÉ HACE FALTA: los PNG de Screaming Brain Studios traen las esquinas de
# cada celda en NEGRO OPACO, no transparente. En un mapa isométrico las celdas
# se solapan por las esquinas, así que cada tile pintaba un rectángulo negro
# encima de sus vecinos y el suelo salía a cuadros.
#
# Qué hace: por cada celda de 128x64, pone alfa 0 en todo lo que cae FUERA del
# rombo inscrito. Es exacto: los rombos de estas hojas están generados a máquina
# y encajan con la retícula al píxel.
#
# El adoquín (128x72) tiene el borde levantado y no es un rombo limpio, así que
# ahí se quita sólo el negro puro.
#
# Uso:  powershell -ExecutionPolicy Bypass -File tools\recortar-rombos.ps1

Add-Type -AssemblyName System.Drawing

$crudo  = Join-Path $PSScriptRoot "..\assets_raw\iso"
$destino = Join-Path $PSScriptRoot "..\godot\assets\tiles"

function Recortar-Rombos {
    param([string]$Origen, [string]$Destino, [int]$CeldaW = 128, [int]$CeldaH = 64,
          [switch]$SoloNegro)

    $src = New-Object System.Drawing.Bitmap($Origen)
    $bmp = New-Object System.Drawing.Bitmap($src.Width, $src.Height, `
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.DrawImage($src, 0, 0, $src.Width, $src.Height)
    $g.Dispose(); $src.Dispose()

    $rect = New-Object System.Drawing.Rectangle(0, 0, $bmp.Width, $bmp.Height)
    $datos = $bmp.LockBits($rect, 'ReadWrite', 'Format32bppArgb')
    $bytes = New-Object byte[] ($datos.Stride * $bmp.Height)
    [System.Runtime.InteropServices.Marshal]::Copy($datos.Scan0, $bytes, 0, $bytes.Length)

    $borrados = 0
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        $fila = $y * $datos.Stride
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            $i = $fila + $x * 4       # BGRA
            $quitar = $false
            if ($SoloNegro) {
                if ($bytes[$i] -le 8 -and $bytes[$i+1] -le 8 -and $bytes[$i+2] -le 8) { $quitar = $true }
            } else {
                $dx = [math]::Abs(($x % $CeldaW) + 0.5 - ($CeldaW / 2.0)) / ($CeldaW / 2.0)
                $dy = [math]::Abs(($y % $CeldaH) + 0.5 - ($CeldaH / 2.0)) / ($CeldaH / 2.0)
                if (($dx + $dy) -gt 1.0) { $quitar = $true }
            }
            if ($quitar -and $bytes[$i+3] -ne 0) { $bytes[$i+3] = 0; $borrados++ }
        }
    }

    [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $datos.Scan0, $bytes.Length)
    $bmp.UnlockBits($datos)
    $bmp.Save($Destino, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    "{0,-26} {1,9:N0} px a transparente" -f (Split-Path $Destino -Leaf), $borrados
}

# La tira base sale de "Solid Tiles Flat": 6 rombos e incluye AGUA, que la otra
# tira no tenía. Orden: hierba A, hierba B, tierra A, tierra B, arena, agua.
Recortar-Rombos "$crudo\water\Water\Flat\Solid Tiles Flat 128x88.png" "$destino\base.png"

Recortar-Rombos "$crudo\water\Water\Flat\Sand A - Water Flat 128x64.png"  "$destino\trans_arena_agua.png"
Recortar-Rombos "$crudo\autotiles\Autotiles\128x64 Grass A to Sand A.png" "$destino\trans_hierba_arena.png"
Recortar-Rombos "$crudo\autotiles\Autotiles\128x64 Grass A to Dirt A.png" "$destino\trans_hierba_tierra.png"
Recortar-Rombos "$crudo\floors\Small 128x64\Worldmap\1 Forests 128x64.png"      "$destino\bosque.png"
Recortar-Rombos "$crudo\floors\Small 128x64\Worldmap\2 Ground - Rocky 128x64.png" "$destino\roca.png"

Recortar-Rombos "$crudo\floors\Small 128x64\Pathways\1 Basic Ground - 128x72.png" `
    "$destino\adoquin.png" -CeldaH 72 -SoloNegro

"Listo."
