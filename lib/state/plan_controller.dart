import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan.dart';
import '../services/api_client.dart';

enum Fase { cargando, acceso, app }

class PlanController extends ChangeNotifier {
  PlanController(this.api);

  final ApiClient api;
  late final SharedPreferences _prefs;

  Fase fase = Fase.cargando;
  Plan? plan;
  bool cargandoPlan = false;
  String? errorCarga;
  Map<String, dynamic>? usuario;
  ThemeMode themeMode = ThemeMode.system;

  bool get esAdmin => usuario != null;

  static const _kEmail = 'emailAutorizado';
  static const _kTema = 'tema';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    api.init(_prefs);

    final tema = _prefs.getString(_kTema);
    themeMode = tema == 'oscuro'
        ? ThemeMode.dark
        : tema == 'claro'
            ? ThemeMode.light
            : ThemeMode.system;

    final email = _prefs.getString(_kEmail);
    if (email == null) {
      fase = Fase.acceso;
      notifyListeners();
      return;
    }
    try {
      await api.verificarAcceso(email);
      fase = Fase.app;
    } on ApiException catch (e) {
      if (e.status == 400 || e.status == 403) {
        await _prefs.remove(_kEmail);
        fase = Fase.acceso;
      } else {
        fase = Fase.app; // sin conexión o error de servidor: entra y permite reintentar
      }
    }
    notifyListeners();
    if (fase == Fase.app) await refrescar();
  }

  Future<void> ingresarConEmail(String email) async {
    await api.verificarAcceso(email);
    await _prefs.setString(_kEmail, email);
    fase = Fase.app;
    notifyListeners();
    await refrescar();
  }

  Future<void> refrescar() async {
    cargandoPlan = true;
    errorCarga = null;
    notifyListeners();
    try {
      plan = await api.obtenerPlan();
      usuario = await api.verificarSesion();
    } on ApiException catch (e) {
      errorCarga = e.message;
    } catch (_) {
      errorCarga = 'No se pudo cargar el plan de pagos.';
    }
    cargandoPlan = false;
    notifyListeners();
  }

  Future<void> iniciarSesion(String email, String password) async {
    usuario = await api.login(email, password);
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    try {
      await api.logout();
    } finally {
      usuario = null;
      notifyListeners();
    }
  }

  Future<void> guardarPago({
    required int cuotaId,
    int? pagoId,
    required String fecha,
    required double monto,
    required String accion,
    PlatformFile? archivo,
  }) async {
    await api.guardarPago(
        cuotaId: cuotaId, pagoId: pagoId, fecha: fecha, monto: monto, accion: accion, archivo: archivo);
    await refrescar();
  }

  Future<void> eliminarPago(int pagoId) async {
    await api.eliminarPago(pagoId);
    await refrescar();
  }

  Future<void> guardarPlan(double deuda, int numCuotas) async {
    await api.guardarPlan(deuda, numCuotas);
    await refrescar();
  }

  Future<void> alternarTema(Brightness actual) async {
    themeMode = actual == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    await _prefs.setString(_kTema, themeMode == ThemeMode.dark ? 'oscuro' : 'claro');
    notifyListeners();
  }
}
