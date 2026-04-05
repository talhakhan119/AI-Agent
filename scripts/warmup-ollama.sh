#!/usr/bin/env bash
# ================================================================
#  Load a model into RAM before Cursor/tunnel calls (avoids timeouts)
#
#  Cursor + Cloudflare close long requests (~30-35s). Cold-loading
#  qwen3:8b on CPU often exceeds that, causing context canceled / HTTP 499.
#
#  Run after: docker compose up -d ollama
#  Run before: starting tunnel + using Cursor
#
#  Usage: ./scripts/warmup-ollama.sh
#         ./scripts/warmup-ollama.sh qwen3:8b
#         make warmup-ollama
# ================================================================

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODEL="${1:-}"
if [[ -z "$MODEL" ]] && [[ -f .env ]]; then
  MODEL="$(grep -E '^CURSOR_AGENT_MODEL=' .env 2>/dev/null | tail -1 | cut -d= -f2- | tr -d '\r' || true)"
fi
if [[ -z "$MODEL" ]]; then
  MODEL="${OLLAMA_MODEL:-qwen3:8b}"
fi

CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

if ! docker ps --filter "name=ai-agent-ollama" --filter "status=running" -q | grep -q .; then
  echo -e "${YELLOW}Starting Ollama...${RESET}"
  docker compose up -d ollama
  sleep 5
fi

echo -e "${CYAN}Warming up Ollama model:${RESET} ${GREEN}${MODEL}${RESET}"
echo -e "${YELLOW}On CPU this can take 1-3 minutes the first time.${RESET}"
echo ""

docker exec ai-agent-ollama ollama run "$MODEL" "Reply with exactly: OK"

echo ""
echo -e "${GREEN}[OK]${RESET} Model is loaded. Start tunnel + Cursor."
echo -e "  Tip: set ${CYAN}OLLAMA_KEEP_ALIVE=-1${RESET} in .env to keep it in RAM."
echo ""
