#!/usr/bin/env bash
# 同时修改 common 与 scaffold 的组织前缀（如 com.s3 -> com.tm / com.ljy）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/package-identity.sh
source "${SCRIPT_DIR}/lib/package-identity.sh"

NEW_ORG=""
CONFIG_FILE="${SCRIPT_DIR}/../package.defaults.json"
AUTO_YES=false

usage() {
  cat <<'EOF'
Usage: ./shared/scripts/configure-organization.sh --org <prefix> [--yes]

一次性修改三个独立工程中的 Java 包路径与 Maven groupId：
  - java-microservice-common/   （com.s3.common.* -> com.tm.common.*）
  - java-microservice-gateway/  （com.s3.gateway.* -> com.tm.gateway.*）
  - java-microservice-scaffold/ （com.s3.skeleton.* -> com.tm.skeleton.*）

  --org com.tm          新组织前缀（必填，如 com.tm、com.ljy）
  --config <file>       package.defaults.json 路径（可选）
  --yes                 跳过确认提示（CI / 自动化）

Example:
  ./shared/scripts/configure-organization.sh --org com.tm

完成后:
  cd java-microservice-common && mvn clean install
  cd ../java-microservice-scaffold && mvn clean test
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) NEW_ORG="$2"; shift 2 ;;
    --config) CONFIG_FILE="$2"; shift 2 ;;
    --yes) AUTO_YES=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$NEW_ORG" ]]; then
  echo "Error: --org is required." >&2
  usage
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: config not found: $CONFIG_FILE" >&2
  exit 1
fi

OLD_ORG="$(python3 - "$CONFIG_FILE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    print(json.load(f)["organizationPrefix"])
PY
)"

if [[ "$OLD_ORG" == "$NEW_ORG" ]]; then
  echo "Organization prefix unchanged: ${OLD_ORG}"
  exit 0
fi

echo "Current organization: ${OLD_ORG}"
echo "New organization:     ${NEW_ORG}"
if [[ "$AUTO_YES" != true ]]; then
  read -r -p "Continue? [y/N] " confirm
  if [[ "${confirm,,}" != "y" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

apply_organization_prefix "$OLD_ORG" "$NEW_ORG"
