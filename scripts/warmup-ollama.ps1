# ================================================================
#  Load a model into RAM before Cursor (avoids tunnel/client timeouts)
#  Usage: .\scripts\warmup-ollama.ps1
#         .\scripts\warmup-ollama.ps1 qwen3:8b
# ================================================================

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$model = $args[0]
if (-not $model -and (Test-Path (Join-Path $Root ".env"))) {
    Get-Content (Join-Path $Root ".env") | ForEach-Object {
        if ($_ -match '^\s*CURSOR_AGENT_MODEL\s*=\s*(.+)$') { $model = $Matches[1].Trim() }
    }
}
if (-not $model) { $model = "qwen3:8b" }

$running = docker ps --filter "name=ai-agent-ollama" --filter "status=running" -q 2>$null
if (-not $running) {
    Write-Host "Starting Ollama..." -ForegroundColor Yellow
    docker compose up -d ollama
    Start-Sleep -Seconds 5
}

Write-Host "Warming up: $model (CPU may take 1–3 min)..." -ForegroundColor Cyan
docker exec ai-agent-ollama ollama run $model "Reply with exactly: OK"
Write-Host "[OK] Model loaded. Start tunnel + Cursor." -ForegroundColor Green
