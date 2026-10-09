import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/plan.dart';
import '../state/plan_controller.dart';

void verComprobante(BuildContext context, PlanController c, Comprobante comp) {
  final url = c.api.urlComprobante(comp.id);
  void abrirExterno() => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => Scaffold(
      appBar: AppBar(
        title: Text(comp.nombre, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
              tooltip: 'Abrir en el navegador', icon: const Icon(Icons.open_in_new), onPressed: abrirExterno),
        ],
      ),
      body: comp.esImagen
          ? InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, prog) =>
                      prog == null ? child : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Text('No se pudo cargar el comprobante.')),
                ),
              ),
            )
          : Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.picture_as_pdf_outlined, size: 72),
                const SizedBox(height: 12),
                Text(comp.nombre),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed: abrirExterno, icon: const Icon(Icons.open_in_new), label: const Text('Abrir PDF')),
              ]),
            ),
    ),
  ));
}
