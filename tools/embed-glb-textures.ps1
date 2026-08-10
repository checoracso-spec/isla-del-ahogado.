# Incrusta las texturas PNG externas dentro de un .glb como data URI base64.
# Necesario porque el navegador bloquea la carga de PNG sueltos via file://,
# pero si carga el .glb; con la textura embebida el modelo se ve completo.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File tools\embed-glb-textures.ps1 <archivo.glb> <carpetaTexturas>

param(
    [Parameter(Mandatory = $true)][string]$GlbPath,
    [Parameter(Mandatory = $true)][string]$TextureDir
)
$ErrorActionPreference = 'Stop'

$bytes = [System.IO.File]::ReadAllBytes($GlbPath)
$jsonChunkLen = [BitConverter]::ToUInt32($bytes, 12)
$jsonBytes = $bytes[20..(20 + $jsonChunkLen - 1)]
$jsonText = [System.Text.Encoding]::UTF8.GetString($jsonBytes)

$refs = [regex]::Matches($jsonText, '"uri":"(Textures/[^"]+\.png)"')
if ($refs.Count -eq 0) { Write-Host "sin-referencias-de-textura"; exit 0 }

$changed = $false
foreach ($m in $refs) {
    $relUri = $m.Groups[1].Value
    $texPath = Join-Path $TextureDir (Split-Path $relUri -Leaf)
    if (-not (Test-Path $texPath)) { Write-Host "  FALTA: $texPath"; continue }
    $b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($texPath))
    $jsonText = $jsonText.Replace('"uri":"' + $relUri + '"', '"uri":"data:image/png;base64,' + $b64 + '"')
    $changed = $true
}
if (-not $changed) { Write-Host "sin-cambios"; exit 0 }

$restBytes = $bytes[(20 + $jsonChunkLen)..($bytes.Length - 1)]
$newJsonBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonText)
$pad = (4 - ($newJsonBytes.Length % 4)) % 4
if ($pad -gt 0) {
    $padBytes = New-Object byte[] $pad
    for ($i = 0; $i -lt $pad; $i++) { $padBytes[$i] = 0x20 }
    $newJsonBytes = $newJsonBytes + $padBytes
}

$newHeader = $bytes[0..11].Clone()
$totalLen = 12 + 8 + $newJsonBytes.Length + $restBytes.Length
$lenBytes = [BitConverter]::GetBytes([uint32]$totalLen)
$newHeader[8] = $lenBytes[0]; $newHeader[9] = $lenBytes[1]
$newHeader[10] = $lenBytes[2]; $newHeader[11] = $lenBytes[3]

$out = New-Object System.Collections.Generic.List[byte]
$out.AddRange([byte[]]$newHeader)
$out.AddRange([byte[]][BitConverter]::GetBytes([uint32]$newJsonBytes.Length))
$out.AddRange([byte[]]$bytes[16..19])
$out.AddRange([byte[]]$newJsonBytes)
$out.AddRange([byte[]]$restBytes)
[System.IO.File]::WriteAllBytes($GlbPath, $out.ToArray())
Write-Host "listo: $GlbPath"
