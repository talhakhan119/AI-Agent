#!/usr/bin/env bash
# ================================================================
#  Cursor / Agent mode + local Ollama — public tunnel (Option B)
#
#  Cursor routes some requests through its servers; they block private
#  IPs (ssrf_blocked). This exposes Ollama on a temporary HTTPS URL.
#
#  Prereq: Docker stack running (ollama published on OLLAMA_PORT).
#  Prereq: cloudflared — https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
#
#  Usage: ./scripts/start-cursor-tunnel.sh
#         make tunnel-cursor
# ================================================================

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PORT="${OLLAMA_PORT:-11434}"
CF_PROTO="${TUNNEL_TRANSPORT_PROTOCOL:-http2}"
if [[ -f .env ]]; then
  line="$(grep -E '^OLLAMA_PORT=' .env 2>/dev/null | tail -1 || true)"
  if [[ -n "${line}" ]]; then
    PORT="${line#OLLAMA_PORT=}"
    PORT="${PORT//$'\r'/}"
  fi
  pl="$(grep -E '^TUNNEL_TRANSPORT_PROTOCOL=' .env 2>/dev/null | tail -1 || true)"
  if [[ -n "${pl}" ]]; then
    CF_PROTO="${pl#TUNNEL_TRANSPORT_PROTOCOL=}"
    CF_PROTO="${CF_PROTO//$'\r'/}"
  fi
fi

CYAN="\033[1;36m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RESET="\033[0m"

if ! command -v cloudflared &>/dev/null; then
  echo ""
  echo "cloudflared is not installed."
  echo "  Debian/Ubuntu/WSL:  curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o /tmp/cf.deb && sudo dpkg -i /tmp/cf.deb"
  echo "  Or see: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
  echo ""
  exit 1
fi

echo ""
echo -e "${CYAN}=== Cursor tunnel → local Ollama ===${RESET}"
echo -e "  Target: ${GREEN}http://127.0.0.1:${PORT}${RESET}"
echo -e "  Transport: ${GREEN}${CF_PROTO}${RESET} (http2 avoids QUIC/UDP blocked in WSL — see docs/CURSOR-LOCAL.md)"
echo ""
echo -e "${YELLOW}1.${RESET} Wait for a line like: ${GREEN}https://something.trycloudflare.com${RESET}"
echo -e "${YELLOW}2.${RESET} Cursor → Settings → Models:"
echo "     • OpenAI API Key: ON (any non-empty value, e.g. ollama)"
echo "     • Override OpenAI Base URL: ON"
echo -e "     • Base URL: ${GREEN}https://YOUR-SUBDOMAIN.trycloudflare.com/v1${RESET}"
echo -e "${YELLOW}3.${RESET} Keep this terminal open while using Cursor."
echo -e "${YELLOW}4.${RESET} If chat fails with context canceled: run ${CYAN}make warmup-ollama${RESET} first (CPU model load exceeds client timeout)."
echo -e "${YELLOW}5.${RESET} URL changes each run (quick tunnel). For a stable URL use ngrok paid or Cloudflare Named Tunnel."
echo ""
echo -e "${CYAN}Starting cloudflared...${RESET}"
echo ""

exec cloudflared tunnel --protocol "${CF_PROTO}" --url "http://127.0.0.1:${PORT}"
