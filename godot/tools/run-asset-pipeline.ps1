param(
    [ValidateSet('validate', 'normalize', 'sheet')]
    [string]$Command = 'validate',
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Arguments = @($Command)
if ($Strict -and $Command -eq 'validate') { $Arguments += '--strict' }
python (Join-Path $PSScriptRoot 'asset_pipeline.py') @Arguments
exit $LASTEXITCODE
