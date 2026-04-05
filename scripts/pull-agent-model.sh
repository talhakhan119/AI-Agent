#!/usr/bin/env bash
# ================================================================
#  Pull Ollama model with tool calling — for Cursor / VS Code AGENT mode
#
#  deepseek-r1 does NOT support tools; Cursor Agent / Ask need tool-calling models.
#  Default: qwen3:8b — Ollama lists Qwen3 with tools + thinking (~5.2 GB).
#  Alternatives: qwen3:4b (lighter), llama3.1:8b, qwen3:14b (more RAM).
#
#  Usage: ./scripts/pull-agent-model.sh
#         ./scripts/pull-agent-model.sh qwen3:4b
#         ./scripts/pull-agent-model.sh llama3.1:8b
# ================================================================

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CYAN="\033[1;36m"; GREEN="\033[1;32m"; YELLOW="\033[1;33m"; GRAY="\033[0;37m"; RESET="\033[0m"
warn() { echo -e "  ${YELLOW}[!!]${RESET} $1"; }
ok()   { echo -e "  ${GREEN}[OK]${RESET} $1"; }

MODEL="${1:-qwen3:8b}"

echo -e "${CYAN}"
cat << EOF
  Cursor Agent — tool-calling model
  =================================
  Pulling: ${MODEL}
  (Use this model name in Cursor → Settings → Models → Add custom model)
EOF
echo -e "${RESET}"

if ! docker ps --filter "name=ai-agent-ollama" --filter "status=running" -q | grep -q .; then
    warn "Ollama container not running. Starting it..."
    docker compose up -d ollama
    sleep 8
fi

echo -e "${GRAY}Downloading… (large file)${RESET}"
docker exec ai-agent-ollama ollama pull "$MODEL"

if [[ -f .env ]]; then
    if grep -q '^CURSOR_AGENT_MODEL=' .env; then
        sed -i.bak "s|^CURSOR_AGENT_MODEL=.*|CURSOR_AGENT_MODEL=${MODEL}|" .env && rm -f .env.bak
    else
        echo "" >> .env
        echo "# Model for Cursor Agent (tool calling); add this name in Cursor Models" >> .env
        echo "CURSOR_AGENT_MODEL=${MODEL}" >> .env
    fi
    ok "Saved CURSOR_AGENT_MODEL=${MODEL} in .env"
fi

echo ""
ok "Done."
echo ""
echo -e "${CYAN}Next (Cursor):${RESET}"
echo "  1. Tunnel:  ./scripts/start-cursor-tunnel.sh  (leave running)"
echo "  2. Settings → Models → Base URL = https://YOUR.trycloudflare.com/v1"
echo -e "  3. Add custom model: ${GREEN}${MODEL}${RESET} — enable it"
echo "  4. New chat → mode ${GREEN}Agent${RESET} (not Chat-only)"
echo ""
echo -e "${GRAY}Keep deepseek-r1:7b for reasoning chat in Open WebUI or Cursor Chat.${RESET}"
echo ""
