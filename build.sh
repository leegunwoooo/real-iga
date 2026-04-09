#!/bin/bash
set -e

APP_NAME="real-iga"
IDENTITY="real-iga-local-sign"

echo "🔨 Release 빌드 중..."
xcodebuild -scheme ${APP_NAME} -configuration Release \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
  -archivePath ~/Desktop/${APP_NAME}.xcarchive archive

APP_PATH=~/Desktop/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app

echo "🔑 자체 서명 인증서 생성 중..."
security delete-certificate -c "${IDENTITY}" 2>/dev/null || true

cat > /tmp/cert.cfg << CERTEOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
[ dn ]
CN = ${IDENTITY}
CERTEOF

openssl req -x509 -newkey rsa:2048 -keyout /tmp/key.pem \
  -out /tmp/cert.pem -days 3650 -nodes -config /tmp/cert.cfg

openssl pkcs12 -legacy -export -out /tmp/cert.p12 \
  -inkey /tmp/key.pem -in /tmp/cert.pem -passout pass:temp1234

security import /tmp/cert.p12 -k ~/Library/Keychains/login.keychain-db \
  -P "temp1234" -T /usr/bin/codesign -A

security add-trusted-cert -d -r trustRoot \
  -k ~/Library/Keychains/login.keychain-db /tmp/cert.pem

echo "✍️ 앱 서명 중..."
codesign --force --deep --sign "${IDENTITY}" "${APP_PATH}"

echo "📦 /Applications 에 설치 중..."
rm -rf /Applications/${APP_NAME}.app
cp -r "${APP_PATH}" /Applications/

echo "✅ 완료! /Applications/${APP_NAME}.app"
