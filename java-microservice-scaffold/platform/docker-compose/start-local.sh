#!/usr/bin/env bash
# 一键启动本地联调基础设施（Nacos / MySQL / Kafka / Redis）
# 注意：mvn test 使用 H2，无需运行本脚本。见 docs/DEPLOYMENT.md §3.4
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.local.yml"

echo "==> Starting local infrastructure (docker-compose.local.yml)..."
docker compose -f "${COMPOSE_FILE}" up -d

echo ""
echo "==> Status:"
docker compose -f "${COMPOSE_FILE}" ps

cat <<'EOF'

==> Local endpoints
  Nacos   http://localhost:8848/nacos     (nacos / nacos)
  MySQL   localhost:3306                  (root / root, db: cursor-demo)
  Kafka   localhost:9092
  Redis   localhost:6379                  (password: root)

==> Next steps
  • mvn test：无需本脚本，单测使用 H2（见 docs/DEPLOYMENT.md §3.4）
  • 联调启动（MySQL + Compose）：
    1. cd java-microservice-common && mvn clean install
    2. ./platform/docker-compose/start-local.sh
    3. mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev
    4. 启动 gateway-service（见 docs/DEPLOYMENT.md §5）

EOF
