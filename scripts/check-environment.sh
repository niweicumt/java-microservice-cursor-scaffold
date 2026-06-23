#!/usr/bin/env bash
# 仓库根目录快捷入口 → shared/scripts/check-environment.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "${ROOT}/shared/scripts/check-environment.sh" "$@"
