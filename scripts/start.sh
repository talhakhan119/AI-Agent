#!/usr/bin/env bash
# ================================================================
#  AI Agent — Start Stack (Linux / macOS)
#  Usage: ./scripts/start.sh
#         ./scripts/start.sh --gpu     (NVIDIA GPU support)
# ================================================================

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CYAN="\033[1;36m"; GREEN="\033[1;32m"; YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"; GRAY="\033[0;37m"; RESET="\033[0m"

header() { echo -e "\n${CYAN}=== $1 ===${RESET}"; }
ok()     { echo -e "  ${GREEN}[OK]${RESET} $1"; }
warn()   { echo -e "  ${YELLOW}[!!]${RESET} $1"; }

GPU=false
for arg in "$@"; do
    [[ "$arg" == "--gpu" ]] && GPU=true
done

echo ""
echo -e "  ${CYAN}Starting AI Agent Stack...${RESET}"

# ── .env check ───────────────────────────────────────────────
if [[ ! -f ".env" ]]; then
    warn ".env not found — running setup first"
    bash "$ROOT/scripts/setup.sh"
fi

# ── Source port from .env ─────────────────────────────────────
WEBUI_PORT=$(grep "^WEBUI_PORT=" .env 2>/dev/null | cut -d= -f2 || echo "3000")
MODEL=$(grep "^OLLAMA_MODEL=" .env 2>/dev/null | cut -d= -f2 || echo "not set")

# ── Start containers ──────────────────────────────────────────
header "Launching Containers"

if [[ "$GPU" == "true" ]]; then
    echo -e "  ${MAGENTA}Mode: GPU (NVIDIA)${RESET}"
    docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
else
    echo -e "  Mode: CPU"
    docker compose up -d
fi

# ── Wait for Open WebUI ───────────────────────────────────────
header "Waiting for Services"
echo -e "  Waiting for Open WebUI on port ${WEBUI_PORT}..."

MAX=30; N=0
until curl -sf "http://localhost:${WEBUI_PORT}" > /dev/null 2>&1; do
    N=$((N+1))
    [[ $N -ge $MAX ]] && { warn "Timeout — check 'docker compose logs open-webui'"; break; }
    echo -e "  ${GRAY}Attempt ${N}/${MAX}...${RESET}"
    sleep 3
done

# ── Status ────────────────────────────────────────────────────
header "Service Status"
docker compose ps

echo ""
echo -e "${GREEN}================================================================${RESET}"
echo -e "  ${GREEN}AI Agent is running!${RESET}"
echo ""
echo -e "  Open WebUI  :  ${CYAN}http://localhost:${WEBUI_PORT}${RESET}"
echo -e "  Ollama API  :  ${CYAN}http://localhost:11434${RESET}"
echo -e "  SearXNG     :  ${CYAN}http://localhost:8080${RESET}"
echo -e "  Model       :  ${YELLOW}${MODEL}${RESET}"
echo ""
echo -e "  Stop with   :  ${YELLOW}./scripts/stop.sh${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo ""

# ── Open browser (Linux/macOS) ────────────────────────────────
if command -v xdg-open &>/dev/null; then
    xdg-open "http://localhost:${WEBUI_PORT}" 2>/dev/null &
elif command -v open &>/dev/null; then
    open "http://localhost:${WEBUI_PORT}"
fi
