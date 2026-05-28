#!/usr/bin/env bash

set -euo pipefail

if ! command -v openssl >/dev/null 2>&1; then
  echo "Error: openssl tidak ditemukan di sistem."
  exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CA_CERT="$BASE_DIR/ca.pem"
CA_KEY="$BASE_DIR/ca-key.pem"
CA_SERIAL="$BASE_DIR/ca.srl"
PASSWORD_FILE="$BASE_DIR/password.txt"

if [[ ! -f "$CA_CERT" ]]; then
  echo "Error: file CA cert tidak ditemukan: $CA_CERT"
  exit 1
fi

if [[ ! -f "$CA_KEY" ]]; then
  echo "Error: file CA key tidak ditemukan: $CA_KEY"
  exit 1
fi

read -r -p "Input domain name (contoh: cuydev.local): " DOMAIN
DOMAIN="${DOMAIN// /}"

if [[ -z "$DOMAIN" ]]; then
  echo "Error: domain name wajib diisi."
  exit 1
fi

read -r -p "Input DNS tambahan (optional, pisahkan dengan koma): " EXTRA_DNS
read -r -p "Input IP (optional, default 127.0.0.1): " INPUT_IP
IP_ADDRESS="${INPUT_IP:-127.0.0.1}"
read -r -p "Nama sertifikat berdasarkan domain (y/N): " USE_DOMAIN_FILENAME

USE_DOMAIN_FILENAME="${USE_DOMAIN_FILENAME:-N}"

PASSIN_ARG=()
if [[ -f "$PASSWORD_FILE" ]]; then
  if [[ ! -s "$PASSWORD_FILE" ]]; then
    echo "Error: file password kosong: $PASSWORD_FILE"
    exit 1
  fi
  PASSIN_ARG=(-passin "file:$PASSWORD_FILE")
  echo "Menggunakan pass phrase dari $PASSWORD_FILE"
else
  read -r -s -p "Masukan pass phrase CA key: " CA_PASSPHRASE
  echo

  if [[ -z "$CA_PASSPHRASE" ]]; then
    echo "Error: pass phrase wajib diisi."
    exit 1
  fi
  PASSIN_ARG=(-passin "pass:$CA_PASSPHRASE")
fi

TARGET_DIR="$PWD/generated/$DOMAIN"
mkdir -p "$TARGET_DIR"

if [[ "$USE_DOMAIN_FILENAME" =~ ^[Yy]$ ]]; then
  DOMAIN_FILENAME_BASE="${DOMAIN%%.*}"
  CERT_KEY="$TARGET_DIR/$DOMAIN_FILENAME_BASE-key.pem"
  CERT_FILE="$TARGET_DIR/$DOMAIN_FILENAME_BASE-pub.pem"
  FULLCHAIN_FILE="$TARGET_DIR/$DOMAIN_FILENAME_BASE.pem"
else
  CERT_KEY="$TARGET_DIR/cert-key.pem"
  CERT_FILE="$TARGET_DIR/cert.pem"
  FULLCHAIN_FILE="$TARGET_DIR/fullchain.pem"
fi

CSR_FILE="$TARGET_DIR/cert.csr"
EXTFILE="$TARGET_DIR/extfile.cnf"

echo "Membuat private key di $CERT_KEY"
openssl genrsa -out "$CERT_KEY" 4096

echo "Membuat CSR di $CSR_FILE"
openssl req -new -sha256 -subj "/CN=$DOMAIN" -key "$CERT_KEY" -out "$CSR_FILE"

SAN_ENTRIES=("DNS:$DOMAIN" "DNS:*.$DOMAIN")

if [[ -n "$EXTRA_DNS" ]]; then
  IFS=',' read -r -a EXTRA_DNS_ITEMS <<< "$EXTRA_DNS"
  for item in "${EXTRA_DNS_ITEMS[@]}"; do
    cleaned="${item// /}"
    if [[ -n "$cleaned" ]]; then
      SAN_ENTRIES+=("DNS:$cleaned")
    fi
  done
fi

if [[ -n "$IP_ADDRESS" ]]; then
  SAN_ENTRIES+=("IP:$IP_ADDRESS")
fi

SAN_VALUE=""
for entry in "${SAN_ENTRIES[@]}"; do
  if [[ -z "$SAN_VALUE" ]]; then
    SAN_VALUE="$entry"
  else
    SAN_VALUE="$SAN_VALUE,$entry"
  fi
done

echo "subjectAltName=$SAN_VALUE" > "$EXTFILE"

echo "Menandatangani cert di $CERT_FILE"
if [[ -f "$CA_SERIAL" ]]; then
  openssl x509 -req -sha256 -days 3650 \
    -in "$CSR_FILE" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    "${PASSIN_ARG[@]}" \
    -out "$CERT_FILE" \
    -extfile "$EXTFILE"
else
  openssl x509 -req -sha256 -days 3650 \
    -in "$CSR_FILE" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    "${PASSIN_ARG[@]}" \
    -out "$CERT_FILE" \
    -extfile "$EXTFILE" \
    -CAcreateserial
fi

cat "$CERT_FILE" > "$FULLCHAIN_FILE"
cat "$CA_CERT" >> "$FULLCHAIN_FILE"

echo
echo "Selesai."
echo "Folder output: $TARGET_DIR"
echo "- $CERT_KEY"
echo "- $CSR_FILE"
echo "- $EXTFILE"
echo "- $CERT_FILE"
echo "- $FULLCHAIN_FILE"