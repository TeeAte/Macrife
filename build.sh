#!/bin/bash
# =============================================================
#  在 release 目录下快速构建并启动 Macrife.app
# =============================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

"$ROOT_DIR/build&pack.command" "$@"
