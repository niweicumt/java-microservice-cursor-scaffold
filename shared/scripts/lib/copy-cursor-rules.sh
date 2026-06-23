#!/usr/bin/env bash
# 将 Cursor 项目规则安装到微服务模块 .cursor/rules/（团队共享，无需本地重复配置）
set -euo pipefail

# Monorepo 根目录仅适用于 alwaysApply 的全局规则，不复制到单服务模块
_CURSOR_RULES_SKIP="specify-rules.mdc"
# 单服务模块使用 skeleton-service 内模板（项目根相对 globs），不用 monorepo 版
_CURSOR_RULES_SERVICE_TEMPLATE="microservice-architecture.mdc"

_resolve_monorepo_root() {
  local scaffold_root="$1"
  local candidate
  for candidate in \
    "$(cd "${scaffold_root}/.." && pwd)" \
    "$(cd "${scaffold_root}/../.." && pwd)"; do
    if [[ -d "${candidate}/.cursor/rules" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  echo ""
}

# install_cursor_rules <scaffold_root> [service_module]
install_cursor_rules() {
  local scaffold_root="$1"
  local service_module="${2:-skeleton-service}"
  local dest="${scaffold_root}/${service_module}/.cursor/rules"
  local monorepo_root
  monorepo_root="$(_resolve_monorepo_root "$scaffold_root")"

  mkdir -p "$dest"

  local svc_arch_backup=""
  if [[ -f "${dest}/${_CURSOR_RULES_SERVICE_TEMPLATE}" ]]; then
    svc_arch_backup="$(mktemp)"
    cp "${dest}/${_CURSOR_RULES_SERVICE_TEMPLATE}" "$svc_arch_backup"
  fi

  local copied=0

  if [[ -n "$monorepo_root" && -d "${monorepo_root}/.cursor/rules" ]]; then
    echo "==> Installing Cursor rules from ${monorepo_root}/.cursor/rules -> ${dest}"
    local rule_file base
    for rule_file in "${monorepo_root}/.cursor/rules"/*.mdc; do
      [[ -f "$rule_file" ]] || continue
      base="$(basename "$rule_file")"
      if [[ " ${_CURSOR_RULES_SKIP} " == *" ${base} "* ]]; then
        continue
      fi
      if [[ "$base" == "$_CURSOR_RULES_SERVICE_TEMPLATE" ]]; then
        continue
      fi
      cp "$rule_file" "${dest}/${base}"
      copied=$((copied + 1))
    done
  fi

  if [[ -n "$svc_arch_backup" ]]; then
    cp "$svc_arch_backup" "${dest}/${_CURSOR_RULES_SERVICE_TEMPLATE}"
    rm -f "$svc_arch_backup"
    copied=$((copied + 1))
  elif [[ -f "${dest}/${_CURSOR_RULES_SERVICE_TEMPLATE}" ]]; then
    copied=$((copied + 1))
  fi

  if [[ "$copied" -eq 0 ]]; then
    echo "Warning: no Cursor rules installed (check monorepo .cursor/rules or skeleton-service template)" >&2
    return 1
  fi

  echo "    Cursor rules: ${dest} ($(find "$dest" -maxdepth 1 -name '*.mdc' | wc -l | tr -d ' ') files)"
}
