@echo off
title Kasir-AI Server
color 0A

echo ============================================
echo         KASIR-AI - Starting Server
echo ============================================
echo.

:: Auto-detect local IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set LOCAL_IP=%%a
)
set LOCAL_IP=%LOCAL_IP: =%

echo [INFO] IP Lokal Anda: %LOCAL_IP%
echo.

:: Update Flutter api_config.dart with detected IP
echo [1/3] Mengatur IP di aplikasi...
(
echo import 'package:shared_preferences/shared_preferences.dart';
echo.
echo class ApiConfig {
echo   // Auto-configured by start.bat
echo   static String _baseUrl = 'http://%LOCAL_IP%:3001/api';
echo   static const int connectTimeout = 10;
echo   static const int receiveTimeout = 30;
echo.
echo   static String get baseUrl =^> _baseUrl;
echo   static set baseUrl^(String url^) =^> _baseUrl = url;
echo.
echo   static Future^<void^> loadSavedUrl^(^) async {
echo     final prefs = await SharedPreferences.getInstance^(^);
echo     final saved = prefs.getString^('api_base_url'^);
echo     if ^(saved != null ^&^& saved.isNotEmpty^) {
echo       if ^(saved.contains^(':3001/api'^)^) {
echo         _baseUrl = saved;
echo       } else {
echo         await prefs.remove^('api_base_url'^);
echo       }
echo     }
echo   }
echo.
echo   static Future^<void^> setBaseUrl^(String url^) async {
echo     _baseUrl = url;
echo     final prefs = await SharedPreferences.getInstance^(^);
echo     await prefs.setString^('api_base_url', url^);
echo   }
echo }
) > apps\mobile\lib\config\api_config.dart

:: Build Flutter Web only if not already built or if --rebuild flag
if "%1"=="--rebuild" goto DO_BUILD
if exist "apps\mobile\build\web\main.dart.js" (
    echo [2/3] Web sudah di-build sebelumnya, skip build.
    echo       ^(Gunakan: start.bat --rebuild untuk build ulang^)
    goto SKIP_BUILD
)

:DO_BUILD
echo [2/3] Building Flutter Web... ^(~90 detik^)
cd apps\mobile
call C:\flutter\bin\flutter.bat build web --release --no-wasm-dry-run
cd ..\..

:SKIP_BUILD

:: Ensure serve.json exists for cache control
echo {"headers":[{"source":"**/*.js","headers":[{"key":"Cache-Control","value":"no-cache, no-store, must-revalidate"}]},{"source":"**/*.html","headers":[{"key":"Cache-Control","value":"no-cache, no-store, must-revalidate"}]}]} > apps\mobile\build\web\serve.json

:: Start API in background
echo [3/3] Menjalankan server...
start /b cmd /c "cd apps\api && npm run dev"

:: Wait for API to start
timeout /t 3 /nobreak > nul

:: Serve Flutter Web
echo.
echo ============================================
echo   KASIR-AI SIAP DIGUNAKAN!
echo ============================================
echo.
echo   BROWSER (PC/HP):
echo   - PC ini    : http://localhost:8081
echo   - HP/Tablet : http://%LOCAL_IP%:8081
echo.
echo   APLIKASI ANDROID (APK):
echo   - API Server: http://%LOCAL_IP%:3001
echo   - Pastikan IP di pengaturan app = %LOCAL_IP%
echo.
echo   Pastikan semua device terhubung ke
echo   Wi-Fi yang SAMA.
echo.
echo   Tekan Ctrl+C untuk menghentikan server.
echo ============================================
echo.

cd apps\mobile
npx -y serve build\web -l 8081 --cors
