$ErrorActionPreference = "Stop"
# PowerShell 7 may otherwise throw on a nonzero pytest exit before subsequent rounds.
$PSNativeCommandUseErrorActionPreference = $false
Push-Location $PSScriptRoot
$previousRunId = $env:RUN_ID
$suiteFailed = $false
try {
    foreach ($round in 1..3) {
        $env:RUN_ID = "round$round"
        Write-Host "RecipeHub E2E: $env:RUN_ID"
        & uv run pytest -v -m "not manual"
        if ($LASTEXITCODE -ne 0) { $suiteFailed = $true }
    }
    & uv run python summarize.py
    if ($LASTEXITCODE -ne 0) { $suiteFailed = $true }
}
finally {
    $env:RUN_ID = $previousRunId
    Pop-Location
}
if ($suiteFailed) { exit 1 }
