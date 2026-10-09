import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/plan.dart';

/// Paleta tomada de css/styles.css (modo claro "papel contable" y modo oscuro).
class Paleta {
  final Color bg, superficie, tinta, tintaSuave, linea;
  final Color pagado, pagadoBg, parcial, parcialBg, pendiente, pendienteBg;
  const Paleta({
    required this.bg,
    required this.superficie,
    required this.tinta,
    required this.tintaSuave,
    required this.linea,
    required this.pagado,
    required this.pagadoBg,
    required this.parcial,
    required this.parcialBg,
    required this.pendiente,
    required this.pendienteBg,
  });

  static const claro = Paleta(
    bg: Color(0xFFEEF1EF),
    superficie: Color(0xFFFFFFFF),
    tinta: Color(0xFF1B2420),
    tintaSuave: Color(0xFF56645D),
    linea: Color(0xFFD7DED9),
    pagado: Color(0xFF2E6B4C),
    pagadoBg: Color(0xFFE4F0E7),
    parcial: Color(0xFFA8791E),
    parcialBg: Color(0xFFF6ECD8),
    pendiente: Color(0xFF9C3A3A),
    pendienteBg: Color(0xFFF5E4E1),
  );

  static const oscuro = Paleta(
    bg: Color(0xFF10161A),
    superficie: Color(0xFF182027),
    tinta: Color(0xFFE9EEEA),
    tintaSuave: Color(0xFF99A7A0),
    linea: Color(0xFF2B363D),
    pagado: Color(0xFF6FBF8F),
    pagadoBg: Color(0xFF1B3327),
    parcial: Color(0xFFE0B04E),
    parcialBg: Color(0xFF3A2E17),
    pendiente: Color(0xFFE08787),
    pendienteBg: Color(0xFF3A2020),
  );

  static Paleta of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? oscuro : claro;

  Color fg(EstadoCuota e) => switch (e) {
        EstadoCuota.pagado => pagado,
        EstadoCuota.parcial => parcial,
        EstadoCuota.pendiente => pendiente,
      };

  Color bgDe(EstadoCuota e) => switch (e) {
        EstadoCuota.pagado => pagadoBg,
        EstadoCuota.parcial => parcialBg,
        EstadoCuota.pendiente => pendienteBg,
      };
}

TextStyle estiloNumero({double size = 14, FontWeight weight = FontWeight.w500, Color? color}) =>
    GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color);

TextStyle estiloTitulo({double size = 20, FontWeight weight = FontWeight.w600, Color? color}) =>
    GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color);

ThemeData construirTema(Brightness b) {
  final p = b == Brightness.dark ? Paleta.oscuro : Paleta.claro;
  final base = ThemeData(brightness: b, useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: Paleta.claro.pagado, brightness: b).copyWith(
      primary: p.pagado,
      onPrimary: b == Brightness.dark ? Paleta.oscuro.bg : Colors.white,
      surface: p.superficie,
      onSurface: p.tinta,
      outline: p.linea,
    ),
    scaffoldBackgroundColor: p.bg,
    textTheme: GoogleFonts.ibmPlexSansTextTheme(base.textTheme)
        .apply(bodyColor: p.tinta, displayColor: p.tinta),
    appBarTheme: AppBarTheme(
      backgroundColor: p.superficie,
      foregroundColor: p.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

InputDecoration decoracion(BuildContext context, String label, {String? ayuda}) {
  final p = Paleta.of(context);
  return InputDecoration(
    labelText: label,
    helperText: ayuda,
    helperMaxLines: 3,
    filled: true,
    fillColor: p.superficie,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: p.linea)),
  );
}
