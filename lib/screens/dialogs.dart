import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../state/plan_controller.dart';
import '../theme.dart';
import '../utils.dart';

void toastM(ScaffoldMessengerState m, String msg, {bool error = false}) {
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg),
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? const Color(0xFF9C3A3A) : null,
  ));
}

void toast(BuildContext context, String msg, {bool error = false}) =>
    toastM(ScaffoldMessenger.of(context), msg, error: error);

Future<bool> confirmar(BuildContext context, String mensaje, {String si = 'Sí, eliminar'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar acción'),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Paleta.of(ctx).pendiente),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(si),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ---------------------------------------------------------------- Login admin

Future<void> mostrarLogin(BuildContext context, PlanController c) =>
    showDialog<void>(context: context, builder: (_) => _LoginDialog(c));

class _LoginDialog extends StatefulWidget {
  const _LoginDialog(this.c);
  final PlanController c;
  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  final email = TextEditingController();
  final pass = TextEditingController();
  String? error;
  bool cargando = false;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (email.text.trim().isEmpty || pass.text.isEmpty) {
      setState(() => error = 'Email y contraseña son obligatorios.');
      return;
    }
    setState(() {
      error = null;
      cargando = true;
    });
    final m = ScaffoldMessenger.of(context);
    try {
      await widget.c.iniciarSesion(email.text.trim(), pass.text);
      if (!mounted) return;
      Navigator.pop(context);
      toastM(m, 'Sesión iniciada correctamente.');
    } on ApiException catch (e) {
      if (mounted) setState(() { error = e.message; cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Acceso administrador'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: decoracion(context, 'Email')),
            const SizedBox(height: 12),
            TextField(
                controller: pass,
                obscureText: true,
                onSubmitted: (_) => _entrar(),
                decoration: decoracion(context, 'Contraseña')),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: TextStyle(color: Paleta.of(context).pendiente)),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: cargando ? null : _entrar, child: const Text('Entrar')),
        ],
      );
}

// ---------------------------------------------------------------- Editar plan

Future<void> mostrarEditarPlan(BuildContext context, PlanController c) =>
    showDialog<void>(context: context, builder: (_) => _PlanDialog(c));

class _PlanDialog extends StatefulWidget {
  const _PlanDialog(this.c);
  final PlanController c;
  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  late final TextEditingController deuda;
  late final TextEditingController cuotas;
  String? error;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    final cfg = widget.c.plan!.config;
    deuda = TextEditingController(text: cfg.deudaTotal.toStringAsFixed(2));
    cuotas = TextEditingController(text: '${cfg.numCuotas}');
  }

  @override
  void dispose() {
    deuda.dispose();
    cuotas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final d = double.tryParse(deuda.text.trim().replaceAll(',', '.'));
    final n = int.tryParse(cuotas.text.trim());
    if (d == null || d <= 0) {
      setState(() => error = 'La deuda total debe ser mayor a cero.');
      return;
    }
    if (n == null || n < 1 || n > 60) {
      setState(() => error = 'El número de cuotas debe estar entre 1 y 60.');
      return;
    }
    final plan = widget.c.plan!;
    if (n < plan.cuotas.length) {
      final conPagos = plan.cuotas.any((q) => q.numero > n && q.pagos.isNotEmpty);
      if (conPagos) {
        final ok = await confirmar(
          context,
          'Algunas de las cuotas que se eliminarán ya tienen pagos registrados. ¿Deseas continuar de todas formas?',
          si: 'Sí, continuar',
        );
        if (!ok || !mounted) return;
      }
    }
    setState(() {
      error = null;
      cargando = true;
    });
    final m = ScaffoldMessenger.of(context);
    try {
      await widget.c.guardarPlan(redondear(d), n);
      if (!mounted) return;
      Navigator.pop(context);
      toastM(m, 'Plan de pagos actualizado.');
    } on ApiException catch (e) {
      if (mounted) setState(() { error = e.message; cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Editar plan de pagos'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: deuda,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: decoracion(context, 'Deuda total (Bs.)')),
            const SizedBox(height: 12),
            TextField(
                controller: cuotas,
                keyboardType: TextInputType.number,
                decoration: decoracion(context, 'Número de cuotas',
                    ayuda:
                        'La cuota mensual se recalcula (deuda ÷ cuotas). Si reduces el número de cuotas, las últimas perderán sus pagos registrados.')),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: TextStyle(color: Paleta.of(context).pendiente)),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: cargando ? null : _guardar, child: const Text('Guardar cambios')),
        ],
      );
}
