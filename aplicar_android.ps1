# Ajusta el AndroidManifest generado por Flutter: permiso de internet,
# trafico http (pruebas) y nombre visible de la app.
$m = Join-Path $PSScriptRoot "android\app\src\main\AndroidManifest.xml"
if (-not (Test-Path $m)) { Write-Host "No se encontro $m"; exit 1 }
$t = Get-Content $m -Raw -Encoding UTF8

if ($t -notmatch 'android.permission.INTERNET') {
  $t = $t -replace '<application', "<uses-permission android:name=`"android.permission.INTERNET`"/>`r`n    <application"
}
if ($t -notmatch 'usesCleartextTraffic') {
  $t = $t -replace '<application', '<application android:usesCleartextTraffic="true"'
}
$t = $t -replace 'android:label="[^"]*"', 'android:label="Mi Plan de Pagos"'

Set-Content -Path $m -Value $t -Encoding UTF8
Write-Host "AndroidManifest.xml configurado (INTERNET + http + nombre)."
