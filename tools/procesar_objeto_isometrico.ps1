param(
    [Parameter(Mandatory = $true)] [string] $Entrada,
    [Parameter(Mandatory = $true)] [string] $Salida,
    [Parameter(Mandatory = $true)] [int] $Ancho,
    [Parameter(Mandatory = $true)] [int] $Alto,
    [Parameter(Mandatory = $true)] [int] $PivoteY
)

Add-Type -AssemblyName System.Drawing
$src=[System.Drawing.Bitmap]::new($Entrada)
function Es-Croma([System.Drawing.Color]$c) {
	if ($c.A -eq 0) { return $true }
    $rb=[Math]::Abs([int]$c.R-[int]$c.B)-lt 85
	$magenta=$c.R-gt($c.G+20)-and $c.B-gt($c.G+20)-and $rb-and([int]$c.R+[int]$c.B)-gt 90
	$verde=$c.G-gt($c.R+35)-and $c.G-gt($c.B+35)-and $c.G-gt 100
	return $magenta-or$verde
}
try {
    $minX=$src.Width;$minY=$src.Height;$maxX=0;$maxY=0
    for($y=0;$y-lt$src.Height;$y+=4){for($x=0;$x-lt$src.Width;$x+=4){
        if(-not(Es-Croma $src.GetPixel($x,$y))){
            $minX=[Math]::Min($minX,$x);$maxX=[Math]::Max($maxX,$x)
            $minY=[Math]::Min($minY,$y);$maxY=[Math]::Max($maxY,$y)
        }
    }}
    $minX=[Math]::Max(0,$minX-4);$minY=[Math]::Max(0,$minY-4)
    $maxX=[Math]::Min($src.Width-1,$maxX+4);$maxY=[Math]::Min($src.Height-1,$maxY+4)
    $r=[System.Drawing.Rectangle]::new($minX,$minY,$maxX-$minX+1,$maxY-$minY+1)
    $lw=[int]($Ancho/2);$lh=[int]($Alto/2);$lp=[int]($PivoteY/2)
    $maxW=$lw-4;$maxH=$lp-2
    $scale=[Math]::Min($maxW/[double]$r.Width,$maxH/[double]$r.Height)
    $dw=[Math]::Max(1,[int][Math]::Round($r.Width*$scale))
    $dh=[Math]::Max(1,[int][Math]::Round($r.Height*$scale))
    $dx=[int][Math]::Round(($lw-$dw)/2.0);$dy=$lp-$dh
    $logical=[System.Drawing.Bitmap]::new($lw,$lh,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $g=[System.Drawing.Graphics]::FromImage($logical);$g.Clear([System.Drawing.Color]::Transparent)
        $g.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($src,[System.Drawing.Rectangle]::new($dx,$dy,$dw,$dh),$r,[System.Drawing.GraphicsUnit]::Pixel);$g.Dispose()
        for($y=0;$y-lt$lh;$y++){for($x=0;$x-lt$lw;$x++){
            if(Es-Croma $logical.GetPixel($x,$y)){$logical.SetPixel($x,$y,[System.Drawing.Color]::Transparent)}
        }}
        $physical=[System.Drawing.Bitmap]::new($Ancho,$Alto,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $gp=[System.Drawing.Graphics]::FromImage($physical);$gp.Clear([System.Drawing.Color]::Transparent)
            $gp.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $gp.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $gp.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $gp.DrawImage($logical,0,0,$Ancho,$Alto);$gp.Dispose()
            $physical.Save($Salida,[System.Drawing.Imaging.ImageFormat]::Png)
        }finally{$physical.Dispose()}
    }finally{$logical.Dispose()}
}finally{$src.Dispose()}
