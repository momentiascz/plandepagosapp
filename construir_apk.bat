@echo off
call flutter build apk --release
if errorlevel 1 (
  echo ERROR al compilar. Revisa el mensaje de arriba.
  pause
  exit /b 1
)
echo.
echo APK generado en: build\app\outputs\flutter-apk\app-release.apk
start "" "build\app\outputs\flutter-apk"
pause
