#!/usr/bin/env bash

set -euo pipefail

if ! command -v openssl >/dev/null 2>&1; then
  echo "Error: openssl tidak ditemukan di sistem."
  exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CA_KEY="$BASE_DIR/ca-key.pem"
CA_CERT="$BASE_DIR/ca.pem"
CA_SERIAL="$BASE_DIR/ca.srl"
PASSWORD_FILE="$BASE_DIR/password.txt"

if [[ -f "$CA_KEY" || -f "$CA_CERT" ]]; then
  read -r -p "File CA sudah ada. Overwrite (y/N): " OVERWRITE
  OVERWRITE="${OVERWRITE:-N}"
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo "Dibatalkan."
    exit 0
  fi
fi

read -r -p "Input CA Common Name (default: Local Root CA): " INPUT_CA_CN
CA_CN="${INPUT_CA_CN:-Local Root CA}"

read -r -p "Masa berlaku CA dalam hari (default: 3650): " INPUT_CA_DAYS
CA_DAYS="${INPUT_CA_DAYS:-3650}"

if [[ ! "$CA_DAYS" =~ ^[0-9]+$ ]]; then
  echo "Error: masa berlaku harus berupa angka."
  exit 1
fi

read -r -s -p "Masukan pass phrase baru untuk CA key: " CA_PASSPHRASE
echo
read -r -s -p "Ulangi pass phrase: " CA_PASSPHRASE_CONFIRM
echo

if [[ -z "$CA_PASSPHRASE" ]]; then
  echo "Error: pass phrase wajib diisi."
  exit 1
fi

if [[ "$CA_PASSPHRASE" != "$CA_PASSPHRASE_CONFIRM" ]]; then
  echo "Error: konfirmasi pass phrase tidak sama."
  exit 1
fi

echo "Membuat CA private key di $CA_KEY"
openssl genrsa -aes256 -passout "pass:$CA_PASSPHRASE" -out "$CA_KEY" 4096

echo "Membuat self-signed CA cert di $CA_CERT"
openssl req -x509 -new -sha256 -days "$CA_DAYS" \
  -subj "/CN=$CA_CN" \
  -key "$CA_KEY" \
  -passin "pass:$CA_PASSPHRASE" \
  -out "$CA_CERT"

if [[ -f "$CA_SERIAL" ]]; then
  rm -f "$CA_SERIAL"
fi

read -r -p "Simpan pass phrase ke password.txt (y/N): " SAVE_PASSWORD_FILE
SAVE_PASSWORD_FILE="${SAVE_PASSWORD_FILE:-N}"
if [[ "$SAVE_PASSWORD_FILE" =~ ^[Yy]$ ]]; then
  printf '%s\n' "$CA_PASSPHRASE" > "$PASSWORD_FILE"
  chmod 600 "$PASSWORD_FILE"
  echo "Pass phrase disimpan ke $PASSWORD_FILE"
fi

echo
echo "Selesai membuat CA."
echo "- $CA_KEY"
echo "- $CA_CERT"
