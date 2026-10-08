@echo off
title Kasir-AI Build Scripts
color 0B
setlocal enabledelayedexpansion

echo ============================================
echo        KASIR-AI - Build Helper
echo ============================================
echo.
echo Pilih yang ingin di-build:
echo.
echo   [1] Flutter Web (untuk browser)
echo   [2] Flutter APK (untuk Android)
echo   [3] API TypeScript (rebuild dist/)
echo   [4] Semua (Web + API dist)
echo   [5] Keluar
echo.
set /p CHOICE=Pilihan (1-5): 

if "%CHOICE%"=="1" goto BUILD_WEB
if "%CHOICE%"=="2" goto BUILD_APK
if "%CHOICE%"=="3" goto BUILD_API
if "%CHOICE%"=="4" goto BUILD_ALL
if "%CHOICE%"=="5" exit /b 0
echo Pilihan tidak valid.
pause
exit /b 1

:: ─────────────────────────────────────────────────────────────────
:BUILD_WEB
:: ─────────────────────────────────────────────────────────────────
echo.
echo [BUILD] Flutter Web (release, no WASM, --pwa-strategy=none)
echo.
cd apps\mobile
call C:\flutter\bin\flutter.bat build web --release --no-wasm-dry-run --pwa-strategy=none
if errorlevel 1 (
    echo [ERROR] Flutter Web build GAGAL!
    cd ..\..
    pause
    exit /b 1
)
cd ..\..
echo.
echo [OK] Output: apps\mobile\build\web\
echo [OK] Serve dengan: start.bat --skip-build
echo.

:: Tampilkan ukuran main.dart.js
for %%f in (apps\mobile\build\web\main.dart.js) do (
    set /a SIZE_KB=%%~zf/1024
    echo [INFO] main.dart.js ukuran: !SIZE_KB! KB
)

:: Cek apakah main.dart.js mengandung string kunci UI baru
findstr /c:"Laporan Penjualan" apps\mobile\build\web\main.dart.js > nul 2>&1
if not errorlevel 1 (
    echo [OK] main.dart.js mengandung string UI terbaru.
) else (
    echo [WARN] String UI tidak ditemukan di main.dart.js.
)
pause
goto END

:: ─────────────────────────────────────────────────────────────────
:BUILD_APK
:: ─────────────────────────────────────────────────────────────────
echo.
echo [BUILD] Flutter APK (release)
echo.
echo PERHATIAN: Untuk menghindari APK lama ter-install:
echo   - Uninstall APK lama dari HP dulu, ATAU
echo   - Pastikan versionCode di-bump di pubspec.yaml
echo.
cd apps\mobile
call C:\flutter\bin\flutter.bat build apk --release
if errorlevel 1 (
    echo [ERROR] Flutter APK build GAGAL!
    cd ..\..
    pause
    exit /b 1
)
cd ..\..

set APK_PATH=apps\mobile\build\app\outputs\flutter-apk\app-release.apk
if exist "%APK_PATH%" (
    for %%f in ("%APK_PATH%") do (
        set /a APK_MB=%%~zf/1048576
        echo [OK] APK: %APK_PATH%
        echo [OK] Ukuran: !APK_MB! MB
    )
) else (
    echo [WARN] APK tidak ditemukan di path yang diharapkan.
    echo        Cek: apps\mobile\build\app\outputs\flutter-apk\
)
pause
goto END

:: ─────────────────────────────────────────────────────────────────
:BUILD_API
:: ─────────────────────────────────────────────────────────────────
echo.
echo [BUILD] API TypeScript -> dist/
echo.
cd apps\api
npm.cmd run build
if errorlevel 1 (
    echo.
    echo [ERROR] TypeScript compile GAGAL!
    echo         Cek error di atas. Jalankan untuk detail:
    echo         cd apps\api ^&^& npm.cmd exec tsc -- --noEmit
    cd ..\..
    pause
    exit /b 1
)
cd ..\..

echo.
echo [OK] dist/ berhasil diperbarui.

:: Validasi route file kunci
set MISSING=0
for %%f in (attendance financeReports inventoryReports customerReports staffReports taxReports purchasingReports customers) do (
    if not exist "apps\api\dist\routes\%%f.routes.js" (
        echo [WARN] HILANG: dist\routes\%%f.routes.js
        set MISSING=1
    )
)
if !MISSING!==0 (
    echo [OK] Semua route file ada di dist/.
)
pause
goto END

:: ─────────────────────────────────────────────────────────────────
:BUILD_ALL
:: ─────────────────────────────────────────────────────────────────
echo.
echo [BUILD] Build semua: Web + API dist
echo.
call :BUILD_WEB_SILENT
call :BUILD_API_SILENT
echo.
echo [OK] Semua build selesai.
pause
goto END

:BUILD_WEB_SILENT
cd apps\mobile
call C:\flutter\bin\flutter.bat build web --release --no-wasm-dry-run --pwa-strategy=none
cd ..\..
goto :eof

:BUILD_API_SILENT
cd apps\api
npm.cmd run build
cd ..\..
goto :eof

:END
echo.
endlocal
