#!/usr/bin/env bash
# 停止本地开发基础设施
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.local.yml"

ACTION="${1:-down}"

case "${ACTION}" in
  stop)
    docker compose -f "${COMPOSE_FILE}" stop
    ;;
  down)
    docker compose -f "${COMPOSE_FILE}" down
    ;;
  clean)
    echo "Warning: this removes volumes (MySQL/Nacos/Redis data)." >&2
    docker compose -f "${COMPOSE_FILE}" down -v
    ;;
  *)
    echo "Usage: $0 [stop|down|clean]" >&2
    exit 1
    ;;
esac

docker compose -f "${COMPOSE_FILE}" ps 2>/dev/null || true
