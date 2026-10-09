import 'package:flutter/material.dart';

import '../models/plan.dart';
import '../state/plan_controller.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'detalle_cuota.dart';
import 'dialogs.dart';
import 'pago_form.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen(this.c, {super.key});
  final PlanController c;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final p = Paleta.of(context);
        final oscuro = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          appBar: AppBar(
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mi Plan de Pagos', style: estiloTitulo(size: 20)),
              Text('Control personal de deuda y cuotas',
                  style: TextStyle(fontSize: 12, color: p.tintaSuave)),
            ]),
            actions: [
              IconButton(
                tooltip: 'Cambiar tema',
                icon: Icon(oscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: () => c.alternarTema(Theme.of(context).brightness),
              ),
              PopupMenuButton<String>(
                tooltip: 'Administrador',
                icon: Icon(c.esAdmin ? Icons.verified_user_outlined : Icons.lock_outline),
                onSelected: (v) async {
                  if (v == 'login') {
                    mostrarLogin(context, c);
                  } else if (v == 'plan') {
                    mostrarEditarPlan(context, c);
                  } else if (v == 'logout') {
                    final m = ScaffoldMessenger.of(context);
                    try {
                      await c.cerrarSesion();
                      toastM(m, 'Sesión cerrada.');
                    } catch (_) {
                      toastM(m, 'No se pudo cerrar la sesión.', error: true);
                    }
                  }
                },
                itemBuilder: (_) => c.esAdmin
                    ? [
                        const PopupMenuItem(value: 'plan', child: Text('Editar plan')),
                        PopupMenuItem(
                            value: 'logout',
                            child: Text('Cerrar sesión (${c.usuario?['nombre'] ?? 'admin'})')),
                      ]
                    : const [PopupMenuItem(value: 'login', child: Text('Iniciar sesión'))],
              ),
            ],
          ),
          body: SafeArea(child: _cuerpo(context, p)),
        );
      },
    );
  }

  Widget _cuerpo(BuildContext context, Paleta p) {
    final plan = c.plan;
    if (plan == null) {
      if (c.cargandoPlan) return const Center(child: CircularProgressIndicator());
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: p.tintaSuave),
            const SizedBox(height: 12),
            Text(c.errorCarga ?? 'No se pudo cargar el plan.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: c.refrescar, child: const Text('Reintentar')),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: c.refrescar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (c.errorCarga != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(c.errorCarga!, style: TextStyle(color: p.pendiente)),
            ),
          _resumen(p, plan),
          const SizedBox(height: 12),
          _estadisticas(p, plan),
          const SizedBox(height: 20),
          Text('Cuotas', style: estiloTitulo(size: 20)),
          const SizedBox(height: 2),
          Text('Toca una cuota para ver o gestionar sus pagos',
              style: TextStyle(fontSize: 12, color: p.tintaSuave)),
          const SizedBox(height: 10),
          for (final q in plan.cuotas) _cuotaCard(context, p, plan, q),
        ],
      ),
    );
  }

  Widget _dato(Paleta p, String label, String valor, {Color? color}) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Etiqueta(label),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: estiloNumero(size: 15, weight: FontWeight.w600, color: color ?? p.tinta)),
          ),
        ]),
      );

  Widget _resumen(Paleta p, Plan plan) {
    final t = plan.totales;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Etiqueta('Avance del plan'),
        Text('${t.porcentaje.round()}%', style: estiloTitulo(size: 56).copyWith(height: 1.1)),
        Text('${t.pagadas} de ${t.totalCuotas} cuotas completadas',
            style: TextStyle(color: p.tintaSuave)),
        const SizedBox(height: 14),
        BarraProgreso(porcentaje: t.porcentaje, marcas: t.totalCuotas),
        const SizedBox(height: 18),
        Row(children: [
          _dato(p, 'Deuda total', fmtMoneda(t.deudaTotal)),
          _dato(p, 'Total pagado', fmtMoneda(t.totalPagado), color: p.pagado),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _dato(p, 'Total pendiente', fmtMoneda(t.totalPendiente), color: p.pendiente),
          _dato(p, 'Cuota mensual', fmtMoneda(plan.cuotaEsperada)),
        ]),
      ]),
    );
  }

  Widget _pill(Paleta p, int n, String label, Color fg, Color bg) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('$n', style: estiloNumero(size: 20, weight: FontWeight.w600, color: fg)),
            Text(label, style: TextStyle(fontSize: 12, color: fg)),
          ]),
        ),
      );

  Widget _estadisticas(Paleta p, Plan plan) {
    final t = plan.totales;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Estadísticas', style: estiloTitulo(size: 18)),
        const SizedBox(height: 12),
        Row(children: [
          _pill(p, t.pagadas, 'Pagadas', p.pagado, p.pagadoBg),
          _pill(p, t.parciales, 'Parciales', p.parcial, p.parcialBg),
          _pill(p, t.pendientes, 'Pendientes', p.pendiente, p.pendienteBg),
        ]),
        const SizedBox(height: 16),
        Center(child: DonaEstados(t)),
        const SizedBox(height: 16),
        const Etiqueta('Esperado vs. pagado por cuota'),
        const SizedBox(height: 8),
        BarrasCuotas(plan),
      ]),
    );
  }

  Widget _cuotaCard(BuildContext context, Paleta p, Plan plan, Cuota q) {
    final d = plan.detalle(q);
    final adjuntos = q.pagos.where((x) => x.comprobante != null).length;

    Widget col(String l, String v, {Color? color}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: TextStyle(fontSize: 11, color: p.tintaSuave)),
            const SizedBox(height: 2),
            FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(v, style: estiloNumero(size: 13, color: color))),
          ]),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        onTap: () => mostrarDetalleCuota(context, c, q.id),
        child: Column(children: [
          Row(children: [
            Text('#${q.numero}', style: estiloTitulo(size: 20)),
            const SizedBox(width: 10),
            EstadoChip(d.estado),
            const Spacer(),
            if (adjuntos > 0) ...[
              Icon(Icons.attach_file, size: 16, color: p.tintaSuave),
              Text('$adjuntos', style: TextStyle(fontSize: 12, color: p.tintaSuave)),
              const SizedBox(width: 10),
            ],
            Text(fmtFecha(d.ultimaFecha), style: TextStyle(fontSize: 12, color: p.tintaSuave)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            col('Esperado', fmtMoneda(d.esperado)),
            col('Pagado', fmtMoneda(d.pagado), color: d.pagado > 0 ? p.pagado : null),
            col('Pendiente', fmtMoneda(d.pendiente), color: d.pendiente > 0 ? p.pendiente : null),
          ]),
          if (c.esAdmin)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonal(
                  onPressed: () => mostrarFormPago(context, c, q),
                  child: const Text('Registrar pago'),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
