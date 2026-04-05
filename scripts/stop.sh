#!/usr/bin/env bash
# ================================================================
#  AI Agent — Stop Stack (Linux / macOS)
#  Usage: ./scripts/stop.sh
#         ./scripts/stop.sh --purge    (also removes volumes/data)
# ================================================================

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

YELLOW="\033[1;33m"; RED="\033[1;31m"; GREEN="\033[1;32m"
CYAN="\033[1;36m"; GRAY="\033[0;37m"; RESET="\033[0m"

echo ""
echo -e "  ${YELLOW}Stopping AI Agent Stack...${RESET}"

PURGE=false
for arg in "$@"; do
    [[ "$arg" == "--purge" ]] && PURGE=true
done

if [[ "$PURGE" == "true" ]]; then
    echo -e "  ${RED}WARNING: --purge will delete all conversation history and model data!${RESET}"
    read -rp "  Type 'yes' to confirm: " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        echo -e "  ${GRAY}Aborted.${RESET}"
        exit 0
    fi
    docker compose down -v
    echo -e "  ${GREEN}[OK]${RESET} All containers and volumes removed."
else
    docker compose down
    echo -e "  ${GREEN}[OK]${RESET} Containers stopped. Data volumes preserved."
    echo -e "  ${GRAY}(Use --purge to also delete all data)${RESET}"
fi

echo ""
echo -e "  ${CYAN}Resources freed. CPU and RAM usage dropped to zero.${RESET}"
echo ""
