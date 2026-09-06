param(
    [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = "Stop"
$godot = "C:\Users\checo\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
$root = (Get-Location).Path
$scenes = Get-ChildItem -Path (Join-Path $root "escenas") -Filter "prueba_*.tscn" | Sort-Object Name
$results = @()

foreach ($scene in $scenes) {
    $name = [IO.Path]::GetFileNameWithoutExtension($scene.Name)
    $output = Join-Path $env:TEMP ("marea-test-" + $name + ".log")
    $errorLog = Join-Path $env:TEMP ("marea-test-" + $name + ".err.log")
    if (Test-Path -LiteralPath $output) {
        Remove-Item -LiteralPath $output -Force
    }
    if (Test-Path -LiteralPath $errorLog) {
        Remove-Item -LiteralPath $errorLog -Force
    }

    $arguments = @("--headless", "--path", $root, ("res://escenas/" + $scene.Name))
    $process = Start-Process -FilePath $godot -ArgumentList $arguments -WorkingDirectory $root -RedirectStandardOutput $output -RedirectStandardError $errorLog -PassThru
    $finished = $process.WaitForExit($TimeoutSeconds * 1000)
    if (-not $finished) {
        try { $process.Kill($true) } catch {}
        $results += [PSCustomObject]@{ Name = $name; Exit = "TIMEOUT"; Error = $true; Summary = "no termino" }
        continue
    }

    $process.Refresh()
    $text = (Get-Content -LiteralPath $output -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content -LiteralPath $errorLog -Raw -ErrorAction SilentlyContinue)
    $errorFound = $text -match "SCRIPT ERROR|Parse Error|Invalid call|Invalid access|Assertion failed|ERROR:"
    $summaryLines = @($text -split "`r?`n" | Where-Object { $_ -match "correctas|LISTO|comprobaciones" })
    $summary = if ($summaryLines.Count -gt 0) { $summaryLines[-1].Trim() } else { "sin resumen" }
    $exitCode = $process.ExitCode
    if ($null -eq $exitCode) {
        $exitCode = 0
    }
    $results += [PSCustomObject]@{ Name = $name; Exit = $exitCode; Error = $errorFound; Summary = $summary }
}

$results | Format-Table -AutoSize
$failed = @($results | Where-Object { $_.Exit -ne 0 -or $_.Error })
Write-Output ("TOTAL_ESCENAS=" + $scenes.Count)
Write-Output ("FALLAS=" + $failed.Count)
if ($failed.Count -gt 0) {
    $failed | Format-List
    exit 1
}
exit 0
