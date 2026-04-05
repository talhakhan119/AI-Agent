# ================================================================
#  AI Agent — Stop Stack (Windows)
#  Usage: .\scripts\stop.ps1
#         .\scripts\stop.ps1 -Purge   (also removes volumes/data)
# ================================================================

param(
    [switch]$Purge
)

$ROOT = Split-Path $PSScriptRoot -Parent
Push-Location $ROOT

Write-Host ""
Write-Host "  Stopping AI Agent Stack..." -ForegroundColor Yellow

if ($Purge) {
    Write-Host "  WARNING: -Purge will delete all conversation history and model data!" -ForegroundColor Red
    $confirm = Read-Host "  Type 'yes' to confirm"
    if ($confirm -ne "yes") {
        Write-Host "  Aborted." -ForegroundColor Gray
        Pop-Location
        exit 0
    }
    docker compose down -v
    Write-Host "  [OK] All containers and volumes removed." -ForegroundColor Green
} else {
    docker compose down
    Write-Host "  [OK] Containers stopped. Data volumes preserved." -ForegroundColor Green
    Write-Host "  (Use -Purge to also delete all data)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  Resources freed. CPU and RAM usage dropped to zero." -ForegroundColor Cyan
Write-Host ""

Pop-Location
