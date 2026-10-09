import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/plan.dart';

class ApiException implements Exception {
  final String message;
  final int? status; // null = error de red / sin respuesta
  ApiException(this.message, {this.status});
  @override
  String toString() => message;
}

/// Cliente de la API PHP (carpeta api/). La sesión de administrador de PHP
/// vive en la cookie PHPSESSID, que aquí se guarda y se reenvía a mano.
class ApiClient {
  static const _kCookie = 'cookieSesion';
  static const _timeout = Duration(seconds: 20);

  SharedPreferences? _prefs;
  String? _cookie;

  void init(SharedPreferences prefs) {
    _prefs = prefs;
    _cookie = prefs.getString(_kCookie);
  }

  Uri _u(String archivo) => Uri.parse('${AppConfig.apiBase}$archivo');
  String urlComprobante(int id) => '${AppConfig.apiBase}comprobante.php?id=$id';

  Map<String, String> _headers({bool json = false}) => {
        if (json) 'Content-Type': 'application/json',
        if (_cookie != null) 'Cookie': _cookie!,
      };

  void _guardarCookie(Map<String, String> headers) {
    final raw = headers['set-cookie'];
    if (raw == null) return;
    final m = RegExp(r'PHPSESSID=([^;,\s]+)').firstMatch(raw);
    if (m != null) {
      _cookie = 'PHPSESSID=${m.group(1)}';
      _prefs?.setString(_kCookie, _cookie!);
    }
  }

  Map<String, dynamic> _procesar(http.Response r) {
    _guardarCookie(r.headers);
    var cuerpo = <String, dynamic>{};
    try {
      final d = jsonDecode(utf8.decode(r.bodyBytes));
      if (d is Map<String, dynamic>) cuerpo = d;
    } catch (_) {}
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(
        (cuerpo['error'] as String?) ?? 'Error del servidor (${r.statusCode}).',
        status: r.statusCode,
      );
    }
    return cuerpo;
  }

  Future<Map<String, dynamic>> _llamar(Future<http.Response> Function() f) async {
    try {
      return _procesar(await f().timeout(_timeout));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder.');
    } on SocketException {
      throw ApiException('Sin conexión con el servidor. Revisa la URL de la API y tu red.');
    } on http.ClientException {
      throw ApiException('No se pudo conectar con el servidor.');
    }
  }

  Future<Map<String, dynamic>> _postJson(String archivo, Map<String, dynamic> cuerpo) =>
      _llamar(() => http.post(_u(archivo), headers: _headers(json: true), body: jsonEncode(cuerpo)));

  // ---------------- Acceso y sesión ----------------

  Future<void> verificarAcceso(String email) async {
    await _postJson('verificar_acceso.php', {'email': email});
  }

  /// Devuelve el usuario admin si hay sesión activa, o null si no.
  Future<Map<String, dynamic>?> verificarSesion() async {
    try {
      final r = await _llamar(() => http.get(_u('verificar_sesion.php'), headers: _headers()));
      return r['usuario'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.status == 401) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await _postJson('login_admin.php', {'email': email, 'password': password});
    return r['usuario'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try {
      await _llamar(() => http.post(_u('logout_admin.php'), headers: _headers()));
    } finally {
      _cookie = null;
      await _prefs?.remove(_kCookie);
    }
  }

  // ---------------- Plan ----------------

  Future<Plan> obtenerPlan() async {
    final r = await _llamar(() => http.get(_u('obtener_plan.php'), headers: _headers()));
    if (!r.containsKey('configuracion')) {
      throw ApiException('Respuesta inválida del servidor (¿URL de la API correcta?).');
    }
    return Plan.fromJson(r);
  }

  Future<void> guardarPlan(double deudaTotal, int numCuotas) async {
    await _postJson('guardar_plan.php', {'deudaTotal': deudaTotal, 'numCuotas': numCuotas});
  }

  // ---------------- Pagos ----------------

  /// [accion]: 'mantener' | 'nuevo' | 'eliminar' (igual que la versión web).
  Future<void> guardarPago({
    required int cuotaId,
    int? pagoId,
    required String fecha,
    required double monto,
    required String accion,
    PlatformFile? archivo,
  }) async {
    await _llamar(() async {
      final req = http.MultipartRequest('POST', _u('guardar_pago.php'))
        ..headers.addAll(_headers())
        ..fields['cuota_id'] = '$cuotaId'
        ..fields['fecha'] = fecha
        ..fields['monto'] = monto.toStringAsFixed(2)
        ..fields['accion_comprobante'] = accion;
      if (pagoId != null) req.fields['pago_id'] = '$pagoId';
      if (accion == 'nuevo' && archivo != null && archivo.path != null) {
        req.files.add(await http.MultipartFile.fromPath(
          'archivo',
          archivo.path!,
          filename: archivo.name,
          contentType: MediaType.parse(_mime(archivo.extension)),
        ));
      }
      return http.Response.fromStream(await req.send());
    });
  }

  Future<void> eliminarPago(int pagoId) async {
    await _postJson('eliminar_pago.php', {'pago_id': pagoId});
  }

  // PHP valida el tipo MIME que manda el cliente, así que lo fijamos por extensión.
  String _mime(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }
}
