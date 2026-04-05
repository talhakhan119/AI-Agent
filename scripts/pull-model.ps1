# ================================================================
#  AI Agent — Model Selector & Puller (Windows)
#  Picks the right DeepSeek R1 variant for your machine specs
#  Usage: .\scripts\pull-model.ps1
#         .\scripts\pull-model.ps1 -Model deepseek-r1:14b
# ================================================================

param(
    [string]$Model = ""
)

$ErrorActionPreference = "Stop"
$ROOT = Split-Path $PSScriptRoot -Parent

function Write-Header { param($msg) Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-OK     { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn   { param($msg) Write-Host "  [!!] $msg" -ForegroundColor Yellow }

# ── Model Tiers ──────────────────────────────────────────────
$MODELS = [ordered]@{
    "1" = @{
        tag         = "deepseek-r1:7b"
        size        = "~4.7 GB"
        ramRequired = "8 GB RAM"
        gpu         = "CPU only — no GPU needed"
        speed       = "Slow on CPU, very capable for its size"
        best        = "Laptops, low-spec machines, first test"
    }
    "2" = @{
        tag         = "deepseek-r1:14b"
        size        = "~9 GB"
        ramRequired = "16 GB RAM  OR  8 GB VRAM"
        gpu         = "Runs well on RTX 3060 8 GB or better"
        speed       = "Good balance of speed and quality"
        best        = "Gaming laptops, mid-range desktops"
    }
    "3" = @{
        tag         = "deepseek-r1:32b"
        size        = "~20 GB"
        ramRequired = "32 GB RAM  OR  16 GB VRAM"
        gpu         = "RTX 3090 / 4080 or better"
        speed       = "Excellent quality, near GPT-4 level"
        best        = "High-spec workstations, servers"
    }
    "4" = @{
        tag         = "deepseek-r1:70b"
        size        = "~43 GB"
        ramRequired = "64 GB RAM  OR  24 GB VRAM"
        gpu         = "RTX 4090 / A100 or multi-GPU"
        speed       = "Exceptional quality"
        best        = "Servers, cloud VMs, power users"
    }
    "5" = @{
        tag         = "deepseek-r1:1.5b"
        size        = "~1.1 GB"
        ramRequired = "4 GB RAM"
        gpu         = "Any / CPU only"
        speed       = "Very fast, basic reasoning"
        best        = "Extreme low-spec, quick tests"
    }
}

Clear-Host
Write-Host @"

  DeepSeek R1 — Model Selection
  ================================
  All models have built-in Chain-of-Thought reasoning (like Claude Thinking).
  Bigger = smarter + slower + more RAM.

"@ -ForegroundColor Cyan

foreach ($key in $MODELS.Keys) {
    $m = $MODELS[$key]
    Write-Host "  [$key] $($m.tag)" -ForegroundColor Yellow -NoNewline
    Write-Host "  ($($m.size))" -ForegroundColor Gray
    Write-Host "      RAM  : $($m.ramRequired)" -ForegroundColor White
    Write-Host "      GPU  : $($m.gpu)" -ForegroundColor White
    Write-Host "      Best : $($m.best)" -ForegroundColor White
    Write-Host ""
}

# ── Detect RAM ───────────────────────────────────────────────
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host "  Detected system RAM: ${ramGB} GB" -ForegroundColor Magenta

$suggested = "1"
if ($ramGB -ge 64) { $suggested = "4" }
elseif ($ramGB -ge 32) { $suggested = "3" }
elseif ($ramGB -ge 16) { $suggested = "2" }
Write-Host "  Suggested tier for your machine: [$suggested] $($MODELS[$suggested].tag)" -ForegroundColor Green
Write-Host ""

# ── Selection ────────────────────────────────────────────────
if ($Model -ne "") {
    $selectedTag = $Model
    Write-Host "  Using model from -Model flag: $selectedTag" -ForegroundColor Cyan
} else {
    $choice = Read-Host "  Enter tier number (1-5) or press Enter for suggested [$suggested]"
    if ($choice -eq "") { $choice = $suggested }
    
    if (-not $MODELS.Contains($choice)) {
        Write-Host "  Invalid choice. Using suggested: $suggested" -ForegroundColor Yellow
        $choice = $suggested
    }
    $selectedTag = $MODELS[$choice].tag
}

Write-Host ""
Write-Host "  Selected: $selectedTag" -ForegroundColor Cyan

# ── Ensure Ollama is running ──────────────────────────────────
Write-Header "Pulling Model"

$ollamaRunning = docker ps --filter "name=ai-agent-ollama" --filter "status=running" -q 2>$null
if (-not $ollamaRunning) {
    Write-Warn "Ollama container is not running. Starting it now..."
    Push-Location $ROOT
    docker compose up -d ollama 2>&1 | Out-Null
    Pop-Location
    Start-Sleep -Seconds 8
}

Write-Host "  Pulling $selectedTag from Ollama registry..." -ForegroundColor White
Write-Host "  (This may take several minutes depending on your connection)" -ForegroundColor Gray
Write-Host ""

docker exec ai-agent-ollama ollama pull $selectedTag

if ($LASTEXITCODE -eq 0) {
    Write-OK "Model pulled successfully: $selectedTag"
    
    # ── Also pull embedding model ──────────────────────────────
    Write-Host ""
    Write-Host "  Pulling embedding model (nomic-embed-text, ~274 MB)..." -ForegroundColor White
    docker exec ai-agent-ollama ollama pull nomic-embed-text
    Write-OK "Embedding model ready"

    # ── Update .env ────────────────────────────────────────────
    $envFile = Join-Path $ROOT ".env"
    if (Test-Path $envFile) {
        (Get-Content $envFile) -replace "^OLLAMA_MODEL=.*", "OLLAMA_MODEL=$selectedTag" | Set-Content $envFile
        Write-OK "Updated OLLAMA_MODEL in .env to $selectedTag"
    }

    # ── Update Continue.dev config ─────────────────────────────
    $continueConfig = Join-Path $ROOT "config\continue\config.json"
    $json = Get-Content $continueConfig -Raw | ConvertFrom-Json
    foreach ($m in $json.models) { $m.model = $selectedTag }
    $json.tabAutocompleteModel.model = $selectedTag
    $json | ConvertTo-Json -Depth 10 | Set-Content $continueConfig
    Write-OK "Updated config\continue\config.json to use $selectedTag"

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Ready! Start the full stack with:" -ForegroundColor Cyan
    Write-Host "  > .\scripts\start.ps1" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
} else {
    Write-Host "  [XX] Failed to pull model. Check your internet connection." -ForegroundColor Red
    exit 1
}
