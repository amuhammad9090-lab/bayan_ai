#!/usr/bin/env bash
# Jalankan dari folder android/ :  bash create_keystore.sh
# Hasil: android/app/upload-keystore.jks  (BACKUP file ini + passwordnya!)
set -e
keytool -genkeypair -v \
  -keystore app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
echo
echo "Selesai. Sekarang: cp key.properties.example key.properties  lalu isi password-nya."
