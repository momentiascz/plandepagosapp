double redondear(num v) => (v * 100).round() / 100;

/// Formato igual al de la versión web: Bs. 1,234.50
String fmtMoneda(num v) {
  final partes = v.abs().toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return 'Bs. ${v < 0 ? '-' : ''}$entero.${partes[1]}';
}

/// yyyy-mm-dd -> dd/mm/aaaa
String fmtFecha(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
}

String isoDe(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
