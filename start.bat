@echo off
title Kasir-AI Server
color 0A

echo ============================================
echo         KASIR-AI - Starting Server
echo ============================================
echo.

:: Auto-detect local IP (skip loopback, get first real IPv4)
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set LOCAL_IP=%%a
)
set LOCAL_IP=%LOCAL_IP: =%

echo [INFO] IP Lokal Anda: %LOCAL_IP%
echo.

:: ─────────────────────────────────────────────
:: [0/3] Start MySQL (XAMPP) jika belum aktif
:: ─────────────────────────────────────────────
echo [0/3] Memeriksa dan menyalakan MySQL...

net start mysql > nul 2>&1

set DB_RETRY=0
:WAIT_DB
netstat -ano | findstr ":3306" > nul 2>&1
if errorlevel 1 (
    set /a DB_RETRY+=1
    if %DB_RETRY% geq 10 (
        echo.
        echo [ERROR] MySQL tidak dapat dijalankan setelah 30 detik!
        echo         Pastikan XAMPP sudah terinstall dan MySQL diaktifkan.
        echo         Buka XAMPP Control Panel lalu klik START pada MySQL.
        echo.
        pause
        exit /b 1
    )
    echo [!] Menunggu MySQL aktif... (%DB_RETRY%/10^)
    timeout /t 3 /nobreak > nul
    goto WAIT_DB
)
echo [OK] MySQL aktif di port 3306.
echo.

:: ─────────────────────────────────────────────
:: Update .env API dengan IP lokal saat ini
:: ─────────────────────────────────────────────
powershell -Command "(Get-Content 'apps\api\.env') -replace 'BETTER_AUTH_URL=.*', 'BETTER_AUTH_URL=http://%LOCAL_IP%:3001' -replace 'CORS_ORIGIN=.*', 'CORS_ORIGIN=http://%LOCAL_IP%:8081' | Set-Content 'apps\api\.env'"
echo [OK] Konfigurasi API diperbarui dengan IP: %LOCAL_IP%
echo.

:: ─────────────────────────────────────────────
:: Matikan proses lama di port 8081 jika ada
:: (memastikan file terbaru selalu disajikan)
:: ─────────────────────────────────────────────
echo [INFO] Memeriksa dan menutup proses lama di port 8081...
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":8081 "') do (
    taskkill /PID %%p /F > nul 2>&1
)
echo [OK] Port 8081 bersih.
echo.

:: ─────────────────────────────────────────────
:: [1/3] Build Flutter Web
:: Gunakan --skip-build untuk melewati build
:: ─────────────────────────────────────────────
if "%1"=="--skip-build" (
    echo [1/3] Skip build ^(--skip-build flag aktif^).
    goto SKIP_BUILD
)

echo [1/3] Building Flutter Web... ^(~60 detik^)
cd apps\mobile
call C:\flutter\bin\flutter.bat build web --release --no-wasm-dry-run
cd ..\..
echo [OK] Flutter Web berhasil di-build.
echo.

:SKIP_BUILD

:: Buat serve.json - nonaktifkan cache browser sepenuhnya
echo {"headers":[{"source":"**","headers":[{"key":"Cache-Control","value":"no-cache, no-store, must-revalidate"},{"key":"Pragma","value":"no-cache"},{"key":"Expires","value":"0"}]}]} > apps\mobile\build\web\serve.json

:: ─────────────────────────────────────────────
:: [2/3] Jalankan API Backend
:: ─────────────────────────────────────────────
echo [2/3] Menjalankan API backend...
start /b cmd /c "cd apps\api && npm run dev"
timeout /t 3 /nobreak > nul
echo [OK] API backend berjalan di port 3001.
echo.

:: ─────────────────────────────────────────────
:: [3/3] Jalankan Flutter Web Server
:: ─────────────────────────────────────────────
echo [3/3] Menjalankan web server...
echo.
echo ============================================
echo   KASIR-AI SIAP DIGUNAKAN!
echo ============================================
echo.
echo   BROWSER (PC/HP):
echo   - PC ini    : http://localhost:8081
echo   - HP/Tablet : http://%LOCAL_IP%:8081
echo   ^(IP otomatis terdeteksi oleh aplikasi^)
echo.
echo   Untuk rebuild setelah perubahan kode:
echo   ^> Tutup window ini ^(Ctrl+C^)
echo   ^> Jalankan lagi: start.bat
echo.
echo   Untuk jalankan TANPA rebuild ^(lebih cepat^):
echo   ^> start.bat --skip-build
echo.
echo   Pastikan semua device terhubung ke
echo   Wi-Fi yang SAMA.
echo.
echo   Tekan Ctrl+C untuk menghentikan server.
echo ============================================
echo.

cd apps\mobile
npx -y serve build\web -l 8081 --cors --no-clipboard
