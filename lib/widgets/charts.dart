import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/plan.dart';
import '../theme.dart';

/// Barra de avance con una marca por cuota.
class BarraProgreso extends StatelessWidget {
  const BarraProgreso({super.key, required this.porcentaje, required this.marcas});
  final double porcentaje;
  final int marcas;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Stack(children: [
          Positioned.fill(child: ColoredBox(color: p.linea)),
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (porcentaje / 100).clamp(0.0, 1.0),
              child: ColoredBox(color: p.pagado),
            ),
          ),
          Positioned.fill(
            child: Row(children: [
              for (var i = 0; i < marcas; i++)
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: i < marcas - 1
                          ? Border(right: BorderSide(color: p.superficie, width: 1.5))
                          : null,
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Dona de estados (pagadas / parciales / pendientes).
class DonaEstados extends StatelessWidget {
  const DonaEstados(this.t, {super.key});
  final Totales t;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: const Size(160, 160), painter: _DonaPainter(t, p)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${t.porcentaje.round()}%', style: estiloTitulo(size: 26)),
          Text('completado', style: TextStyle(fontSize: 11, color: p.tintaSuave)),
        ]),
      ]),
    );
  }
}

class _DonaPainter extends CustomPainter {
  _DonaPainter(this.t, this.p);
  final Totales t;
  final Paleta p;

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 20.0;
    final centro = size.center(Offset.zero);
    final radio = size.width / 2 - grosor / 2;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    Paint pincel(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..color = c;

    canvas.drawCircle(centro, radio, pincel(p.linea));
    final total = t.totalCuotas == 0 ? 1 : t.totalCuotas;
    var inicio = -math.pi / 2;
    for (final (valor, color) in [(t.pagadas, p.pagado), (t.parciales, p.parcial), (t.pendientes, p.pendiente)]) {
      if (valor <= 0) continue;
      final barrido = valor / total * 2 * math.pi;
      canvas.drawArc(rect, inicio, barrido, false, pincel(color));
      inicio += barrido;
    }
  }

  @override
  bool shouldRepaint(_DonaPainter old) => old.t != t || old.p != p;
}

/// Barras: esperado (gris) vs. pagado (color del estado) por cuota.
class BarrasCuotas extends StatelessWidget {
  const BarrasCuotas(this.plan, {super.key});
  final Plan plan;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 150,
        width: double.infinity,
        child: CustomPaint(painter: _BarrasPainter(plan, Paleta.of(context))),
      );
}

class _BarrasPainter extends CustomPainter {
  _BarrasPainter(this.plan, this.p);
  final Plan plan;
  final Paleta p;

  @override
  void paint(Canvas canvas, Size size) {
    final n = plan.cuotas.length;
    if (n == 0) return;
    const margenInf = 18.0;
    final alto = size.height - margenInf;
    final paso = size.width / n;
    final anchoBarra = math.max(paso - 6, 4.0);
    final esperado = plan.cuotaEsperada == 0 ? 1 : plan.cuotaEsperada;

    for (var i = 0; i < n; i++) {
      final cuota = plan.cuotas[i];
      final d = plan.detalle(cuota);
      final x = i * paso + 3;
      final hEsperado = alto * 0.9;
      final hPagado = (d.pagado / esperado).clamp(0.0, 1.1) * alto * 0.9;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, alto - hEsperado, anchoBarra, hEsperado), const Radius.circular(2)),
        Paint()..color = p.linea,
      );
      if (d.pagado > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, alto - hPagado, anchoBarra, hPagado), const Radius.circular(2)),
          Paint()..color = p.fg(d.estado),
        );
      }
      if (n <= 24 || (i + 1) % 5 == 0) {
        final tp = TextPainter(
          text: TextSpan(text: '${cuota.numero}', style: TextStyle(fontSize: 9, color: p.tintaSuave)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + anchoBarra / 2 - tp.width / 2, size.height - tp.height - 1));
      }
    }
  }

  @override
  bool shouldRepaint(_BarrasPainter old) => true;
}
