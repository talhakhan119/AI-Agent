# ================================================================
#  AI Agent — Start Stack (Windows)
#  Usage: .\scripts\start.ps1
#         .\scripts\start.ps1 -GPU     (NVIDIA GPU support)
# ================================================================

param(
    [switch]$GPU
)

$ROOT = Split-Path $PSScriptRoot -Parent
Push-Location $ROOT

function Write-Header { param($msg) Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-OK     { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn   { param($msg) Write-Host "  [!!] $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  Starting AI Agent Stack..." -ForegroundColor Cyan

# ── .env check ───────────────────────────────────────────────
if (-not (Test-Path ".env")) {
    Write-Warn ".env not found — running setup first"
    & "$PSScriptRoot\setup.ps1"
}

# ── Build compose command ─────────────────────────────────────
if ($GPU) {
    Write-Host "  Mode: GPU (NVIDIA)" -ForegroundColor Magenta
    $composeCmd = "docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d"
} else {
    Write-Host "  Mode: CPU" -ForegroundColor White
    $composeCmd = "docker compose up -d"
}

# ── Start services ────────────────────────────────────────────
Write-Header "Launching Containers"
Invoke-Expression $composeCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [XX] Failed to start containers. Check Docker Desktop is running." -ForegroundColor Red
    Pop-Location
    exit 1
}

# ── Wait for Open WebUI ───────────────────────────────────────
Write-Header "Waiting for Services"
Write-Host "  Waiting for Open WebUI to be ready..." -ForegroundColor White

$webuiPort = if (Test-Path ".env") {
    $p = (Select-String -Path ".env" -Pattern "^WEBUI_PORT=(.+)").Matches.Groups[1].Value
    if ($p) { $p } else { "3000" }
} else { "3000" }

$maxAttempts = 30
$attempt = 0
do {
    Start-Sleep -Seconds 3
    $attempt++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$webuiPort" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) { break }
    } catch {}
    Write-Host "  Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
} while ($attempt -lt $maxAttempts)

# ── Status ────────────────────────────────────────────────────
Write-Header "Service Status"
docker compose ps

# ── Show loaded model ─────────────────────────────────────────
$model = if (Test-Path ".env") {
    $m = (Select-String -Path ".env" -Pattern "^OLLAMA_MODEL=(.+)").Matches.Groups[1].Value
    if ($m) { $m } else { "(not set)" }
} else { "(not set)" }

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  AI Agent is running!" -ForegroundColor Green
Write-Host ""
Write-Host "  Open WebUI  :  http://localhost:$webuiPort" -ForegroundColor Cyan
Write-Host "  Ollama API  :  http://localhost:11434" -ForegroundColor Cyan
Write-Host "  SearXNG     :  http://localhost:8080" -ForegroundColor Cyan
Write-Host "  Model       :  $model" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Stop with   :  .\scripts\stop.ps1" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

# ── Open browser ──────────────────────────────────────────────
$open = Read-Host "  Open browser now? [Y/n]"
if ($open -ne "n" -and $open -ne "N") {
    Start-Process "http://localhost:$webuiPort"
}

Pop-Location
