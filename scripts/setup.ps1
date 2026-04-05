# ================================================================
#  AI Agent — First-Time Setup (Windows)
#  Run once after cloning the repo
#  Usage: .\scripts\setup.ps1
# ================================================================

$ErrorActionPreference = "Stop"
$ROOT = Split-Path $PSScriptRoot -Parent

function Write-Header { param($msg) Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-OK     { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn   { param($msg) Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Write-Fail   { param($msg) Write-Host "  [XX] $msg" -ForegroundColor Red }

Clear-Host
Write-Host @"

  ___  ____     ___                    _   
 / _ \|  _ \   / _ \__      _____ _ __ | |_ 
| | | | |_) | | | | \ \ /\ / / _ \ '__|| __|
| |_| |  __/  | |_| |\ V  V /  __/ |   | |_ 
 \__\_\_|      \___/  \_/\_/ \___|_|    \__|
                                             
  Local AI Agent Setup — Windows
"@ -ForegroundColor Cyan

# ── 1. Docker check ──────────────────────────────────────────
Write-Header "Checking Prerequisites"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Fail "Docker is not installed."
    Write-Host "  Please install Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host "  After installation, enable WSL2 backend in Docker Desktop settings." -ForegroundColor Yellow
    exit 1
}
Write-OK "Docker found"

try {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Fail "Docker daemon is not running."
    Write-Host "  Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}
Write-OK "Docker daemon is running"

if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Fail "docker compose not found (requires Docker Desktop >= 4.x)"
    exit 1
}
Write-OK "Docker Compose found"

# ── 2. .env file ─────────────────────────────────────────────
Write-Header "Environment Configuration"

$envFile    = Join-Path $ROOT ".env"
$envExample = Join-Path $ROOT ".env.example"

if (Test-Path $envFile) {
    Write-Warn ".env already exists — skipping copy (delete it to regenerate)"
} else {
    Copy-Item $envExample $envFile
    Write-OK ".env created from .env.example"
}

# Generate WEBUI_SECRET_KEY
$existingKey = (Select-String -Path $envFile -Pattern "^WEBUI_SECRET_KEY=change-me").Matches
if ($existingKey.Count -gt 0) {
    $newKey = -join ((33..126) | Get-Random -Count 48 | ForEach-Object { [char]$_ })
    (Get-Content $envFile) -replace "^WEBUI_SECRET_KEY=.*", "WEBUI_SECRET_KEY=$newKey" | Set-Content $envFile
    Write-OK "Generated WEBUI_SECRET_KEY"
} else {
    Write-Warn "WEBUI_SECRET_KEY already set — keeping existing value"
}

# ── 3. SearXNG secret key ─────────────────────────────────────
Write-Header "Configuring SearXNG"

$searxFile = Join-Path $ROOT "config\searxng\settings.yml"
$searxContent = Get-Content $searxFile -Raw

if ($searxContent -match "change-me-replaced-by-setup-script") {
    $searxKey = -join ((33..126) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
    # Escape special chars for replacement
    $escaped = [regex]::Escape($searxKey)
    (Get-Content $searxFile) -replace "change-me-replaced-by-setup-script", $searxKey | Set-Content $searxFile
    Write-OK "Generated SearXNG secret key"
} else {
    Write-Warn "SearXNG secret key already set"
}

# ── 4. Pull a model ───────────────────────────────────────────
Write-Header "Model Selection"
Write-Host "  Run the model picker to download your DeepSeek R1 model:" -ForegroundColor White
Write-Host "  > .\scripts\pull-model.ps1" -ForegroundColor Yellow

# ── 5. Continue.dev for VSCode / Cursor ──────────────────────
Write-Header "VSCode / Cursor Integration (Continue.dev)"

$continueDst = "$env:APPDATA\Code\User\globalStorage\continue.continue"
$continueDstCursor = "$env:APPDATA\Cursor\User\globalStorage\continue.continue"
$continueSrc = Join-Path $ROOT "config\continue\config.json"

foreach ($dst in @($continueDst, $continueDstCursor)) {
    if (Test-Path $dst) {
        $dstFile = Join-Path $dst "config.json"
        $backup  = Join-Path $dst "config.json.bak"
        if (Test-Path $dstFile) {
            Copy-Item $dstFile $backup -Force
            Write-Warn "Backed up existing Continue config to config.json.bak in $dst"
        }
        Copy-Item $continueSrc $dstFile -Force
        Write-OK "Installed Continue.dev config -> $dstFile"
    }
}
if (-not (Test-Path $continueDst) -and -not (Test-Path $continueDstCursor)) {
    Write-Warn "Continue.dev not installed yet."
    Write-Host "  1. Install Continue from: https://continue.dev" -ForegroundColor White
    Write-Host "  2. Then copy config\continue\config.json to:" -ForegroundColor White
    Write-Host "     %APPDATA%\Code\User\globalStorage\continue.continue\config.json" -ForegroundColor Yellow
}

# ── Done ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Setup complete! Next steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Pull a model  :  .\scripts\pull-model.ps1" -ForegroundColor White
Write-Host "  2. Start stack   :  .\scripts\start.ps1" -ForegroundColor White
Write-Host "  3. Open browser  :  http://localhost:3000" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
