#!/usr/bin/env bash
# 一键检查本地开发 / 联调环境是否符合本 Monorepo 要求
#
# Usage:
#   ./shared/scripts/check-environment.sh              # 必装 + 推荐项
#   ./shared/scripts/check-environment.sh --integration # 含 Docker / 端口（本地联调）
#   ./shared/scripts/check-environment.sh --json        # JSON 输出（CI / 自动化）
#   ./shared/scripts/check-environment.sh --help
#
# 退出码: 0 = 全部必检项通过；1 = 存在缺失或版本不符

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CHECK_INTEGRATION=false
JSON_MODE=false

usage() {
  cat <<'EOF'
Usage: ./shared/scripts/check-environment.sh [OPTIONS]

检查 JDK、Maven、Git、Cursor/OpenSpec/Superpowers、项目配置；可选 Docker 联调环境。

OPTIONS:
  --integration   额外检查 Docker、Compose、常用联调端口
  --json          JSON 输出（供 CI / 脚本解析）
  -h, --help      显示帮助

参考文档:
  shared/docs/CURSOR-IDE-SETUP.md
  shared/docs/CI-TOOLCHAIN.md
  docs/DEPLOYMENT.md §4.5
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --integration) CHECK_INTEGRATION=true; shift ;;
    --json) JSON_MODE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# --- counters & result store ---
REQ_PASS=0
REQ_FAIL=0
OPT_PASS=0
OPT_WARN=0
OPT_FAIL=0
JSON_ITEMS=()

# --- colors (disabled when not tty or --json) ---
if [[ -t 1 ]] && ! $JSON_MODE; then
  C_GREEN='\033[0;32m'
  C_YELLOW='\033[1;33m'
  C_RED='\033[0;31m'
  C_BLUE='\033[0;34m'
  C_DIM='\033[0;2m'
  C_RESET='\033[0m'
else
  C_GREEN='' C_YELLOW='' C_RED='' C_BLUE='' C_DIM='' C_RESET=''
fi

# Compare semver: version_ge <current> <minimum> → 0 if current >= minimum
version_ge() {
  local cur="${1#v}" min="${2#v}"
  if [[ "$cur" == "$min" ]]; then return 0; fi
  local lowest
  lowest="$(printf '%s\n%s\n' "$min" "$cur" | sort -V | head -n1)"
  [[ "$lowest" == "$min" && "$cur" != "$min" ]]
}

# Extract major Java version from `java -version` stderr
java_major_version() {
  local ver_line
  ver_line="$("$1" -version 2>&1 | head -n1)"
  if [[ "$ver_line" =~ \"([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$ver_line" =~ version\ \"1\.([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

# Extract Maven version from `mvn -version` first line
maven_version() {
  local line
  line="$("$1" -version 2>&1 | head -n1)"
  if [[ "$line" =~ Apache\ Maven\ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

# Maven-reported Java version from `mvn -version`
maven_java_major() {
  local line
  line="$("$1" -version 2>&1 | grep -E '^Java version:' | head -n1)"
  if [[ "$line" =~ Java\ version:\ ([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

record_json() {
  local level="$1" category="$2" name="$3" status="$4" detail="$5"
  JSON_ITEMS+=("$(printf '{"level":"%s","category":"%s","name":"%s","status":"%s","detail":"%s"}' \
    "$level" "$category" "$name" "$status" "$(echo "$detail" | sed 's/"/\\"/g')")")
}

# level: required | optional
# status: pass | fail | warn
emit() {
  local level="$1" status="$2" name="$3" expected="$4" actual="$5" hint="$6"
  local icon label color

  case "$status" in
    pass) icon='✓'; color="$C_GREEN" ;;
    warn) icon='⚠'; color="$C_YELLOW" ;;
    fail) icon='✗'; color="$C_RED" ;;
    *) icon='·'; color="$C_DIM" ;;
  esac

  if [[ "$level" == "required" ]]; then
    label='必装'
    case "$status" in
      pass) REQ_PASS=$((REQ_PASS + 1)) ;;
      *) REQ_FAIL=$((REQ_FAIL + 1)) ;;
    esac
  else
    label='推荐'
    case "$status" in
      pass) OPT_PASS=$((OPT_PASS + 1)) ;;
      warn) OPT_WARN=$((OPT_WARN + 1)) ;;
      fail) OPT_FAIL=$((OPT_FAIL + 1)) ;;
    esac
  fi

  record_json "$level" "$label" "$name" "$status" "${actual:-—} (要求: ${expected})"

  if ! $JSON_MODE; then
    printf "  ${color}%s${C_RESET} [%s] %s\n" "$icon" "$label" "$name"
    printf "      ${C_DIM}要求:${C_RESET} %s\n" "$expected"
    printf "      ${C_DIM}当前:${C_RESET} %s\n" "${actual:-未检测到}"
    [[ -n "$hint" ]] && printf "      ${C_DIM}建议:${C_RESET} %s\n" "$hint"
    echo
  fi
}

section() {
  if ! $JSON_MODE; then
    printf "${C_BLUE}== %s ==${C_RESET}\n\n" "$1"
  fi
}

# 解析 Cursor CLI 路径（空表示未找到）
resolve_cursor_bin() {
  local c
  for c in cursor "/Applications/Cursor.app/Contents/Resources/app/bin/cursor"; do
    if command -v "$c" >/dev/null 2>&1; then
      command -v "$c"
      return 0
    fi
    if [[ -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

# 检测 Superpowers 插件缓存（Cursor 插件市场，非 VS Code 扩展）
find_superpowers_plugin_root() {
  local root="${HOME}/.cursor/plugins/cache/cursor-public/superpowers"
  local candidate skill
  if [[ ! -d "$root" ]]; then
    return 1
  fi
  for candidate in "${root}"/*/; do
    [[ -d "$candidate" ]] || continue
    skill="${candidate}skills/using-superpowers/SKILL.md"
    if [[ -f "$skill" ]]; then
      echo "${candidate%/}"
      return 0
    fi
  done
  return 1
}

# 统计 glob 匹配数量（无匹配返回 0）
glob_count() {
  local pattern="$1"
  local n=0 f
  shopt -s nullglob
  for f in $pattern; do
    [[ -e "$f" ]] && n=$((n + 1))
  done
  shopt -u nullglob
  echo "$n"
}

# --- checks ---

check_command() {
  local level="$1" cmd="$2" name="$3" expected="$4" hint="$5"
  if command -v "$cmd" >/dev/null 2>&1; then
    emit "$level" pass "$name" "$expected" "已安装 ($(command -v "$cmd"))" ""
  else
    emit "$level" fail "$name" "$expected" "未安装" "$hint"
  fi
}

check_java() {
  section "Java / JDK"
  local expected_major=17
  local java_bin=""

  if command -v java >/dev/null 2>&1; then
    java_bin="java"
  else
    emit required fail "JDK" "Java ${expected_major}" "未找到 java 命令" \
      "export JAVA_HOME=\$(/usr/libexec/java_home -v 17)  # macOS"
    return
  fi

  local major ver_line
  major="$(java_major_version "$java_bin")"
  ver_line="$("$java_bin" -version 2>&1 | head -n1)"

  if [[ "$major" == "$expected_major" ]]; then
    emit required pass "JDK 版本" "Java ${expected_major}.x" "$ver_line" ""
  elif [[ -n "$major" ]]; then
    emit required fail "JDK 版本" "Java ${expected_major}.x" "$ver_line (major=${major})" \
      "export JAVA_HOME=\$(/usr/libexec/java_home -v 17)"
  else
    emit required warn "JDK 版本" "Java ${expected_major}.x" "$ver_line" "无法解析主版本号，请手动确认"
  fi

  if [[ -n "${JAVA_HOME:-}" ]]; then
    local home_major
    if [[ -x "${JAVA_HOME}/bin/java" ]]; then
      home_major="$(java_major_version "${JAVA_HOME}/bin/java")"
      if [[ "$home_major" == "$expected_major" ]]; then
        emit required pass "JAVA_HOME" "指向 JDK ${expected_major}" "$JAVA_HOME" ""
      else
        emit required fail "JAVA_HOME" "指向 JDK ${expected_major}" "$JAVA_HOME (Java ${home_major:-?})" \
          "在 ~/.zshrc 设置: export JAVA_HOME=\$(/usr/libexec/java_home -v 17)"
      fi
    else
      emit required fail "JAVA_HOME" "有效 JDK 目录" "$JAVA_HOME (无 bin/java)" \
        "修正 JAVA_HOME 路径"
    fi
  else
    if [[ "$major" == "$expected_major" ]]; then
      emit optional warn "JAVA_HOME" "建议显式设置" "未设置（java 命令已是 17）" \
        "写入 ~/.zshrc: export JAVA_HOME=\$(/usr/libexec/java_home -v 17)"
    else
      emit required fail "JAVA_HOME" "指向 JDK ${expected_major}" "未设置" \
        "export JAVA_HOME=\$(/usr/libexec/java_home -v 17)"
    fi
  fi

  if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    local jdk17_home=""
    jdk17_home="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
    if [[ -n "$jdk17_home" ]]; then
      emit optional pass "本机 JDK 17" "已安装" "$jdk17_home" ""
    else
      emit optional fail "本机 JDK 17" "已安装" "未找到" "安装 JDK 17 或 GraalVM 17"
    fi
  fi
}

check_maven() {
  section "Maven"
  local min_version="3.9.0"

  if ! command -v mvn >/dev/null 2>&1; then
    emit required fail "Maven" ">= ${min_version}" "未安装" \
      "https://maven.apache.org/download.cgi 或 brew install maven"
    return
  fi

  local ver mvn_java
  ver="$(maven_version mvn)"
  mvn_java="$(maven_java_major mvn)"

  if [[ -n "$ver" ]] && version_ge "$ver" "$min_version"; then
    emit required pass "Maven 版本" ">= ${min_version}" "Apache Maven ${ver}" ""
  elif [[ -n "$ver" ]]; then
    emit required fail "Maven 版本" ">= ${min_version}" "Apache Maven ${ver}" "升级到 Maven 3.9+"
  else
    emit required warn "Maven 版本" ">= ${min_version}" "$(mvn -version 2>&1 | head -n1)" "请手动确认版本"
  fi

  if [[ "$mvn_java" == "17" ]]; then
    local mvn_java_detail
    mvn_java_detail="$(mvn -version 2>&1 | grep -E '^Java version:' | head -n1 | sed 's/^Java version: //')"
    emit required pass "Maven 使用的 Java" "17.x" "Java ${mvn_java} (${mvn_java_detail})" ""
  elif [[ -n "$mvn_java" ]]; then
    emit required fail "Maven 使用的 Java" "17.x" "Java ${mvn_java}" \
      "确保 PATH 中 JDK 17 优先: export PATH=\"\$JAVA_HOME/bin:\$PATH\""
  else
    emit required warn "Maven 使用的 Java" "17.x" "无法解析" "运行 mvn -version 手动确认"
  fi

  if [[ -n "${MAVEN_HOME:-}" && -x "${MAVEN_HOME}/bin/mvn" ]]; then
    emit optional pass "MAVEN_HOME" "已设置" "$MAVEN_HOME" ""
  else
    emit optional warn "MAVEN_HOME" "建议设置" "${MAVEN_HOME:-未设置}" \
      "export MAVEN_HOME=/path/to/apache-maven-3.9.x"
  fi
}

check_git() {
  section "Git"
  if command -v git >/dev/null 2>&1; then
    emit required pass "Git" "任意近期版本" "$(git --version)" ""
  else
    emit required fail "Git" "已安装" "未找到" "https://git-scm.com/downloads"
  fi
}

check_node() {
  section "Node.js（OpenSpec 依赖）"
  local min_node="20.19.0"

  if ! command -v node >/dev/null 2>&1; then
    emit optional fail "Node.js" ">= ${min_node}" "未安装" \
      "https://nodejs.org 或 nvm install 20"
    return
  fi

  local node_ver
  node_ver="$(node -v 2>/dev/null | sed 's/^v//')"
  if version_ge "$node_ver" "$min_node"; then
    emit optional pass "Node.js" ">= ${min_node}" "v${node_ver}" ""
  else
    emit optional fail "Node.js" ">= ${min_node}" "v${node_ver}" "nvm install 20 或升级 Node"
  fi
}

check_cursor_toolchain() {
  section "Cursor IDE（团队推荐）"

  local cursor_app=""
  case "$(uname -s)" in
    Darwin)
      if [[ -d "/Applications/Cursor.app" ]]; then
        cursor_app="/Applications/Cursor.app"
      fi
      ;;
    Linux)
      if command -v cursor >/dev/null 2>&1; then
        cursor_app="$(command -v cursor)"
      fi
      ;;
  esac

  if [[ -n "$cursor_app" ]]; then
    emit optional pass "Cursor 应用" "已安装" "$cursor_app" ""
  else
    emit optional fail "Cursor 应用" "已安装" "未检测到" \
      "https://cursor.com 下载安装；macOS 默认路径 /Applications/Cursor.app"
  fi

  local cursor_bin=""
  if cursor_bin="$(resolve_cursor_bin)"; then
    local cursor_ver=""
    cursor_ver="$("$cursor_bin" --version 2>/dev/null | head -n1 || true)"
    if [[ -n "$cursor_ver" ]]; then
      emit optional pass "Cursor CLI" "cursor 命令可用" "$cursor_ver" ""
    else
      emit optional pass "Cursor CLI" "cursor 命令可用" "$cursor_bin" ""
    fi

    if "$cursor_bin" --list-extensions 2>/dev/null | grep -qi 'sonarsource.sonarlint-vscode'; then
      emit optional pass "SonarLint 扩展" "SonarSource.sonarlint-vscode" "已安装" ""
    else
      emit optional fail "SonarLint 扩展" "SonarSource.sonarlint-vscode" "未检测到" \
        "cursor --install-extension SonarSource.sonarlint-vscode"
    fi
  else
    emit optional fail "Cursor CLI" "cursor 命令可用" "未在 PATH 中" \
      "macOS: /Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    emit optional warn "SonarLint 扩展" "SonarSource.sonarlint-vscode" "无法自动检测（无 CLI）" \
      "在 Cursor 中安装推荐扩展"
  fi
}

check_superpowers_plugin() {
  section "Superpowers 插件（团队推荐）"

  local plugin_root sp_version skill_count
  if plugin_root="$(find_superpowers_plugin_root)"; then
    sp_version=""
    if [[ -f "${plugin_root}/.cursor-plugin/plugin.json" ]]; then
      sp_version="$(grep -E '"version"' "${plugin_root}/.cursor-plugin/plugin.json" 2>/dev/null \
        | head -n1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
    fi
    skill_count="$(find "${plugin_root}/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    if [[ -n "$sp_version" ]]; then
      emit optional pass "Superpowers 插件" "已安装（Cursor 插件市场）" \
        "v${sp_version}，${skill_count} 个 skills（${plugin_root}）" \
        "在 Cursor Settings → Plugins 确认已启用"
    else
      emit optional pass "Superpowers 插件" "已安装（Cursor 插件市场）" \
        "${skill_count} 个 skills（${plugin_root}）" \
        "在 Cursor Settings → Plugins 确认已启用"
    fi
    emit optional pass "Superpowers 核心 Skill" "using-superpowers" "已缓存" ""
  else
    emit optional fail "Superpowers 插件" "已安装并启用" "未检测到本地缓存" \
      "Cursor Chat: /add-plugin superpowers；或 Settings → Plugins → Superpowers"
  fi
}

check_openspec() {
  section "OpenSpec（团队推荐）"

  local min_node="20.19.0"
  local has_node=false
  if command -v node >/dev/null 2>&1; then
    local node_ver
    node_ver="$(node -v 2>/dev/null | sed 's/^v//')"
    if version_ge "$node_ver" "$min_node"; then
      has_node=true
    fi
  fi

  if command -v openspec >/dev/null 2>&1; then
    local os_ver
    os_ver="$(openspec --version 2>/dev/null || echo '已安装')"
    emit optional pass "OpenSpec CLI" "openspec 命令" "$os_ver" ""
  elif $has_node; then
    emit optional fail "OpenSpec CLI" "openspec 命令" "未安装" \
      "npm install -g @fission-ai/openspec@latest"
  else
    emit optional fail "OpenSpec CLI" "openspec 命令" "未安装（需 Node >= ${min_node}）" \
      "先安装 Node.js，再 npm install -g @fission-ai/openspec@latest"
  fi

  if [[ -d "${REPO_ROOT}/openspec" ]]; then
    emit optional pass "OpenSpec 仓库目录" "openspec/" "已存在" ""
    if [[ -f "${REPO_ROOT}/openspec/config.yaml" ]]; then
      emit optional pass "OpenSpec 配置" "openspec/config.yaml" "已存在" ""
    else
      emit optional warn "OpenSpec 配置" "openspec/config.yaml" "缺失" \
        "在仓库根目录执行: openspec init --tools cursor"
    fi
  else
    emit optional warn "OpenSpec 仓库目录" "openspec/" "未初始化" \
      "cd ${REPO_ROOT} && openspec init --tools cursor"
  fi

  local opsx_cmd_count opsx_skill_count
  opsx_cmd_count="$(glob_count "${REPO_ROOT}/.cursor/commands/opsx-"*.md)"
  opsx_skill_count="$(glob_count "${REPO_ROOT}/.cursor/skills/openspec-"*/SKILL.md)"

  if [[ "$opsx_cmd_count" -gt 0 ]]; then
    emit optional pass "OpenSpec Cursor 斜杠命令" ".cursor/commands/opsx-*.md" \
      "已配置 ${opsx_cmd_count} 个" ""
  else
    emit optional fail "OpenSpec Cursor 斜杠命令" ".cursor/commands/opsx-*.md" "未找到" \
      "openspec init --tools cursor；Chat 中应能联想 /opsx-*"
  fi

  if [[ "$opsx_skill_count" -gt 0 ]]; then
    emit optional pass "OpenSpec Cursor Skills" ".cursor/skills/openspec-*/SKILL.md" \
      "已配置 ${opsx_skill_count} 个" ""
  else
    emit optional warn "OpenSpec Cursor Skills" ".cursor/skills/openspec-*/SKILL.md" "未找到" \
      "openspec init --tools cursor"
  fi

  if [[ -f "${REPO_ROOT}/AGENTS.md" ]]; then
    emit optional pass "AGENTS.md" "OpenSpec 团队约定" "已存在" ""
  else
    emit optional warn "AGENTS.md" "OpenSpec 团队约定" "未找到" \
      "openspec init 后可选提交 AGENTS.md"
  fi
}

check_project_layout() {
  section "项目配置（Monorepo）"

  local paths=(
    ".mvn/settings.xml:Maven 镜像配置"
    "java-microservice-common/pom.xml:公共组件工程"
    "java-microservice-gateway/pom.xml:网关工程"
    "java-microservice-scaffold/pom.xml:业务脚手架工程"
    "java-microservice-scaffold/skeleton-service/pom.xml:业务服务模板"
  )

  for entry in "${paths[@]}"; do
    local rel="${entry%%:*}"
    local desc="${entry##*:}"
    if [[ -f "${REPO_ROOT}/${rel}" ]]; then
      emit required pass "$desc" "$rel" "存在" ""
    else
      emit required fail "$desc" "$rel" "缺失" "请在仓库根目录执行: ${REPO_ROOT}"
    fi
  done

  # maven.config Maven 3.9+ 多行格式粗检
  local cfg="${REPO_ROOT}/.mvn/maven.config"
  if [[ -f "$cfg" ]]; then
    if grep -q 'session.rootDirectory' "$cfg" 2>/dev/null; then
      emit optional pass "maven.config" "Maven 3.9+ 格式" "含 session.rootDirectory" ""
    else
      emit optional warn "maven.config" "Maven 3.9+ 多行格式" "$(tr '\n' ' ' < "$cfg")" \
        "参见 .mvn/maven.config 示例（--settings 与路径分行）"
    fi
  fi

  if command -v mvn >/dev/null 2>&1; then
    local local_repo
    local_repo="$(cd "${REPO_ROOT}/java-microservice-common" && mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout 2>/dev/null || true)"
    if [[ -n "$local_repo" && -w "$local_repo" ]]; then
      emit optional pass "Maven 本地仓库" "可写" "$local_repo" ""
    elif [[ -n "$local_repo" ]]; then
      emit optional warn "Maven 本地仓库" "可写" "$local_repo (不可写?)" "检查目录权限"
    fi

    if [[ -d "$local_repo/com/s3/common-core" ]] || \
       find "$local_repo" -maxdepth 4 -type d -name 'common-core' 2>/dev/null | grep -q .; then
      emit optional pass "common 本地安装" "mvn install 后可用" "已检测到 common-core" \
        ""
    else
      emit optional warn "common 本地安装" "mvn install 后可用" "未检测到" \
        "cd java-microservice-common && mvn clean install"
    fi
  fi
}

check_docker_integration() {
  section "Docker 联调（--integration）"

  if ! command -v docker >/dev/null 2>&1; then
    emit optional fail "Docker" ">= 20.10" "未安装" "安装 Docker Desktop"
    emit optional fail "Docker Compose" "V2 (docker compose)" "跳过" ""
    return
  fi

  local docker_ver
  docker_ver="$(docker --version 2>/dev/null || echo unknown)"
  emit optional pass "Docker" ">= 20.10" "$docker_ver" ""

  if docker compose version >/dev/null 2>&1; then
    emit optional pass "Docker Compose" "V2" "$(docker compose version 2>/dev/null | head -n1)" ""
  else
    emit optional fail "Docker Compose" "V2 (docker compose)" "不可用" "升级 Docker Desktop"
  fi

  if docker info >/dev/null 2>&1; then
    emit optional pass "Docker 守护进程" "运行中" "docker info 成功" ""
  else
    emit optional fail "Docker 守护进程" "运行中" "未运行或无权限" "启动 Docker Desktop"
  fi

  section "联调端口（占用情况）"
  local ports=(8848 3306 9092 6379 8080 8081)
  for port in "${ports[@]}"; do
    local state="空闲"
    local detail="可启动对应服务"
    if command -v lsof >/dev/null 2>&1; then
      local proc
      proc="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $1" (pid "$2")"}')"
      if [[ -n "$proc" ]]; then
        state="已占用"
        detail="$proc"
        emit optional warn "端口 ${port}" "联调前宜空闲或确认为目标服务" "$state — $detail" ""
        continue
      fi
    elif command -v nc >/dev/null 2>&1; then
      if nc -z 127.0.0.1 "$port" 2>/dev/null; then
        state="已占用"
        detail="127.0.0.1:${port} 有监听"
        emit optional warn "端口 ${port}" "联调前宜空闲或确认为目标服务" "$state — $detail" ""
        continue
      fi
    fi
    emit optional pass "端口 ${port}" "未占用或无法检测" "$state" "$detail"
  done

  local compose_script="${REPO_ROOT}/java-microservice-scaffold/platform/docker-compose/start-local.sh"
  if [[ -x "$compose_script" ]]; then
    emit optional pass "本地基础设施脚本" "可执行" "$compose_script" ""
  else
    emit optional warn "本地基础设施脚本" "可执行" "${compose_script} (缺失或不可执行)" \
      "chmod +x java-microservice-scaffold/platform/docker-compose/start-local.sh"
  fi
}

print_summary() {
  if $JSON_MODE; then
    local items_json
    items_json="$(printf '%s,' "${JSON_ITEMS[@]}")"
    items_json="[${items_json%,}]"
    printf '{"required":{"pass":%d,"fail":%d},"optional":{"pass":%d,"warn":%d,"fail":%d},"items":%s}\n' \
      "$REQ_PASS" "$REQ_FAIL" "$OPT_PASS" "$OPT_WARN" "$OPT_FAIL" "$items_json"
    return
  fi

  echo
  printf "${C_BLUE}== 汇总 ==${C_RESET}\n\n"
  printf "  必装项: ${C_GREEN}%d 通过${C_RESET}" "$REQ_PASS"
  if [[ $REQ_FAIL -gt 0 ]]; then
    printf ", ${C_RED}%d 未通过${C_RESET}" "$REQ_FAIL"
  fi
  echo

  local opt_total=$((OPT_PASS + OPT_WARN + OPT_FAIL))
  if [[ $opt_total -gt 0 ]]; then
    printf "  推荐项: ${C_GREEN}%d 通过${C_RESET}" "$OPT_PASS"
    [[ $OPT_WARN -gt 0 ]] && printf ", ${C_YELLOW}%d 警告${C_RESET}" "$OPT_WARN"
    [[ $OPT_FAIL -gt 0 ]] && printf ", ${C_RED}%d 未通过${C_RESET}" "$OPT_FAIL"
    echo
  fi

  echo
  if [[ $REQ_FAIL -eq 0 ]]; then
    printf "  ${C_GREEN}必装环境检查通过。${C_RESET}"
    if [[ $OPT_FAIL -gt 0 || $OPT_WARN -gt 0 ]]; then
      printf " 推荐项有警告，见上文。\n"
    else
      echo
    fi
    if $CHECK_INTEGRATION; then
      echo "  可继续: cd java-microservice-common && mvn clean install"
      echo "          cd java-microservice-scaffold && ./platform/docker-compose/start-local.sh"
    else
      echo "  下一步: cd java-microservice-common && mvn clean install && cd ../java-microservice-scaffold && mvn clean test"
      echo "  联调检查: ./shared/scripts/check-environment.sh --integration"
    fi
  else
    printf "  ${C_RED}存在必装项缺失或版本不符，请先修复后再构建。${C_RESET}\n"
    echo "  文档: shared/docs/CURSOR-IDE-SETUP.md"
  fi
  echo
}

# --- main ---
if ! $JSON_MODE; then
  printf "${C_BLUE}Java 微服务 Monorepo — 环境检查${C_RESET}\n"
  printf "${C_DIM}仓库: %s${C_RESET}\n\n" "$REPO_ROOT"
fi

check_java
check_maven
check_git
check_node
check_cursor_toolchain
check_superpowers_plugin
check_openspec
check_project_layout

if $CHECK_INTEGRATION; then
  check_docker_integration
fi

print_summary

if [[ $REQ_FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
