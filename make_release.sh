#!/bin/bash
# =============================================================
#  Macrife 发布打包脚本（放置于 release/ 仓库）
#
#  功能：
#    1. 编译 release 二进制
#    2. 组装 Macrife.app 并注入指定版本号与模型
#    3. 自动代码签名
#    4. 打包 DMG（内含 Macrife.app 与 /Applications 替身，不打 zip）
#    5. 生成 SHA256SUMS.txt 校验文件
#    6. 输出至独立版本文件夹（如 release/v1.01/），同一版本重复执行直接覆盖
#
#  用法：
#    ./make_release.sh                  # 默认 1.01
#    ./make_release.sh 1.02             # 直接指定版本号
#    ./make_release.sh --version 1.02
#    VERSION=1.02 ./make_release.sh
#    ./make_release.sh --lite           # 仅内置 576p
# =============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/../Package.swift" ]; then
    ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
    RELEASE_DIR="$SCRIPT_DIR"
elif [ -f "$SCRIPT_DIR/Package.swift" ]; then
    ROOT_DIR="$SCRIPT_DIR"
    RELEASE_DIR="$ROOT_DIR/release"
else
    echo "❌ 找不到 Macrife 工程根目录"
    exit 1
fi

# 支持位置参数直接指定版本：./make_release.sh 1.01
if [ -n "$1" ] && [[ "$1" != -* ]]; then
    VERSION="$1"
    shift
fi

TIERS="576p 720p 1080p 1440p 2160p"
SIGN_INPUT=""
NO_PROMPT=0

while [ $# -gt 0 ]; do
    case "$1" in
        --version|-v) VERSION="$2"; shift 2 ;;
        --lite)       TIERS="576p"; shift ;;
        --tiers)      TIERS=$(echo "$2" | tr ',' ' '); shift 2 ;;
        --sign)       SIGN_INPUT="$2"; shift 2 ;;
        --no-prompt)  NO_PROMPT=1; shift ;;
        -h|--help)
            echo "用法: ./make_release.sh [版本号] [--version <版本>] [--lite] [--tiers 576p,1080p] [--sign <证书>] [--no-prompt]"
            exit 0
            ;;
        *) echo "未知参数: $1（--help 看用法）"; exit 1 ;;
    esac
done

# 如果未通过参数指定版本，且处于交互/GUI环境，询问版本号
if [ -z "$VERSION" ]; then
    DEFAULT_VER="1.01"
    if [ -d "$RELEASE_DIR" ]; then
        LATEST_FOUND=$(find "$RELEASE_DIR" -maxdepth 1 -type d -name "v*" 2>/dev/null | sed -E 's/.*\/v//' | sort -V | tail -n 1)
        if [ -n "$LATEST_FOUND" ]; then
            DEFAULT_VER="$LATEST_FOUND"
        fi
    fi

    PROMPT_OUT=""
    if [ "${NO_PROMPT}" != "1" ] && [ -z "$CI" ] && [ -z "$NON_INTERACTIVE" ]; then
        if command -v osascript &>/dev/null; then
            PROMPT_OUT=$(osascript <<EOF 2>/dev/null || true
try
    tell application "System Events"
        activate
        set dialogResult to display dialog "请输入要打包发布的版本号（例如 1.01、1.02）：" & return & return & "· 若同版本已存在，本次打包将直接覆盖" & return & "· 点击「取消」退出" default answer "$DEFAULT_VER" with title "Macrife 发布打包" buttons {"取消", "开始打包"} default button "开始打包" cancel button "取消"
        return text returned of dialogResult
    end tell
on error number -128
    return "__USER_CANCELLED__"
end try
EOF
)
        fi

        if [ "$PROMPT_OUT" = "__USER_CANCELLED__" ]; then
            echo ""
            echo ">>> 用户已取消打包。"
            exit 0
        elif [ -n "$PROMPT_OUT" ]; then
            VERSION=$(echo "$PROMPT_OUT" | xargs)
        elif [ -t 0 ]; then
            read -r -p "请输入要打包发布的版本号 [$DEFAULT_VER]: " USER_INPUT_VER
            USER_INPUT_VER=$(echo "$USER_INPUT_VER" | xargs)
            VERSION="${USER_INPUT_VER:-$DEFAULT_VER}"
        fi
    fi

    VERSION="${VERSION:-$DEFAULT_VER}"
fi

RAW_VER="${VERSION:-1.01}"
VERSION_NUM="${RAW_VER#v}"
TAG_NAME="v$VERSION_NUM"

# 调用根目录 build&pack.command 完成全套构建与 DMG 封装
NO_OPEN=1 "$ROOT_DIR/build&pack.command" "$VERSION_NUM" --tiers "$TIERS" --sign "$SIGN_INPUT" --no-prompt

VERSION_DIR="$RELEASE_DIR/$TAG_NAME"
DMG_PATH="$VERSION_DIR/Macrife-$VERSION_NUM.dmg"
SUMS_PATH="$VERSION_DIR/SHA256SUMS.txt"

cat <<TIP

发布到 GitHub Release（在 release 目录下执行）：
    cd "$RELEASE_DIR"
    gh release create $TAG_NAME --title "Macrife $TAG_NAME" --notes-file RELEASE_NOTES.md \\
        "$TAG_NAME/Macrife-$VERSION_NUM.dmg" "$TAG_NAME/SHA256SUMS.txt"

或在 GitHub 网页新建 Release（Tag 填 $TAG_NAME）后，将 $VERSION_DIR 里的 dmg 与 sha256 拖入附件区。
TIP
