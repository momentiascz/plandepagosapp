import 'dart:math' as math;
import '../utils.dart';

enum EstadoCuota { pendiente, parcial, pagado }

extension EstadoCuotaX on EstadoCuota {
  String get etiqueta => switch (this) {
        EstadoCuota.pendiente => 'Pendiente',
        EstadoCuota.parcial => 'Parcial',
        EstadoCuota.pagado => 'Pagado',
      };
}

class Comprobante {
  final int id;
  final String nombre;
  final String tipo;
  const Comprobante({required this.id, required this.nombre, required this.tipo});

  factory Comprobante.fromJson(Map<String, dynamic> j) => Comprobante(
        id: (j['id'] as num).toInt(),
        nombre: (j['nombre'] as String?) ?? 'comprobante',
        tipo: (j['tipo'] as String?) ?? '',
      );

  bool get esImagen => tipo.startsWith('image/');
}

class Pago {
  final int id;
  final String fecha; // yyyy-mm-dd
  final double monto;
  final Comprobante? comprobante;
  const Pago({required this.id, required this.fecha, required this.monto, this.comprobante});

  factory Pago.fromJson(Map<String, dynamic> j) => Pago(
        id: (j['id'] as num).toInt(),
        fecha: j['fecha'] as String,
        monto: (j['monto'] as num).toDouble(),
        comprobante: j['comprobante'] == null
            ? null
            : Comprobante.fromJson(j['comprobante'] as Map<String, dynamic>),
      );
}

class Cuota {
  final int id;
  final int numero;
  final List<Pago> pagos;
  const Cuota({required this.id, required this.numero, required this.pagos});

  factory Cuota.fromJson(Map<String, dynamic> j) => Cuota(
        id: (j['id'] as num).toInt(),
        numero: (j['numero'] as num).toInt(),
        pagos: (j['pagos'] as List)
            .map((e) => Pago.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Configuracion {
  final double deudaTotal;
  final int numCuotas;
  final String moneda;
  const Configuracion({required this.deudaTotal, required this.numCuotas, required this.moneda});

  factory Configuracion.fromJson(Map<String, dynamic> j) => Configuracion(
        deudaTotal: (j['deudaTotal'] as num).toDouble(),
        numCuotas: (j['numCuotas'] as num).toInt(),
        moneda: (j['moneda'] as String?) ?? 'Bs.',
      );
}

class DetalleCuota {
  final double esperado, pagado, pendiente;
  final EstadoCuota estado;
  final String? ultimaFecha;
  const DetalleCuota(this.esperado, this.pagado, this.pendiente, this.estado, this.ultimaFecha);
}

class Totales {
  final double deudaTotal, totalPagado, totalPendiente, porcentaje;
  final int pagadas, parciales, pendientes, totalCuotas;
  const Totales(this.deudaTotal, this.totalPagado, this.totalPendiente, this.porcentaje,
      this.pagadas, this.parciales, this.pendientes, this.totalCuotas);
}

class Plan {
  final Configuracion config;
  final List<Cuota> cuotas;
  const Plan(this.config, this.cuotas);

  factory Plan.fromJson(Map<String, dynamic> j) {
    final cuotas = (j['cuotas'] as List)
        .map((e) => Cuota.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));
    return Plan(Configuracion.fromJson(j['configuracion'] as Map<String, dynamic>), cuotas);
  }

  double get cuotaEsperada =>
      config.numCuotas == 0 ? 0 : redondear(config.deudaTotal / config.numCuotas);

  Cuota? cuotaPorId(int id) {
    for (final c in cuotas) {
      if (c.id == id) return c;
    }
    return null;
  }

  DetalleCuota detalle(Cuota c) {
    final esperado = cuotaEsperada;
    final pagado = redondear(c.pagos.fold<double>(0, (s, p) => s + p.monto));
    final pendiente = redondear(math.max(esperado - pagado, 0.0));
    var estado = EstadoCuota.pendiente;
    if (pagado > 0 && pagado < esperado) {
      estado = EstadoCuota.parcial;
    } else if (pagado >= esperado && esperado > 0) {
      estado = EstadoCuota.pagado;
    }
    String? ultima;
    for (final p in c.pagos) {
      if (ultima == null || p.fecha.compareTo(ultima) > 0) ultima = p.fecha;
    }
    return DetalleCuota(esperado, pagado, pendiente, estado, ultima);
  }

  Totales get totales {
    final deuda = config.deudaTotal;
    double pagado = 0;
    int ok = 0, parcial = 0, pend = 0;
    for (final c in cuotas) {
      final d = detalle(c);
      pagado += d.pagado;
      switch (d.estado) {
        case EstadoCuota.pagado:
          ok++;
        case EstadoCuota.parcial:
          parcial++;
        case EstadoCuota.pendiente:
          pend++;
      }
    }
    pagado = redondear(pagado);
    final pct = deuda > 0 ? math.min(pagado / deuda * 100, 100.0) : 0.0;
    return Totales(deuda, pagado, redondear(math.max(deuda - pagado, 0.0)), pct, ok, parcial, pend, cuotas.length);
  }
}
