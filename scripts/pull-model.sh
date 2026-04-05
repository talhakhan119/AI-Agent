#!/usr/bin/env bash
# ================================================================
#  AI Agent — Model Selector & Puller (Linux / macOS)
#  Usage: ./scripts/pull-model.sh
#         ./scripts/pull-model.sh deepseek-r1:14b
# ================================================================

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CYAN="\033[1;36m"; GREEN="\033[1;32m"; YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"; GRAY="\033[0;37m"; RESET="\033[0m"

ok()   { echo -e "  ${GREEN}[OK]${RESET} $1"; }
warn() { echo -e "  ${YELLOW}[!!]${RESET} $1"; }

# ── Model Definitions ─────────────────────────────────────────
declare -A TAGS=( [1]="deepseek-r1:7b"   [2]="deepseek-r1:14b" [3]="deepseek-r1:32b" [4]="deepseek-r1:70b" [5]="deepseek-r1:1.5b" )
declare -A SIZES=([1]="~4.7 GB"           [2]="~9 GB"            [3]="~20 GB"           [4]="~43 GB"          [5]="~1.1 GB" )
declare -A RAM=(  [1]="8 GB RAM"           [2]="16 GB RAM / 8 GB VRAM"  [3]="32 GB RAM / 16 GB VRAM" [4]="64 GB RAM / 24 GB VRAM" [5]="4 GB RAM" )
declare -A GPU=(  [1]="CPU only"           [2]="RTX 3060 8 GB+"   [3]="RTX 3090 / 4080" [4]="RTX 4090 / A100" [5]="Any CPU" )
declare -A BEST=( [1]="Laptops, first test" [2]="Gaming laptops, mid desktops" [3]="Workstations, servers" [4]="High-end servers" [5]="Ultra low-spec, quick tests" )

clear
echo -e "${CYAN}"
cat << 'HEADER'
  DeepSeek R1 — Model Selection
  ================================
  All variants have built-in Chain-of-Thought reasoning (like Claude Thinking).
  Bigger = smarter + slower + more RAM.
HEADER
echo -e "${RESET}"

for i in 1 2 3 4 5; do
    echo -e "  ${YELLOW}[$i]${RESET} ${TAGS[$i]}  ${GRAY}(${SIZES[$i]})${RESET}"
    echo -e "      RAM  : ${RAM[$i]}"
    echo -e "      GPU  : ${GPU[$i]}"
    echo -e "      Best : ${BEST[$i]}"
    echo ""
done

# ── Detect RAM ───────────────────────────────────────────────
if [[ "$(uname)" == "Darwin" ]]; then
    RAM_GB=$(( $(sysctl -n hw.memsize) / 1073741824 ))
else
    RAM_GB=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1048576 ))
fi

echo -e "  ${MAGENTA}Detected system RAM: ${RAM_GB} GB${RESET}"

SUGGESTED=1
[[ $RAM_GB -ge 16 ]] && SUGGESTED=2
[[ $RAM_GB -ge 32 ]] && SUGGESTED=3
[[ $RAM_GB -ge 64 ]] && SUGGESTED=4

echo -e "  ${GREEN}Suggested for your machine: [$SUGGESTED] ${TAGS[$SUGGESTED]}${RESET}"
echo ""

# ── Selection ────────────────────────────────────────────────
if [[ -n "${1:-}" ]]; then
    SELECTED_TAG="$1"
    echo -e "  Using model from argument: ${CYAN}${SELECTED_TAG}${RESET}"
else
    read -rp "  Enter tier number (1-5) or press Enter for [$SUGGESTED]: " CHOICE
    CHOICE="${CHOICE:-$SUGGESTED}"
    if [[ -z "${TAGS[$CHOICE]+_}" ]]; then
        warn "Invalid choice. Using suggested: $SUGGESTED"
        CHOICE="$SUGGESTED"
    fi
    SELECTED_TAG="${TAGS[$CHOICE]}"
fi

echo ""
echo -e "  Selected: ${CYAN}${SELECTED_TAG}${RESET}"

# ── Ensure Ollama is running ──────────────────────────────────
echo ""
echo -e "${CYAN}=== Pulling Model ===${RESET}"

if ! docker ps --filter "name=ai-agent-ollama" --filter "status=running" -q | grep -q .; then
    warn "Ollama container not running. Starting it..."
    docker compose up -d ollama
    sleep 8
fi

echo -e "  Pulling ${SELECTED_TAG} from Ollama registry..."
echo -e "  ${GRAY}(This may take several minutes depending on your connection)${RESET}"
echo ""

docker exec ai-agent-ollama ollama pull "$SELECTED_TAG"

# ── Embedding model ───────────────────────────────────────────
echo ""
echo "  Pulling embedding model (nomic-embed-text, ~274 MB)..."
docker exec ai-agent-ollama ollama pull nomic-embed-text
ok "Embedding model ready"

# ── Update .env ───────────────────────────────────────────────
if [[ -f ".env" ]]; then
    sed -i.bak "s|^OLLAMA_MODEL=.*|OLLAMA_MODEL=${SELECTED_TAG}|" .env
    rm -f .env.bak
    ok "Updated OLLAMA_MODEL in .env to ${SELECTED_TAG}"
fi

# ── Update Continue.dev config ────────────────────────────────
CONTINUE_CFG="config/continue/config.json"
if command -v python3 &>/dev/null; then
    python3 - <<PYEOF
import json, re
with open("${CONTINUE_CFG}", "r") as f:
    cfg = json.load(f)
for m in cfg.get("models", []):
    m["model"] = "${SELECTED_TAG}"
if "tabAutocompleteModel" in cfg:
    cfg["tabAutocompleteModel"]["model"] = "${SELECTED_TAG}"
with open("${CONTINUE_CFG}", "w") as f:
    json.dump(cfg, f, indent=2)
print("  \033[1;32m[OK]\033[0m Updated config/continue/config.json to use ${SELECTED_TAG}")
PYEOF
fi

echo ""
echo -e "${CYAN}================================================================${RESET}"
echo -e "  Model ready! Start the full stack with:"
echo -e "  ${YELLOW}./scripts/start.sh${RESET}"
echo -e "${CYAN}================================================================${RESET}"
echo ""
