#!/usr/bin/env bash
# 跨 common / scaffold 工程的包路径与组织前缀替换
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
_COMMON_ROOT="${_REPO_ROOT}/java-microservice-common"
_GATEWAY_ROOT="${_REPO_ROOT}/java-microservice-gateway"
_SCAFFOLD_ROOT="${_REPO_ROOT}/java-microservice-scaffold"

_sed_inplace() {
  local expr="$1"
  local file="$2"
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$expr" "$file"
  else
    sed -i "$expr" "$file"
  fi
}

_replace_text_in_tree() {
  local root="$1"
  local old="$2"
  local new="$3"
  if [[ "$old" == "$new" || -z "$old" ]]; then
    return
  fi
  find "$root" -type f \( \
    -name '*.java' -o -name '*.xml' -o -name '*.yml' -o -name '*.yaml' \
    -o -name '*.json' -o -name '*.md' -o -name '*.mdc' -o -name '*.sh' \
    \) ! -path '*/target/*' ! -path '*/.git/*' \
    -exec grep -l "${old}" {} + 2>/dev/null | while read -r f; do
      _sed_inplace "s|${old}|${new}|g" "$f"
    done
}

_move_org_java_dirs() {
  local project_root="$1"
  local old_org="$2"
  local new_org="$3"
  local old_seg="${old_org//./\/}"
  local new_seg="${new_org//./\/}"

  find "$project_root" \( -path '*/src/main/java/*' -o -path '*/src/test/java/*' \) -type d -path "*/${old_seg}" 2>/dev/null | \
    sort -r | while read -r old_dir; do
      local parent new_dir
      parent="$(dirname "$old_dir")"
      new_dir="${parent}/${new_seg##*/}"
      if [[ "$old_org" != *.* ]]; then
        new_dir="${parent}/$(basename "$new_seg")"
      fi
      new_dir="${old_dir/${old_seg}/${new_seg}}"
      mkdir -p "$(dirname "$new_dir")"
      if [[ -d "$new_dir" ]]; then
        echo "Warning: target exists, merging: $new_dir" >&2
        shopt -s dotglob
        mv "$old_dir"/* "$new_dir"/ 2>/dev/null || true
        shopt -u dotglob
        rmdir "$old_dir" 2>/dev/null || true
      else
        mv "$old_dir" "$new_dir"
      fi
      echo "  moved: ${old_dir#$project_root/} -> ${new_dir#$project_root/}"
    done
}

apply_organization_prefix() {
  local old_org="$1"
  local new_org="$2"

  echo "==> Organization prefix: ${old_org} -> ${new_org}"
  echo "==> [common] ${old_org}.common -> ${new_org}.common"
  _move_org_java_dirs "$_COMMON_ROOT" "$old_org" "$new_org"
  _replace_text_in_tree "$_COMMON_ROOT" "$old_org" "$new_org"

  echo "==> [gateway] ${old_org}.gateway -> ${new_org}.gateway"
  _move_org_java_dirs "$_GATEWAY_ROOT" "$old_org" "$new_org"
  _replace_text_in_tree "$_GATEWAY_ROOT" "$old_org" "$new_org"

  echo "==> [scaffold] ${old_org}.* -> ${new_org}.*"
  _move_org_java_dirs "$_SCAFFOLD_ROOT" "$old_org" "$new_org"
  _replace_text_in_tree "$_SCAFFOLD_ROOT" "$old_org" "$new_org"
  _replace_text_in_tree "$_REPO_ROOT/shared" "$old_org" "$new_org"
  _replace_text_in_tree "$_REPO_ROOT/.cursor" "$old_org" "$new_org" 2>/dev/null || true

  python3 - "$_REPO_ROOT/shared/package.defaults.json" "$new_org" <<'PY'
import json, sys
path, org = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
data["organizationPrefix"] = org
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

  python3 - "$_COMMON_ROOT/common.defaults.json" "$old_org" "$new_org" <<'PY'
import json, sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
data["organizationPrefix"] = new
data["basePackage"] = data["basePackage"].replace(old, new, 1)
data["groupId"] = new
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

  if [[ -f "$_SCAFFOLD_ROOT/skeleton.defaults.json" ]]; then
    python3 - "$_SCAFFOLD_ROOT/skeleton.defaults.json" "$old_org" "$new_org" <<'PY'
import json, sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
if "organizationPrefix" in data:
    data["organizationPrefix"] = new
data["basePackage"] = data["basePackage"].replace(old, new, 1)
data["groupId"] = new
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
  fi

  if [[ -f "$_GATEWAY_ROOT/gateway.defaults.json" ]]; then
    python3 - "$_GATEWAY_ROOT/gateway.defaults.json" "$old_org" "$new_org" <<'PY'
import json, sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
if "organizationPrefix" in data:
    data["organizationPrefix"] = new
data["basePackage"] = data["basePackage"].replace(old, new, 1)
data["groupId"] = new
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
  fi

  echo "==> Done. Re-run: cd java-microservice-common && mvn clean install"
}
