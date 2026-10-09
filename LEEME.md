# Mi Plan de Pagos — app Flutter

App móvil (Android / iOS) que reemplaza el frontend web de `plandepagos`
(index.html + css + js) y **usa la misma API PHP** (`api/*.php`) y la misma base
MariaDB. El backend no se modifica: la app nunca se conecta a la base de datos,
solo llama a los endpoints.

## Pasos rápidos (Windows)

1. Descomprime el zip y abre la carpeta en VS Code (Archivo > Abrir carpeta).
2. Doble clic en **`preparar_android.bat`** (o ejecútalo en la terminal de VS Code).
   Crea la carpeta `android/`, agrega el permiso de internet y descarga las dependencias.
3. Edita **`lib/config.dart`** con la URL de tu API (ver tabla abajo).
4. Para probar: conecta el celular por USB (depuración activada) y presiona F5.
5. Para generar el APK: doble clic en **`construir_apk.bat`**.
   Queda en `build\app\outputs\flutter-apk\app-release.apk`; cópialo al celular e instálalo
   (permite "instalar apps de orígenes desconocidos").

### URL de la API (`lib/config.dart`)

| Dónde corre la app | `apiBase` |
|---|---|
| Emulador Android (XAMPP en tu PC) | `http://10.0.2.2/plan-pagos/api/` |
| Celular real, misma WiFi que tu PC | `http://IP_DE_TU_PC/plan-pagos/api/` |
| Servidor en internet (HTTPS) | `https://dzire.duckdns.org/api/` |

Debe terminar en `/`. Para el celular real, Apache debe aceptar conexiones de la red
y el firewall de Windows debe permitir el puerto 80. El APK queda con la URL que tenga
`config.dart` al compilar: cámbiala antes de generarlo.

### Si prefieres hacerlo a mano

`flutter create --platforms=android --project-name plan_pagos --org bo.planpagos .`
y en `android/app/src/main/AndroidManifest.xml` agrega antes de `<application`:
`<uses-permission android:name="android.permission.INTERNET"/>` y, si usas `http://`,
`android:usesCleartextTraffic="true"` dentro de `<application`.

## Equivalencias con la versión web

| Web (PHP/JS) | Flutter |
|---|---|
| `js/app.js` (fetch + cálculos) | `lib/services/api_client.dart`, `lib/models/plan.dart`, `lib/state/plan_controller.dart` |
| Pantalla "Acceso restringido" (email) | `lib/screens/access_screen.dart` |
| Dashboard, estadísticas SVG | `home_screen.dart`, `widgets/charts.dart` (dona y barras con CustomPainter) |
| Tabla de cuotas | Lista de tarjetas (la tabla no cabe en el celular) |
| Modales de detalle / pago | Bottom sheets: `detalle_cuota.dart`, `pago_form.dart` |
| Login admin, editar plan | `dialogs.dart` |
| Visor de comprobantes | `comprobante_viewer.dart` (imagen con zoom; PDF se abre en el navegador) |
| Tema claro/oscuro (localStorage) | `shared_preferences` |
| Sesión PHP (cookie `PHPSESSID`) | Se guarda y reenvía manualmente en `ApiClient` |

No incluido: el botón "Restablecer datos" (en la web ya estaba comentado).
