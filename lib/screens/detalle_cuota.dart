import 'package:flutter/material.dart';

import '../state/plan_controller.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'comprobante_viewer.dart';
import 'dialogs.dart';
import 'pago_form.dart';

void mostrarDetalleCuota(BuildContext context, PlanController c, int cuotaId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _Detalle(c, cuotaId),
    );

class _Detalle extends StatelessWidget {
  const _Detalle(this.c, this.cuotaId);
  final PlanController c;
  final int cuotaId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final plan = c.plan;
        final q = plan?.cuotaPorId(cuotaId);
        if (plan == null || q == null) {
          return const Padding(padding: EdgeInsets.all(32), child: Text('La cuota ya no existe.'));
        }
        final p = Paleta.of(context);
        final d = plan.detalle(q);
        final pagos = [...q.pagos]..sort((a, b) => b.fecha.compareTo(a.fecha));

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text('Cuota #${q.numero}', style: estiloTitulo(size: 22)),
              const SizedBox(width: 12),
              EstadoChip(d.estado),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 6, children: [
              Text('Esperado: ${fmtMoneda(d.esperado)}', style: estiloNumero(size: 13)),
              Text('Pagado: ${fmtMoneda(d.pagado)}', style: estiloNumero(size: 13, color: p.pagado)),
              Text('Pendiente: ${fmtMoneda(d.pendiente)}', style: estiloNumero(size: 13, color: p.pendiente)),
            ]),
            const SizedBox(height: 20),
            const Etiqueta('Pagos registrados'),
            const SizedBox(height: 8),
            if (pagos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Todavía no se registraron pagos para esta cuota.',
                    style: TextStyle(color: p.tintaSuave)),
              ),
            for (final pago in pagos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(fmtMoneda(pago.monto), style: estiloNumero(size: 15, weight: FontWeight.w600)),
                        Text(fmtFecha(pago.fecha), style: TextStyle(fontSize: 12, color: p.tintaSuave)),
                      ]),
                    ),
                    if (pago.comprobante != null)
                      IconButton(
                        tooltip: 'Ver comprobante',
                        icon: const Icon(Icons.receipt_long_outlined),
                        onPressed: () => verComprobante(context, c, pago.comprobante!),
                      ),
                    if (c.esAdmin) ...[
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => mostrarFormPago(context, c, q, pago: pago),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: Icon(Icons.delete_outline, color: p.pendiente),
                        onPressed: () => _eliminar(context, pago.id, pago.monto, pago.fecha),
                      ),
                    ],
                  ]),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: c.esAdmin ? () => mostrarFormPago(context, c, q) : null,
              child: Text(c.esAdmin ? 'Registrar nuevo pago' : 'Solo lectura'),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _eliminar(BuildContext context, int pagoId, double monto, String fecha) async {
    final ok = await confirmar(
      context,
      '¿Eliminar el pago de ${fmtMoneda(monto)} del ${fmtFecha(fecha)}? Esta acción no se puede deshacer.',
    );
    if (!ok || !context.mounted) return;
    final m = ScaffoldMessenger.of(context);
    try {
      await c.eliminarPago(pagoId);
      toastM(m, 'Pago eliminado.');
    } catch (e) {
      toastM(m, e.toString(), error: true);
    }
  }
}
