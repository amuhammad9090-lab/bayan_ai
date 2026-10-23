@echo off
REM Jalankan dari folder android\ :  create_keystore.bat
REM Hasil: android\app\upload-keystore.jks  (BACKUP file ini + passwordnya!)
keytool -genkeypair -v -keystore app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
echo.
echo Selesai. Sekarang: copy key.properties.example key.properties  lalu isi password-nya.
