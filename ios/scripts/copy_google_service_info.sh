#!/bin/bash

# Flutter FlavorごとにGoogleService-Info.plistを切り替えるスクリプト
# Xcode Build Phases > Run Script に追加して使用

# デバッグ用ログ
echo "Running copy_google_service_info.sh"
echo "CONFIGURATION: ${CONFIGURATION}"
echo "SRCROOT: ${SRCROOT}"

# Configurationからflavorを判定
# Debug-dev, Release-dev → dev
# Debug-prod, Release-prod, Debug, Release → prod
if [[ "${CONFIGURATION}" == *"-dev"* ]] || [[ "${CONFIGURATION}" == *"Dev"* ]]; then
    FLAVOR="dev"
else
    FLAVOR="prod"
fi

echo "Detected FLAVOR: ${FLAVOR}"

# コピー元とコピー先のパス
SOURCE_PLIST="${SRCROOT}/Runner/${FLAVOR}/GoogleService-Info.plist"
DEST_PLIST="${SRCROOT}/Runner/GoogleService-Info.plist"

echo "Source: ${SOURCE_PLIST}"
echo "Destination: ${DEST_PLIST}"

# ファイルの存在チェック
if [ -f "${SOURCE_PLIST}" ]; then
    cp "${SOURCE_PLIST}" "${DEST_PLIST}"
    echo "Successfully copied GoogleService-Info.plist for ${FLAVOR} environment"
else
    echo "error: GoogleService-Info.plist not found at ${SOURCE_PLIST}"
    exit 1
fi
