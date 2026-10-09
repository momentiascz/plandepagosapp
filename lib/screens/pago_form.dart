import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/plan.dart';
import '../services/api_client.dart';
import '../state/plan_controller.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'dialogs.dart';

const _maxBytes = 4 * 1024 * 1024; // 4 MB, igual que el servidor

Future<void> mostrarFormPago(BuildContext context, PlanController c, Cuota cuota, {Pago? pago}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FormPago(c, cuota, pago),
    );

class _FormPago extends StatefulWidget {
  const _FormPago(this.c, this.cuota, this.pago);
  final PlanController c;
  final Cuota cuota;
  final Pago? pago;
  @override
  State<_FormPago> createState() => _FormPagoState();
}

class _FormPagoState extends State<_FormPago> {
  late String fecha;
  final monto = TextEditingController();
  PlatformFile? archivo;
  String accion = 'mantener'; // 'mantener' | 'nuevo' | 'eliminar'
  String? error;
  bool guardando = false;

  Comprobante? get existente => widget.pago?.comprobante;

  @override
  void initState() {
    super.initState();
    fecha = widget.pago?.fecha ?? isoDe(DateTime.now());
    if (widget.pago != null) monto.text = widget.pago!.monto.toStringAsFixed(2);
  }

  @override
  void dispose() {
    monto.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(fecha) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => fecha = isoDe(d));
  }

  Future<void> _elegirArchivo() async {
    final elegidos = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (elegidos.isEmpty) return;
    final f = elegidos.single;
    final tam = f.lengthSync() ?? (await f.length()) ?? 0;
    if (tam > _maxBytes) {
      setState(() => error = 'El archivo supera el tamaño máximo de 4 MB.');
      return;
    }
    setState(() {
      archivo = f;
      accion = 'nuevo';
      error = null;
    });
  }

  void _quitar() => setState(() {
        archivo = null;
        accion = existente != null ? 'eliminar' : 'mantener';
      });

  Future<void> _guardar() async {
    final m = double.tryParse(monto.text.trim().replaceAll(',', '.'));
    if (m == null || m <= 0) {
      setState(() => error = 'El monto debe ser un número mayor a cero.');
      return;
    }
    setState(() {
      error = null;
      guardando = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.c.guardarPago(
        cuotaId: widget.cuota.id,
        pagoId: widget.pago?.id,
        fecha: fecha,
        monto: redondear(m),
        accion: accion,
        archivo: archivo,
      );
      if (!mounted) return;
      Navigator.pop(context);
      toastM(messenger,
          widget.pago != null ? 'Pago actualizado correctamente.' : 'Pago registrado correctamente.');
    } on ApiException catch (e) {
      if (mounted) setState(() { error = e.message; guardando = false; });
    } catch (_) {
      if (mounted) setState(() { error = 'Ocurrió un error inesperado.'; guardando = false; });
    }
  }

  Widget _seccionComprobante(Paleta p) {
    String? nombre;
    if (archivo != null) {
      nombre = archivo!.name;
    } else if (existente != null && accion != 'eliminar') {
      nombre = existente!.nombre;
    }
    if (nombre == null) {
      return OutlinedButton.icon(
        onPressed: _elegirArchivo,
        icon: const Icon(Icons.attach_file),
        label: const Text('Adjuntar comprobante (JPG, PNG o PDF)'),
      );
    }
    final esImagenNueva = archivo != null && archivo!.path != null &&
        const ['jpg', 'jpeg', 'png'].contains((archivo!.extension ?? '').toLowerCase());
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        if (esImagenNueva)
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(File(archivo!.path!), width: 40, height: 40, fit: BoxFit.cover))
        else
          const Icon(Icons.description_outlined),
        const SizedBox(width: 10),
        Expanded(child: Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis)),
        TextButton(onPressed: _elegirArchivo, child: const Text('Cambiar')),
        TextButton(onPressed: _quitar, child: const Text('Quitar')),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    final plan = widget.c.plan!;
    final d = plan.detalle(widget.cuota);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            '${widget.pago == null ? 'Registrar' : 'Editar'} pago — cuota #${widget.cuota.numero}',
            style: estiloTitulo(size: 20),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _elegirFecha,
            child: InputDecorator(
              decoration: decoracion(context, 'Fecha de pago'),
              child: Row(children: [
                Expanded(child: Text(fmtFecha(fecha))),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: monto,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: decoracion(
              context,
              'Monto pagado (Bs.)',
              ayuda:
                  'Esperado: ${fmtMoneda(d.esperado)} · Ya pagado: ${fmtMoneda(d.pagado)} · Pendiente: ${fmtMoneda(d.pendiente)}',
            ),
          ),
          const SizedBox(height: 12),
          _seccionComprobante(p),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!, style: TextStyle(color: p.pendiente)),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: guardando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'))),
            const SizedBox(width: 12),
            Expanded(
                child: FilledButton(
                    onPressed: guardando ? null : _guardar,
                    child: guardando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar pago'))),
          ]),
        ]),
      ),
    );
  }
}
