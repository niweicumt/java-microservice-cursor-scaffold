#!/usr/bin/env bash
# 仅调整骨架默认组织前缀（fork 骨架后、创建具体业务服务前使用）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/skeleton-config.sh
source "${SCRIPT_DIR}/lib/skeleton-config.sh"
# shellcheck source=lib/apply-skeleton-identity.sh
source "${SCRIPT_DIR}/lib/apply-skeleton-identity.sh"

ROOT="$(cd "${SCRIPT_DIR}/../../java-microservice-scaffold" && pwd)"

NEW_BASE_PACKAGE=""
NEW_GROUP_ID=""
NEW_MODULE_NAME=""

usage() {
  cat <<'EOF'
Usage: ./scripts/configure-skeleton.sh [options]

在 fork 骨架后，将默认组织前缀（如 com.s3）改为团队自己的前缀，模块名默认保持 skeleton。

  --base-package com.acme.skeleton   新根包（必填）
  --group-id com.acme                  新 Maven groupId（可选，默认取 base-package 去掉末段）
  --module-name skeleton               模块名/主类前缀（可选，默认取 base-package 末段）

当前骨架标识请查看: skeleton.defaults.json

Example（将 com.s3.skeleton 改为 com.acme.skeleton）:
  ./scripts/configure-skeleton.sh \
    --base-package com.acme.skeleton \
    --group-id com.acme
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-package) NEW_BASE_PACKAGE="$2"; shift 2 ;;
    --group-id) NEW_GROUP_ID="$2"; shift 2 ;;
    --module-name) NEW_MODULE_NAME="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$NEW_BASE_PACKAGE" ]]; then
  echo "Error: --base-package is required."
  usage
  exit 1
fi

load_skeleton_config "$ROOT"

if [[ -z "$NEW_GROUP_ID" ]]; then
  NEW_GROUP_ID="$(derive_group_id "$NEW_BASE_PACKAGE")"
fi

if [[ -z "$NEW_MODULE_NAME" ]]; then
  NEW_MODULE_NAME="${NEW_BASE_PACKAGE##*.}"
fi

apply_skeleton_identity \
  "$ROOT" \
  "$BASE_PACKAGE" "$GROUP_ID" "$ARTIFACT_ID" "$APP_NAME" "$MODULE_NAME" \
  "$DB_DEV" "$DB_TEST" "$DB_UAT" "$DB_PRE" "$DB_PROD" \
  "$NEW_BASE_PACKAGE" "$NEW_GROUP_ID" "$ARTIFACT_ID" "$APP_NAME" "$NEW_MODULE_NAME" \
  "$DB_DEV" "$DB_TEST" "$DB_UAT" "$DB_PRE" "$DB_PROD"

echo "Next: mvn clean test"
echo "Cursor rules installed under skeleton-service/.cursor/rules/ (see shared/scripts/lib/copy-cursor-rules.sh)"
echo "创建具体业务服务时，再执行 ./shared/scripts/rename-skeleton.sh --package <新包> --artifact <新服务>"
