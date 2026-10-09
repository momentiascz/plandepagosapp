import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../state/plan_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen(this.c, {super.key});
  final PlanController c;
  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final email = TextEditingController();
  String? error;
  bool cargando = false;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final valor = email.text.trim();
    if (valor.isEmpty) {
      setState(() => error = 'Debes ingresar un email autorizado.');
      return;
    }
    setState(() {
      error = null;
      cargando = true;
    });
    try {
      await widget.c.ingresarConEmail(valor);
    } on ApiException catch (e) {
      if (mounted) setState(() { error = e.message; cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Paleta.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Panel(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Acceso restringido', style: estiloTitulo(size: 24)),
                  const SizedBox(height: 8),
                  Text('Para acceder debes ingresar con un email autorizado.',
                      style: TextStyle(color: p.tintaSuave)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _entrar(),
                    decoration: decoracion(context, 'Email autorizado'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: cargando ? null : _entrar,
                    child: cargando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Ingresar'),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error!, style: TextStyle(color: p.pendiente)),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
