#!/bin/bash
set -e

APP_NAME="real-iga"
IDENTITY_NAME="real-iga Local Signing"
KEYCHAIN_PATH="$HOME/Library/Keychains/login.keychain-db"
PKCS12_PASSWORD="real-iga-local-signing"

echo "🔑 자체 서명 인증서 생성 중..."
EXISTING=$(security find-certificate -Z -a -c "$IDENTITY_NAME" "$KEYCHAIN_PATH" 2>/dev/null | awk '/SHA-1 hash:/ { print $3; exit }' || true)

if [[ -z "$EXISTING" ]]; then
  WORK_DIR=$(mktemp -d)
  trap 'rm -rf "$WORK_DIR"' EXIT

  cat > "$WORK_DIR/openssl.cnf" <<'OPENSSLEOF'
[ req ]
default_bits = 2048
distinguished_name = dn
x509_extensions = ext
prompt = no
[ dn ]
CN = real-iga Local Signing
[ ext ]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
OPENSSLEOF

  openssl genrsa -out "$WORK_DIR/key.pem" 2048 >/dev/null 2>&1
  openssl req -new -x509 -days 3650 -key "$WORK_DIR/key.pem" \
    -out "$WORK_DIR/cert.pem" -config "$WORK_DIR/openssl.cnf" >/dev/null 2>&1
  openssl pkcs12 -legacy -export -inkey "$WORK_DIR/key.pem" \
    -in "$WORK_DIR/cert.pem" -out "$WORK_DIR/cert.p12" \
    -passout pass:"$PKCS12_PASSWORD" >/dev/null 2>&1
  security import "$WORK_DIR/cert.p12" -k "$KEYCHAIN_PATH" \
    -P "$PKCS12_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security >/dev/null
  echo "✅ 인증서 생성 완료"
else
  echo "✅ 기존 인증서 사용"
fi

echo "🔨 Release 빌드 중..."
xcodebuild -scheme ${APP_NAME} -configuration Release \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
  -archivePath ~/Desktop/${APP_NAME}.xcarchive archive

APP_PATH=~/Desktop/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app

echo "✍️ 앱 서명 중..."
codesign --force --deep --sign "$IDENTITY_NAME" "$APP_PATH"

echo "📦 /Applications 에 설치 중..."
rm -rf /Applications/${APP_NAME}.app
cp -r "$APP_PATH" /Applications/

echo "🍺 완료! /Applications/${APP_NAME}.app"
