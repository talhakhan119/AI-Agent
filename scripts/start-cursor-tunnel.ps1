# ================================================================
#  Cursor / Agent mode + local Ollama — public tunnel (Option B)
#
#  Run from Windows PowerShell (Docker Desktop exposes Ollama on localhost).
#
#  Prereq: cloudflared for Windows:
#    https://github.com/cloudflare/cloudflared/releases
#    (download cloudflared-windows-amd64.exe, rename to cloudflared.exe, add to PATH)
#
#  Usage: .\scripts\start-cursor-tunnel.ps1
# ================================================================

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$port = 11434
$cfProto = if ($env:TUNNEL_TRANSPORT_PROTOCOL) { $env:TUNNEL_TRANSPORT_PROTOCOL } else { "http2" }
$envFile = Join-Path $Root ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*OLLAMA_PORT\s*=\s*(\d+)\s*$') {
            $port = [int]$Matches[1]
        }
        if ($_ -match '^\s*TUNNEL_TRANSPORT_PROTOCOL\s*=\s*(\S+)\s*$') {
            $cfProto = $Matches[1].Trim()
        }
    }
}

$cf = Get-Command cloudflared -ErrorAction SilentlyContinue
if (-not $cf) {
    Write-Host ""
    Write-Host "cloudflared not found in PATH."
    Write-Host "  Download: https://github.com/cloudflare/cloudflared/releases"
    Write-Host "  Add cloudflared.exe to PATH, then re-run this script."
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "=== Cursor tunnel -> local Ollama ===" -ForegroundColor Cyan
Write-Host "  Target: http://127.0.0.1:$port" -ForegroundColor Green
Write-Host "  Transport: $cfProto (http2 avoids QUIC/UDP issues in WSL)" -ForegroundColor Green
Write-Host ""
Write-Host "1. Wait for: https://....trycloudflare.com" -ForegroundColor Yellow
Write-Host "2. Cursor -> Settings -> Models -> Override OpenAI Base URL:"
Write-Host "   https://YOUR-SUBDOMAIN.trycloudflare.com/v1" -ForegroundColor Green
Write-Host "3. Keep this window open while using Cursor." -ForegroundColor Yellow
Write-Host ""

& cloudflared tunnel --protocol $cfProto --url "http://127.0.0.1:$port"
