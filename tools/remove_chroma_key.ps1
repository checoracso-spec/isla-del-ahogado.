param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Add-Type -AssemblyName System.Drawing

$source = [System.Drawing.Bitmap]::new($InputPath)
$result = [System.Drawing.Bitmap]::new(
    $source.Width,
    $source.Height,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
)

$key = $source.GetPixel(0, 0)
for ($y = 0; $y -lt $source.Height; $y++) {
    for ($x = 0; $x -lt $source.Width; $x++) {
        $pixel = $source.GetPixel($x, $y)
        $dr = [int]$pixel.R - [int]$key.R
        $dg = [int]$pixel.G - [int]$key.G
        $db = [int]$pixel.B - [int]$key.B
        $distance = [math]::Sqrt($dr * $dr + $dg * $dg + $db * $db)

        if ($distance -le 55) {
            $result.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, $pixel.R, $pixel.G, $pixel.B))
        } elseif ($distance -le 100) {
            $alpha = [int](255.0 * (($distance - 55.0) / 45.0))
            $result.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $pixel.R, $pixel.G, $pixel.B))
        } else {
            $result.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $pixel.R, $pixel.G, $pixel.B))
        }
    }
}

$result.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$result.Dispose()
$source.Dispose()
