#!/usr/bin/env bash
# 从骨架创建新服务：读取 skeleton.defaults.json 中的当前标识，替换为新服务标识
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/skeleton-config.sh
source "${SCRIPT_DIR}/lib/skeleton-config.sh"
# shellcheck source=lib/apply-skeleton-identity.sh
source "${SCRIPT_DIR}/lib/apply-skeleton-identity.sh"

ROOT="$(cd "${SCRIPT_DIR}/../../java-microservice-scaffold" && pwd)"

NEW_PACKAGE=""
NEW_ARTIFACT=""
NEW_APP_NAME=""
NEW_DB_NAME=""
NEW_GROUP_ID=""

usage() {
  cat <<'EOF'
Usage: ./scripts/rename-skeleton.sh [options]

从当前骨架标识（见 skeleton.defaults.json）替换为新服务标识。

  --package com.acme.order      新 Java 根包（必填）
  --artifact order-service      新 Maven artifactId（必填）
  --group-id com.acme             新 Maven groupId（可选，默认取 package 去掉末段）
  --app-name order-service        新 spring.application.name（默认与 artifact 相同）
  --db-name order_dev             新 dev 默认库名（默认: <artifact>_dev）

当前骨架标识请查看: skeleton.defaults.json

Example:
  ./scripts/rename-skeleton.sh \
    --package com.acme.order \
    --group-id com.acme \
    --artifact order-service \
    --db-name order_dev
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package) NEW_PACKAGE="$2"; shift 2 ;;
    --artifact) NEW_ARTIFACT="$2"; shift 2 ;;
    --group-id) NEW_GROUP_ID="$2"; shift 2 ;;
    --app-name) NEW_APP_NAME="$2"; shift 2 ;;
    --db-name) NEW_DB_NAME="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$NEW_PACKAGE" || -z "$NEW_ARTIFACT" ]]; then
  echo "Error: --package and --artifact are required."
  usage
  exit 1
fi

load_skeleton_config "$ROOT"

if [[ -z "$NEW_APP_NAME" ]]; then
  NEW_APP_NAME="$NEW_ARTIFACT"
fi

if [[ -z "$NEW_DB_NAME" ]]; then
  NEW_DB_NAME="${NEW_ARTIFACT//-/_}_dev"
fi

if [[ -z "$NEW_GROUP_ID" ]]; then
  NEW_GROUP_ID="$(derive_group_id "$NEW_PACKAGE")"
fi

NEW_MODULE_NAME="${NEW_PACKAGE##*.}"
NEW_DB_TEST="${NEW_ARTIFACT//-/_}_test"
NEW_DB_UAT="${NEW_ARTIFACT//-/_}_uat"
NEW_DB_PRE="${NEW_ARTIFACT//-/_}_pre"
NEW_DB_PROD="${NEW_ARTIFACT//-/_}_prod"

apply_skeleton_identity \
  "$ROOT" \
  "$BASE_PACKAGE" "$GROUP_ID" "$ARTIFACT_ID" "$APP_NAME" "$MODULE_NAME" \
  "$DB_DEV" "$DB_TEST" "$DB_UAT" "$DB_PRE" "$DB_PROD" \
  "$NEW_PACKAGE" "$NEW_GROUP_ID" "$NEW_ARTIFACT" "$NEW_APP_NAME" "$NEW_MODULE_NAME" \
  "$NEW_DB_NAME" "$NEW_DB_TEST" "$NEW_DB_UAT" "$NEW_DB_PRE" "$NEW_DB_PROD"

echo "Next: mvn clean test"
echo "Cursor rules: skeleton-service/.cursor/rules/ (auto-installed)"
