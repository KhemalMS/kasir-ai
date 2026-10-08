@echo off
title Kasir-AI Server
color 0A
setlocal enabledelayedexpansion

echo ============================================
echo         KASIR-AI - Starting Server
echo ============================================
echo.

:: ─── Timestamp build (untuk verifikasi versi di browser) ────────
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value 2^>nul') do (
    if not "%%a"=="" set DT=%%a
)
set BUILD_TS=%DT:~0,4%-%DT:~4,2%-%DT:~6,2% %DT:~8,2%:%DT:~10,2%:%DT:~12,2%
echo [INFO] Start time  : %BUILD_TS%

:: ─── Auto-detect IP lokal (skip loopback, ambil yang pertama) ───
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set LOCAL_IP=%%a
)
set LOCAL_IP=%LOCAL_IP: =%
echo [INFO] IP Lokal    : %LOCAL_IP%
echo.

:: ─────────────────────────────────────────────────────────────────
:: [1/5] MySQL
:: ─────────────────────────────────────────────────────────────────
echo [1/5] Memeriksa MySQL (port 3306)...
net start mysql > nul 2>&1

set DB_RETRY=0
:WAIT_DB
netstat -ano | findstr ":3306 " > nul 2>&1
if errorlevel 1 (
    set /a DB_RETRY+=1
    if !DB_RETRY! geq 10 (
        echo.
        echo [ERROR] MySQL tidak aktif setelah 30 detik!
        echo         Buka XAMPP Control Panel, klik START pada MySQL.
        echo.
        pause
        exit /b 1
    )
    echo [!] Menunggu MySQL... (!DB_RETRY!/10^)
    timeout /t 3 /nobreak > nul
    goto WAIT_DB
)
echo [OK] MySQL aktif di port 3306.
echo.

:: ─────────────────────────────────────────────────────────────────
:: [2/5] Update .env API dengan IP lokal
:: ─────────────────────────────────────────────────────────────────
echo [2/5] Memperbarui konfigurasi API...
powershell -Command "(Get-Content 'apps\api\.env') -replace 'BETTER_AUTH_URL=.*', 'BETTER_AUTH_URL=http://%LOCAL_IP%:3001' -replace 'CORS_ORIGIN=.*', 'CORS_ORIGIN=http://localhost:8081,http://127.0.0.1:8081,http://%LOCAL_IP%:8081,http://localhost:5173' | Set-Content 'apps\api\.env'"
echo [OK] BETTER_AUTH_URL = http://%LOCAL_IP%:3001
echo [OK] CORS_ORIGIN     = localhost:8081 + 127.0.0.1:8081 + %LOCAL_IP%:8081 + localhost:5173
echo.

:: ─────────────────────────────────────────────────────────────────
:: [3/5] Kill proses lama di port 3001 (API) DAN 8081 (Web)
::       KRITIS: port 3001 harus dimatikan agar instance API baru
::       bisa start. Tanpa ini, tsx watch lama tetap berjalan
::       dan perubahan source tidak terlihat.
:: ─────────────────────────────────────────────────────────────────
echo [3/5] Menutup proses lama di port 3001 dan 8081...

for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3001 " 2^>nul') do (
    if not "%%p"=="" taskkill /PID %%p /F > nul 2>&1
)
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":8081 " 2^>nul') do (
    if not "%%p"=="" taskkill /PID %%p /F > nul 2>&1
)
timeout /t 1 /nobreak > nul
echo [OK] Port 3001 dan 8081 bersih.
echo.

:: ─────────────────────────────────────────────────────────────────
:: [4/5] Flutter Web Build
::       Skip dengan: start.bat --skip-build
:: ─────────────────────────────────────────────────────────────────
if "%1"=="--skip-build" (
    echo [4/5] Skip Flutter build ^(--skip-build aktif^).
    echo       Menggunakan build terakhir.
    goto SKIP_FLUTTER_BUILD
)

echo [4/5] Building Flutter Web... ^(estimasi 60-90 detik^)
cd apps\mobile
call C:\flutter\bin\flutter.bat build web --release --no-wasm-dry-run --pwa-strategy=none
if errorlevel 1 (
    echo.
    echo [ERROR] Flutter build GAGAL! Cek error di atas.
    cd ..\..
    pause
    exit /b 1
)
cd ..\..
echo [OK] Flutter Web build selesai.

:SKIP_FLUTTER_BUILD

:: ─── Write serve.json: header Cache-Control no-store ────────────
:: (satu baris PowerShell, tanpa multi-line continuation)
powershell -Command "Set-Content -Path 'apps\mobile\build\web\serve.json' -Value '{\"headers\":[{\"source\":\"**\",\"headers\":[{\"key\":\"Cache-Control\",\"value\":\"no-store, no-cache, must-revalidate, max-age=0\"},{\"key\":\"Pragma\",\"value\":\"no-cache\"},{\"key\":\"Expires\",\"value\":\"0\"}]}]}'"

:: ─── Inject build timestamp ke version.json ─────────────────────
powershell -Command "try { $v = Get-Content 'apps\mobile\build\web\version.json' | ConvertFrom-Json; Add-Member -InputObject $v -NotePropertyName 'buildTime' -NotePropertyValue '%BUILD_TS%' -Force; $v | ConvertTo-Json | Set-Content 'apps\mobile\build\web\version.json'; Write-Host '[OK] version.json: %BUILD_TS%' } catch { Write-Host '[WARN] version.json update skipped' }"
echo.

:: ─────────────────────────────────────────────────────────────────
:: [5/5] Start API Backend (tsx watch - baca langsung dari src/)
::       Buka di window terpisah agar log API terlihat
:: ─────────────────────────────────────────────────────────────────
echo [5/5] Menjalankan API backend (tsx watch)...
pushd apps\api
start "Kasir-AI API [port 3001]" cmd /k "echo. && echo [API] Kasir-AI Backend - mode DEV (tsx watch src/) && echo [API] Port 3001 && echo. && npm.cmd run dev"
popd
echo [INFO] Window API terbuka. Tunggu API aktif...

:: ─── Tunggu API aktif (cek port 3001 terbuka) ───────────────────
set API_RETRY=0
:WAIT_API
timeout /t 2 /nobreak > nul
netstat -ano | findstr ":3001 " > nul 2>&1
if not errorlevel 1 goto API_READY
set /a API_RETRY+=1
if !API_RETRY! geq 15 (
    echo.
    echo [WARN] API belum aktif setelah 30 detik!
    echo        Cek window "Kasir-AI API [port 3001]" untuk pesan error.
    echo        Kemungkinan penyebab:
    echo          1. npm.cmd tidak ditemukan (Node.js belum di PATH)
    echo          2. Port 3001 masih terpakai (proses lain)
    echo          3. Error TypeScript di src/
    echo.
    echo   Tekan tombol apa saja untuk lanjut ke web server...
    pause > nul
    goto SKIP_API_WAIT
)
if !API_RETRY!==3  echo [!] Menunggu API aktif... (!API_RETRY!/15^)
if !API_RETRY!==6  echo [!] Menunggu API aktif... (!API_RETRY!/15^)
if !API_RETRY!==9  echo [!] Menunggu API aktif... (!API_RETRY!/15^)
if !API_RETRY!==12 echo [!] Menunggu API aktif... (!API_RETRY!/15^)
goto WAIT_API

:API_READY
echo [OK] API aktif di port 3001.

:SKIP_API_WAIT
echo.

:: ─────────────────────────────────────────────────────────────────
:: Jalankan Web Server (npx serve - Flutter Web di port 8081)
:: ─────────────────────────────────────────────────────────────────
echo ============================================
echo   KASIR-AI SIAP DIGUNAKAN!
echo ============================================
echo.
echo   Build time : %BUILD_TS%
echo.
echo   BROWSER (PC / HP):
echo   - PC ini    : http://localhost:8081
echo   - HP/Tablet : http://%LOCAL_IP%:8081
echo     ^(Semua device harus di Wi-Fi yang sama^)
echo.
echo   Verifikasi build terbaru di browser:
echo     Buka DevTools ^(F12^) ^> Console
echo     Ketik: fetch('/version.json').then(r=^>r.json()).then(console.log)
echo     Cek field 'buildTime' sesuai waktu di atas.
echo.
echo   Jika UI belum update:
echo     1. Hard Refresh: Ctrl+Shift+R
echo     2. Buka tab Incognito
echo     3. DevTools ^> Application ^> Service Workers ^> Unregister All
echo.
echo   Rebuild setelah ubah kode    : start.bat
echo   Skip Flutter build (cepat)   : start.bat --skip-build
echo   Build APK / API / Web manual : build.bat
echo.
echo   Ctrl+C = hentikan web server.
echo   Window API tetap berjalan; tutup manual jika perlu.
echo ============================================
echo.

cd apps\mobile
npx -y serve build\web -l 8081 --cors --no-clipboard
