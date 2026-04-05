#!/usr/bin/env bash
# ================================================================
#  AI Agent — First-Time Setup (Linux / macOS)
#  Run once after cloning the repo
#  Usage: chmod +x scripts/*.sh && ./scripts/setup.sh
# ================================================================

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# ── Colors ───────────────────────────────────────────────────
CYAN="\033[1;36m"; GREEN="\033[1;32m"; YELLOW="\033[1;33m"
RED="\033[1;31m"; GRAY="\033[0;37m"; RESET="\033[0m"

header() { echo -e "\n${CYAN}=== $1 ===${RESET}"; }
ok()     { echo -e "  ${GREEN}[OK]${RESET} $1"; }
warn()   { echo -e "  ${YELLOW}[!!]${RESET} $1"; }
fail()   { echo -e "  ${RED}[XX]${RESET} $1"; }

clear
echo -e "${CYAN}"
cat << 'LOGO'
  ___  ____     ___                    _
 / _ \|  _ \   / _ \__      _____ _ __ | |_
| | | | |_) | | | | \ \ /\ / / _ \ '__|| __|
| |_| |  __/  | |_| |\ V  V /  __/ |   | |_
 \__\_\_|      \___/  \_/\_/ \___|_|    \__|

  Local AI Agent Setup — Linux / macOS
LOGO
echo -e "${RESET}"

# ── 1. Docker check ──────────────────────────────────────────
header "Checking Prerequisites"

if ! command -v docker &>/dev/null; then
    fail "Docker is not installed."
    echo "  Install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
ok "Docker found: $(docker --version)"

if ! docker info &>/dev/null; then
    fail "Docker daemon is not running. Please start Docker and retry."
    exit 1
fi
ok "Docker daemon is running"

if ! docker compose version &>/dev/null; then
    fail "docker compose plugin not found. Update Docker Desktop or install it."
    exit 1
fi
ok "Docker Compose found"

# ── 2. .env file ─────────────────────────────────────────────
header "Environment Configuration"

if [[ -f ".env" ]]; then
    warn ".env already exists — skipping (delete it to regenerate)"
else
    cp .env.example .env
    ok ".env created from .env.example"
fi

# Generate WEBUI_SECRET_KEY if still default
# (Avoid tr|head under pipefail — head closes the pipe and tr exits 141/SIGPIPE.)
if grep -q "change-me-to-a-long-random-string" .env; then
    if ! command -v openssl &>/dev/null; then
        fail "openssl not found — install it (e.g. sudo apt install openssl) to generate secrets"
        exit 1
    fi
    NEW_KEY=$(openssl rand -hex 24)
    sed -i.bak "s|WEBUI_SECRET_KEY=.*|WEBUI_SECRET_KEY=${NEW_KEY}|" .env
    rm -f .env.bak
    ok "Generated WEBUI_SECRET_KEY"
else
    warn "WEBUI_SECRET_KEY already set — keeping existing value"
fi

# ── 3. SearXNG secret key ─────────────────────────────────────
header "Configuring SearXNG"

SEARX_FILE="config/searxng/settings.yml"
if grep -q "change-me-replaced-by-setup-script" "$SEARX_FILE"; then
    if ! command -v openssl &>/dev/null; then
        fail "openssl not found — install it (e.g. sudo apt install openssl) to generate secrets"
        exit 1
    fi
    SEARX_KEY=$(openssl rand -hex 16)
    sed -i.bak "s|change-me-replaced-by-setup-script|${SEARX_KEY}|" "$SEARX_FILE"
    rm -f "${SEARX_FILE}.bak"
    ok "Generated SearXNG secret key"
else
    warn "SearXNG secret key already set"
fi

# ── 4. Script permissions ─────────────────────────────────────
header "Setting Script Permissions"
chmod +x scripts/*.sh
ok "All shell scripts are executable"

# ── 5. Continue.dev for VSCode / Cursor ──────────────────────
header "VSCode / Cursor Integration (Continue.dev)"

CONTINUE_SRC="config/continue/config.json"
CONTINUE_DIRS=(
    "$HOME/.continue"
    "$HOME/Library/Application Support/Code/User/globalStorage/continue.continue"
    "$HOME/.config/Code/User/globalStorage/continue.continue"
)

INSTALLED=false
for DST_DIR in "${CONTINUE_DIRS[@]}"; do
    if [[ -d "$DST_DIR" ]]; then
        DST_FILE="$DST_DIR/config.json"
        if [[ -f "$DST_FILE" ]]; then
            cp "$DST_FILE" "${DST_FILE}.bak"
            warn "Backed up existing config to ${DST_FILE}.bak"
        fi
        cp "$CONTINUE_SRC" "$DST_FILE"
        ok "Installed Continue.dev config -> $DST_FILE"
        INSTALLED=true
    fi
done

if [[ "$INSTALLED" == "false" ]]; then
    warn "Continue.dev not detected. After installing it:"
    echo "  Copy config/continue/config.json to ~/.continue/config.json"
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}================================================================${RESET}"
echo -e "  Setup complete! Next steps:"
echo ""
echo -e "  1. Pull a model  :  ${YELLOW}./scripts/pull-model.sh${RESET}"
echo -e "  2. Start stack   :  ${YELLOW}./scripts/start.sh${RESET}"
echo -e "  3. Open browser  :  ${CYAN}http://localhost:3000${RESET}"
echo -e "${CYAN}================================================================${RESET}"
echo ""
