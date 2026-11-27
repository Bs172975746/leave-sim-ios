#!/usr/bin/env bash
# 在任意一台 macOS（本机或云主机）上一条命令产出未签名 ipa。
# 用法：bash scripts/make_ipa.sh
set -euo pipefail
cd "$(dirname "$0")/.."

SCHEME=LeaveSim
APP=LeaveSim

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "没有 xcodebuild：这台机器不是 macOS，或者没装 Xcode。"
  exit 1
fi

if [ ! -d "${APP}.xcodeproj" ]; then
  echo "== 用 XcodeGen 从 project.yml 生成工程 =="
  if ! command -v xcodegen >/dev/null 2>&1; then
    command -v brew >/dev/null 2>&1 && brew install xcodegen || {
      echo "先生成工程再跑：brew install xcodegen && xcodegen generate"
      exit 1
    }
  fi
  xcodegen generate
fi

echo "== 编译（不签名）=="
xcodebuild \
  -project "${APP}.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

echo "== 打 ipa =="
rm -rf Payload "${APP}-unsigned.ipa"
mkdir -p Payload
cp -R "build/Build/Products/Release-iphoneos/${APP}.app" Payload/
zip -qry "${APP}-unsigned.ipa" Payload
ls -l "${APP}-unsigned.ipa"
echo "完成：$(pwd)/${APP}-unsigned.ipa —— 传到手机上用轻松签/全能签/ESign 自签安装即可。"
