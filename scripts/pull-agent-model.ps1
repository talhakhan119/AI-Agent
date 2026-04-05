# ================================================================
#  Pull Ollama model with tool calling — Cursor Agent (Windows)
#  Usage: .\scripts\pull-agent-model.ps1
#         .\scripts\pull-agent-model.ps1 qwen3:4b
# ================================================================

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$model = if ($args[0]) { $args[0] } else { "qwen3:8b" }

Write-Host ""
Write-Host "  Cursor Agent — tool-calling model" -ForegroundColor Cyan
Write-Host "  Pulling: $model"
Write-Host ""

$running = docker ps --filter "name=ai-agent-ollama" --filter "status=running" -q
if (-not $running) {
    Write-Host "  Starting Ollama container..." -ForegroundColor Yellow
    docker compose up -d ollama
    Start-Sleep -Seconds 8
}

docker exec ai-agent-ollama ollama pull $model

$envFile = Join-Path $Root ".env"
if (Test-Path $envFile) {
    $lines = Get-Content $envFile
    $found = $false
    $newLines = foreach ($line in $lines) {
        if ($line -match '^\s*CURSOR_AGENT_MODEL=') {
            $found = $true
            "CURSOR_AGENT_MODEL=$model"
        } else { $line }
    }
    if (-not $found) {
        $newLines = $newLines + "" + "# Model for Cursor Agent (tool calling)" + "CURSOR_AGENT_MODEL=$model"
    }
    $newLines | Set-Content $envFile
    Write-Host "  [OK] Saved CURSOR_AGENT_MODEL in .env" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next: run start-cursor-tunnel.ps1, set Cursor Base URL, add model $model, use Agent mode." -ForegroundColor Cyan
Write-Host ""
