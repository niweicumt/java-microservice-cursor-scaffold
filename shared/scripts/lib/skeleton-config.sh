#!/usr/bin/env bash
# 读取 / 写入 skeleton.defaults.json（骨架标识单一事实来源）
set -euo pipefail

SKELETON_CONFIG_FILE="${SKELETON_CONFIG_FILE:-skeleton.defaults.json}"

_skeleton_config_path() {
  local root="${1:-.}"
  echo "${root%/}/${SKELETON_CONFIG_FILE}"
}

load_skeleton_config() {
  local root="${1:-.}"
  local config_file
  config_file="$(_skeleton_config_path "$root")"
  if [[ ! -f "$config_file" ]]; then
    echo "Error: config not found: $config_file" >&2
    return 1
  fi
  eval "$(python3 - "$config_file" <<'PY'
import json, shlex, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
dbs = data.get("databases", {})
module = data.get("moduleName", data["basePackage"].split(".")[-1])
fields = {
    "BASE_PACKAGE": data["basePackage"],
    "GROUP_ID": data["groupId"],
    "ARTIFACT_ID": data["artifactId"],
    "APP_NAME": data["appName"],
    "MODULE_NAME": module,
    "DB_DEV": dbs.get("dev", "app_dev"),
    "DB_TEST": dbs.get("test", "app_test"),
    "DB_UAT": dbs.get("uat", "app_uat"),
    "DB_PRE": dbs.get("pre", "app_pre"),
    "DB_PROD": dbs.get("prod", "app_prod"),
}
for key, value in fields.items():
    print(f"{key}={shlex.quote(str(value))}")
PY
)"
  BASE_PATH="${BASE_PACKAGE//.//}"
}

derive_group_id() {
  local package_name="$1"
  if [[ "$package_name" != *.* ]]; then
    echo "$package_name"
    return
  fi
  echo "${package_name%.*}"
}

capitalize() {
  echo "$1" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}'
}

save_skeleton_config() {
  local root="${1:-.}"
  local config_file
  config_file="$(_skeleton_config_path "$root")"
  python3 - "$config_file" \
    "$BASE_PACKAGE" "$GROUP_ID" "$ARTIFACT_ID" "$APP_NAME" "$MODULE_NAME" \
    "$DB_DEV" "$DB_TEST" "$DB_UAT" "$DB_PRE" "$DB_PROD" <<'PY'
import json, sys
path = sys.argv[1]
data = {
    "basePackage": sys.argv[2],
    "groupId": sys.argv[3],
    "artifactId": sys.argv[4],
    "appName": sys.argv[5],
    "moduleName": sys.argv[6],
    "databases": {
        "dev": sys.argv[7],
        "test": sys.argv[8],
        "uat": sys.argv[9],
        "pre": sys.argv[10],
        "prod": sys.argv[11],
    },
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
}
