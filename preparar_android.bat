@echo off
setlocal
echo === Preparando el proyecto para Android ===
where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: no se encuentra el comando flutter.
  echo Abre esta carpeta en VS Code y ejecuta este archivo desde su terminal,
  echo o agrega la carpeta flutter\bin al PATH de Windows.
  pause
  exit /b 1
)
call flutter create --platforms=android --project-name plan_pagos --org bo.planpagos .
if errorlevel 1 (
  echo ERROR al ejecutar flutter create.
  pause
  exit /b 1
)
if exist test\widget_test.dart del test\widget_test.dart
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0aplicar_android.ps1"
call flutter pub get
echo.
echo Listo. Ahora edita lib\config.dart con la URL de tu API
echo y luego ejecuta construir_apk.bat para generar el APK.
pause
