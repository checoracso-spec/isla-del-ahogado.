# Genera los PNG técnicos del kit de validación leyendo el manifiesto.
#
# NO son cuadrados de colores. Cada uno lleva:
#   · el rombo de base dibujado, para ver si la huella cuadra
#   · una CRUZ EN EL PIVOTE, para que un anclaje mal puesto se vea al instante
#     en vez de manifestarse como "el edificio parece un poco hundido"
#   · marcas en las esquinas del lienzo, para detectar recortes
#
# Todo se dibuja a resolución LÓGICA y se amplía ×2 con Nearest Neighbor, así
# que cada píxel artístico acaba siendo un bloque físico de 2×2 — igual que
# tendrá que serlo el arte de verdad.
#
# Uso:  powershell -ExecutionPolicy Bypass -File tools\generar-placeholders.ps1
# Para añadir piezas sin reemplazar arte aprobado: -SoloFaltantes

param([switch]$SoloFaltantes)

Add-Type -AssemblyName System.Drawing

$raiz = Join-Path $PSScriptRoot ".."
$kit = Join-Path $raiz "godot\assets\kit_validacion"
$manifiesto = Join-Path $kit "manifiesto.json"

if (-not (Test-Path $manifiesto)) { throw "No encuentro $manifiesto" }
$doc = Get-Content $manifiesto -Raw -Encoding UTF8 | ConvertFrom-Json

$PALETA = @{
    hierba = "5e8e44"; tierra = "8a6a45"; arena = "d8bc89"; agua = "2c7793"
    madera = "6b4a2c"; piedra = "8b8e92"; tinta = "222f3a"; pivote = "ff2fd0"
    marca  = "48d1c4"; cuerpo = "7d6549"; tejado = "8a4a46"; ui = "3a4a5c"
}

function C([string]$hex, [int]$a = 255) {
    return [System.Drawing.Color]::FromArgb($a,
        [Convert]::ToInt32($hex.Substring(0,2),16),
        [Convert]::ToInt32($hex.Substring(2,2),16),
        [Convert]::ToInt32($hex.Substring(4,2),16))
}

function NuevoLienzo([int]$w, [int]$h) {
    $b = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $g.Clear([System.Drawing.Color]::Transparent)
    return @{ bmp = $b; g = $g }
}

function Rombo($g, [double]$cx, [double]$cy, [double]$rw, [double]$rh, $relleno, $borde) {
    $pts = @(
        (New-Object System.Drawing.PointF(($cx),      ($cy - $rh))),
        (New-Object System.Drawing.PointF(($cx + $rw), ($cy))),
        (New-Object System.Drawing.PointF(($cx),      ($cy + $rh))),
        (New-Object System.Drawing.PointF(($cx - $rw), ($cy)))
    )
    if ($relleno) { $g.FillPolygon((New-Object System.Drawing.SolidBrush($relleno)), $pts) }
    if ($borde)   { $g.DrawPolygon((New-Object System.Drawing.Pen($borde, 1)), $pts) }
}

function CruzPivote($g, [double]$x, [double]$y) {
    $p = New-Object System.Drawing.Pen((C $PALETA.pivote), 1)
    $g.DrawLine($p, $x - 4, $y, $x + 4, $y)
    $g.DrawLine($p, $x, $y - 4, $x, $y + 4)
    $g.DrawRectangle($p, $x - 1, $y - 1, 2, 2)
}

function MarcasEsquina($g, [int]$w, [int]$h) {
    $p = New-Object System.Drawing.Pen((C $PALETA.marca), 1)
    foreach ($e in @(@(0,0,1,1), @(($w-1),0,-1,1), @(0,($h-1),1,-1), @(($w-1),($h-1),-1,-1))) {
        $g.DrawLine($p, $e[0], $e[1], $e[0] + 3*$e[2], $e[1])
        $g.DrawLine($p, $e[0], $e[1], $e[0], $e[1] + 3*$e[3])
    }
}

function GuardarAmpliado($lienzo, [int]$w, [int]$h, [int]$escala, [string]$destino) {
    $out = New-Object System.Drawing.Bitmap(($w * $escala), ($h * $escala),
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $go = [System.Drawing.Graphics]::FromImage($out)
    $go.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $go.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $go.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    $go.DrawImage($lienzo.bmp, 0, 0, ($w * $escala), ($h * $escala))
    $go.Dispose()
    $dir = Split-Path $destino -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    $out.Save($destino, [System.Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
    $lienzo.g.Dispose(); $lienzo.bmp.Dispose()
}

# ---------------------------------------------------------------------------

function HazTile($d, [string]$destino) {
    $cw = [int]$d.celda_logica[0]; $ch = [int]$d.celda_logica[1]
    $tw = [int]$d.tam_logico[0];   $th = [int]$d.tam_logico[1]
    $cols = [int]($tw / $cw)
    $L = NuevoLienzo $tw $th
    $nombres = @()
    if ($d.PSObject.Properties.Name -contains "celdas") {
        $nombres = $d.celdas.PSObject.Properties | Sort-Object { $_.Value } | ForEach-Object { $_.Name }
    }
    for ($i = 0; $i -lt $cols; $i++) {
        $clave = if ($i -lt $nombres.Count) { $nombres[$i] } else { "hierba" }
        $col = if ($PALETA.ContainsKey($clave)) { $PALETA[$clave] } else { $PALETA.hierba }
        $cx = $i * $cw + $cw / 2.0
        Rombo $L.g $cx ($ch / 2.0) (($cw / 2.0) - 1) (($ch / 2.0) - 1) (C $col) (C $PALETA.tinta)
    }
    GuardarAmpliado $L $tw $th ([int]$d.escala_pixel) $destino
}

# 16 celdas: celda n = máscara n. bit0 arriba, bit1 derecha, bit2 abajo, bit3 izq.
function HazMascaras($d, [string]$destino) {
    $cw = [int]$d.celda_logica[0]; $ch = [int]$d.celda_logica[1]
    $tw = [int]$d.tam_logico[0];   $th = [int]$d.tam_logico[1]
    $L = NuevoLienzo $tw $th
    $ca = C $PALETA[[string]$d.nivel_a]
    $cb = C $PALETA[[string]$d.nivel_b]
    for ($m = 0; $m -lt 16; $m++) {
        $ox = $m * $cw
        $cx = $ox + $cw / 2.0; $cy = $ch / 2.0
        $rw = ($cw / 2.0) - 1; $rh = ($ch / 2.0) - 1
        Rombo $L.g $cx $cy $rw $rh $ca (C $PALETA.tinta)
        $V = @(
            @($cx, ($cy - $rh)), @(($cx + $rw), $cy), @($cx, ($cy + $rh)), @(($cx - $rw), $cy))
        for ($b = 0; $b -lt 4; $b++) {
            if (-not ($m -band (1 -shl $b))) { continue }
            $ant = $V[($b + 3) % 4]; $vt = $V[$b]; $sig = $V[($b + 1) % 4]
            $pts = @(
                (New-Object System.Drawing.PointF($cx, $cy)),
                (New-Object System.Drawing.PointF((($ant[0]+$vt[0])/2), (($ant[1]+$vt[1])/2))),
                (New-Object System.Drawing.PointF($vt[0], $vt[1])),
                (New-Object System.Drawing.PointF((($vt[0]+$sig[0])/2), (($vt[1]+$sig[1])/2)))
            )
            $L.g.FillPolygon((New-Object System.Drawing.SolidBrush($cb)), $pts)
        }
        Rombo $L.g $cx $cy $rw $rh $null (C $PALETA.tinta)
    }
    GuardarAmpliado $L $tw $th ([int]$d.escala_pixel) $destino
}

function HazSprite($d, [string]$clave, [string]$destino) {
    $w = [int]$d.tam_logico[0]; $h = [int]$d.tam_logico[1]
    $esc = [int]$d.escala_pixel
    $px = [double]$d.pivote[0] / $esc; $py = [double]$d.pivote[1] / $esc
    $L = NuevoLienzo $w $h

    $hu = @(1,1)
    if ($d.PSObject.Properties.Name -contains "huella") { $hu = @([int]$d.huella[0], [int]$d.huella[1]) }
    # Rombo de la huella, con el vértice inferior EN el pivote.
    $rw = ($hu[0] + $hu[1]) * 16.0
    $rh = ($hu[0] + $hu[1]) * 8.0
    Rombo $L.g $px ($py - $rh) $rw $rh (C $PALETA.arena 90) (C $PALETA.marca)

    $es_tejado = $clave -like "*tejado*"
    $col = if ($es_tejado) { C $PALETA.tejado } else { C $PALETA.cuerpo }
    if ($es_tejado) {
        $pts = @(
            (New-Object System.Drawing.PointF($px, 4)),
            (New-Object System.Drawing.PointF(($px + $rw), ($py - $rh))),
            (New-Object System.Drawing.PointF($px, ($py - $rh + 8))),
            (New-Object System.Drawing.PointF(($px - $rw), ($py - $rh)))
        )
        $L.g.FillPolygon((New-Object System.Drawing.SolidBrush($col)), $pts)
        $L.g.DrawPolygon((New-Object System.Drawing.Pen((C $PALETA.tinta), 1)), $pts)
    } else {
        $alto = [Math]::Max(8, $py - $rh * 2 - 4)
        $L.g.FillRectangle((New-Object System.Drawing.SolidBrush($col)),
            ($px - $rw * 0.6), $alto, ($rw * 1.2), ($py - $rh - $alto))
        $L.g.DrawRectangle((New-Object System.Drawing.Pen((C $PALETA.tinta), 1)),
            ($px - $rw * 0.6), $alto, ($rw * 1.2), ($py - $rh - $alto))
    }

    MarcasEsquina $L.g $w $h
    CruzPivote $L.g $px $py
    GuardarAmpliado $L $w $h $esc $destino
}

function HazAnimacion($d, [string]$destino) {
    $fw = [int]$d.fotograma_logico[0]; $fh = [int]$d.fotograma_logico[1]
    $esc = [int]$d.escala_pixel
    $n = [int]$d.fotogramas
    $dirs = @($d.direcciones)
    $w = $fw * $n; $h = $fh * $dirs.Count
    $px = [double]$d.pivote[0] / $esc; $py = [double]$d.pivote[1] / $esc
    $L = NuevoLienzo $w $h
    $flechas = @{ abajo = @(0,1); izquierda = @(-1,0); arriba = @(0,-1); derecha = @(1,0) }

    for ($f = 0; $f -lt $dirs.Count; $f++) {
        $dir = [string]$dirs[$f]
        for ($c = 0; $c -lt $n; $c++) {
            $ox = $c * $fw; $oy = $f * $fh
            $L.g.DrawRectangle((New-Object System.Drawing.Pen((C $PALETA.tinta), 1)),
                $ox, $oy, ($fw - 1), ($fh - 1))
            # cuerpo: la altura oscila con el fotograma, para ver la animación
            $bob = [Math]::Abs(($c % 4) - 2)
            $bx = $ox + $fw / 2.0
            $by = $oy + $py
            $L.g.FillRectangle((New-Object System.Drawing.SolidBrush((C $PALETA.cuerpo))),
                ($bx - 4), ($by - 22 - $bob), 8, (18 + $bob))
            $L.g.FillEllipse((New-Object System.Drawing.SolidBrush((C $PALETA.arena))),
                ($bx - 4), ($by - 30 - $bob), 8, 8)
            # flecha de dirección
            $fl = $flechas[$dir]
            $p = New-Object System.Drawing.Pen((C $PALETA.marca), 1)
            $L.g.DrawLine($p, $bx, ($oy + 6), ($bx + $fl[0] * 6), ($oy + 6 + $fl[1] * 6))
            # puntos = índice de fotograma
            for ($k = 0; $k -le $c; $k++) {
                $L.g.FillRectangle((New-Object System.Drawing.SolidBrush((C $PALETA.pivote))),
                    ($ox + 2 + $k * 2), ($oy + $fh - 3), 1, 1)
            }
            CruzPivote $L.g ($ox + $px) ($oy + $py)
        }
    }
    GuardarAmpliado $L $w $h $esc $destino
}

function HazNuevePartes($d, [string]$destino) {
    $w = [int]$d.tam_logico[0]; $h = [int]$d.tam_logico[1]
    $esc = [int]$d.escala_pixel
    $m = @($d.margenes) | ForEach-Object { [int]$_ / $esc }
    $L = NuevoLienzo $w $h
    $L.g.FillRectangle((New-Object System.Drawing.SolidBrush((C $PALETA.ui 220))), 0, 0, $w, $h)
    $L.g.DrawRectangle((New-Object System.Drawing.Pen((C $PALETA.marca), 1)), 0, 0, ($w-1), ($h-1))
    # guías de los márgenes: donde el 9-patch parte la imagen
    $p = New-Object System.Drawing.Pen((C $PALETA.pivote), 1)
    if ($m[0] -gt 0) { $L.g.DrawLine($p, $m[0], 0, $m[0], ($h-1)) }
    if ($m[1] -gt 0) { $L.g.DrawLine($p, ($w-1-$m[1]), 0, ($w-1-$m[1]), ($h-1)) }
    if ($m[2] -gt 0) { $L.g.DrawLine($p, 0, $m[2], ($w-1), $m[2]) }
    if ($m[3] -gt 0) { $L.g.DrawLine($p, 0, ($h-1-$m[3]), ($w-1), ($h-1-$m[3])) }
    GuardarAmpliado $L $w $h $esc $destino
}

# ---------------------------------------------------------------------------

$hechos = 0
foreach ($prop in $doc.assets.PSObject.Properties) {
    $clave = $prop.Name
    $d = $prop.Value
    $destino = Join-Path $kit ([string]$d.archivo).Replace("/", "\")
	if ($SoloFaltantes -and (Test-Path -LiteralPath $destino)) {
		continue
	}
    switch ([string]$d.tipo) {
        "atlas_tile"    { HazTile $d $destino }
        "atlas_mascara" { HazMascaras $d $destino }
        "sprite"        { HazSprite $d $clave $destino }
        "animacion"     { HazAnimacion $d $destino }
        "nueve_partes"  { HazNuevePartes $d $destino }
        default         { Write-Host "  (tipo desconocido: $($d.tipo)) $clave"; continue }
    }
    "{0,-34} {1}" -f $clave, ([string]$d.archivo)
    $hechos++
}
"`n$hechos placeholders generados en $kit"
