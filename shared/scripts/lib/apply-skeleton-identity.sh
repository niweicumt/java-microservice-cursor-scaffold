#!/usr/bin/env bash
# 脚手架业务服务标识替换（skeleton-service 模块内）
set -euo pipefail

_APPLY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=skeleton-config.sh
source "${_APPLY_LIB_DIR}/skeleton-config.sh"
# shellcheck source=copy-cursor-rules.sh
source "${_APPLY_LIB_DIR}/copy-cursor-rules.sh"

apply_skeleton_identity() {
  local root="$1"
  local old_package="$2"
  local old_group_id="$3"
  local old_artifact="$4"
  local old_app_name="$5"
  local old_module_name="$6"
  local old_db_dev="$7"
  local old_db_test="$8"
  local old_db_uat="$9"
  local old_db_pre="${10}"
  local old_db_prod="${11}"

  local new_package="${12}"
  local new_group_id="${13}"
  local new_artifact="${14}"
  local new_app_name="${15}"
  local new_module_name="${16}"
  local new_db_dev="${17}"
  local new_db_test="${18}"
  local new_db_uat="${19}"
  local new_db_pre="${20}"
  local new_db_prod="${21}"

  local service_module="skeleton-service"
  local old_path="${old_package//.//}"
  local new_path="${new_package//.//}"
  local main_base="${root}/${service_module}/src/main/java"
  local test_base="${root}/${service_module}/src/test/java"

  cd "$root"

  if [[ ! -d "${main_base}/${old_path}" ]]; then
    echo "Error: package directory not found: ${main_base}/${old_path}" >&2
    return 1
  fi

  echo "==> Moving Java packages: ${old_package} -> ${new_package}"
  mkdir -p "${main_base}/$(dirname "$new_path")"
  mv "${main_base}/${old_path}" "${main_base}/${new_path}"
  mkdir -p "${test_base}/$(dirname "$new_path")"
  if [[ -d "${test_base}/${old_path}" ]]; then
    mv "${test_base}/${old_path}" "${test_base}/${new_path}"
  fi

  _replace_in_files() {
    local old="$1"
    local new="$2"
    if [[ "$old" == "$new" || -z "$old" ]]; then
      return
    fi
    find . -type f \( -name '*.java' -o -name '*.xml' -o -name '*.yml' -o -name '*.yaml' -o -name '*.md' -o -name '*.mdc' \) \
      ! -path './target/*' ! -path './.git/*' ! -path './examples/*' ! -path '../shared/*' \
      -exec grep -l "${old}" {} + 2>/dev/null | while read -r f; do
        if [[ "$(uname)" == "Darwin" ]]; then
          sed -i '' "s|${old}|${new}|g" "$f"
        else
          sed -i "s|${old}|${new}|g" "$f"
        fi
      done
  }

  echo "==> Replacing identifiers in scaffold sources and docs"
  _replace_in_files "$old_package" "$new_package"
  _replace_in_files "$old_artifact" "$new_artifact"
  _replace_in_files "$old_app_name" "$new_app_name"
  _replace_in_files "$old_db_dev" "$new_db_dev"
  _replace_in_files "$old_db_test" "$new_db_test"
  _replace_in_files "$old_db_uat" "$new_db_uat"
  _replace_in_files "$old_db_pre" "$new_db_pre"
  _replace_in_files "$old_db_prod" "$new_db_prod"
  _replace_in_files "$old_group_id" "$new_group_id"

  local old_main_class new_main_class
  old_main_class="$(capitalize "$old_module_name")Application"
  new_main_class="$(capitalize "$new_module_name")Application"

  if [[ "$old_module_name" != "$new_module_name" ]]; then
    echo "==> Renaming main class: ${old_main_class} -> ${new_main_class}"
    local main_src="${main_base}/${new_path}"
    local main_file="${main_src}/${old_main_class}.java"
    if [[ -f "$main_file" ]]; then
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/${old_main_class}/${new_main_class}/g" "$main_file"
      else
        sed -i "s/${old_main_class}/${new_main_class}/g" "$main_file"
      fi
      mv "$main_file" "${main_src}/${new_main_class}.java"
    fi
    local test_src="${test_base}/${new_path}"
    local old_test_class="${old_main_class}IntegrationTest"
    local new_test_class="${new_main_class}IntegrationTest"
    local test_file="${test_src}/${old_test_class}.java"
    if [[ -f "$test_file" ]]; then
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/${old_main_class}/${new_main_class}/g" "$test_file"
      else
        sed -i "s/${old_main_class}/${new_main_class}/g" "$test_file"
      fi
      mv "$test_file" "${test_src}/${new_test_class}.java"
    fi
  fi

  BASE_PACKAGE="$new_package"
  GROUP_ID="$new_group_id"
  ARTIFACT_ID="$new_artifact"
  APP_NAME="$new_app_name"
  MODULE_NAME="$new_module_name"
  DB_DEV="$new_db_dev"
  DB_TEST="$new_db_test"
  DB_UAT="$new_db_uat"
  DB_PRE="$new_db_pre"
  DB_PROD="$new_db_prod"
  save_skeleton_config "$root"

  install_cursor_rules "$root" "$service_module"

  echo "==> Done."
  echo "    basePackage: ${new_package}"
  echo "    groupId:     ${new_group_id}"
  echo "    artifact:    ${new_artifact}"
  echo "    app name:    ${new_app_name}"
  echo "    config:      skeleton.defaults.json updated"
}
