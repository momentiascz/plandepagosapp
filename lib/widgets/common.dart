import 'package:flutter/material.dart';

import '../models/plan.dart';
import '../theme.dart';

/// Tarjeta con borde fino (equivale a .panel del CSS). Usa Material para que
/// el efecto de toque (InkWell) se vea por encima del fondo.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    final contenido = Padding(padding: padding, child: child);
    return Material(
      color: p.superficie,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: p.linea),
      ),
      child: onTap == null ? contenido : InkWell(onTap: onTap, child: contenido),
    );
  }
}

class EstadoChip extends StatelessWidget {
  const EstadoChip(this.estado, {super.key});
  final EstadoCuota estado;

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: p.bgDe(estado), borderRadius: BorderRadius.circular(20)),
      child: Text(estado.etiqueta,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.fg(estado))),
    );
  }
}

class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Text(
        texto.toUpperCase(),
        style: TextStyle(
            fontSize: 10.5, letterSpacing: 0.6, color: Paleta.of(context).tintaSuave),
      );
}
