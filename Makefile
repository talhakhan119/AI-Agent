# ================================================================
#  AI Agent — Makefile (Linux / macOS shortcut)
#  Usage: make setup | make pull | make start | make stop
#
#  On Windows: use .\scripts\*.ps1 instead
#  On Linux/macOS: you can also call ./scripts/*.sh directly
# ================================================================

.PHONY: setup pull start start-gpu stop stop-purge status logs tunnel-cursor help

# Default target
help:
	@echo ""
	@echo "  AI Agent — Available commands:"
	@echo ""
	@echo "  make setup        First-time setup (generates secrets, installs configs)"
	@echo "  make pull         Interactive model picker (pulls DeepSeek R1)"
	@echo "  make start        Start all services (CPU mode)"
	@echo "  make start-gpu    Start all services (NVIDIA GPU mode)"
	@echo "  make stop         Stop all services (keeps data)"
	@echo "  make stop-purge   Stop and delete ALL data (irreversible)"
	@echo "  make status       Show running container status"
	@echo "  make logs         Follow live logs from all services"
	@echo "  make tunnel-cursor  Cloudflare tunnel for Cursor (fixes ssrf_blocked on localhost)"
	@echo ""

setup:
	@chmod +x scripts/*.sh
	@./scripts/setup.sh

pull:
	@chmod +x scripts/*.sh
	@./scripts/pull-model.sh

start:
	@chmod +x scripts/*.sh
	@./scripts/start.sh

start-gpu:
	@chmod +x scripts/*.sh
	@./scripts/start.sh --gpu

stop:
	@./scripts/stop.sh

stop-purge:
	@./scripts/stop.sh --purge

status:
	@docker compose ps

logs:
	@docker compose logs -f

tunnel-cursor:
	@chmod +x scripts/*.sh
	@./scripts/start-cursor-tunnel.sh
