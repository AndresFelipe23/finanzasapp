/// Lee una notificación de pago (Google Wallet, app del banco) y saca el
/// monto, el comercio y la tarjeta. Es genérico: no depende del formato de un
/// banco en particular, así que puede no entender algún mensaje; en ese caso
/// devuelve null y no se registra nada.
class CompraDetectada {
  const CompraDetectada({
    required this.monto,
    this.moneda,
    this.comercio,
    this.ultimos4,
    this.fuente,
  });

  final double monto;

  /// Solo si el mensaje la dice (USD, MXN…); si no, la de la cuenta.
  final String? moneda;
  final String? comercio;
  final String? ultimos4;

  /// "Google Wallet", "Bancolombia"… (null si la app no se conoce).
  final String? fuente;

  @override
  String toString() =>
      'Compra($monto ${moneda ?? ''} en ${comercio ?? '?'} *${ultimos4 ?? '?'} · ${fuente ?? '?'})';
}

const _billeteras = {
  'com.google.android.apps.walletnfcrel': 'Google Wallet',
  'com.samsung.android.spay': 'Samsung Wallet',
};

const _fuentes = {
  ..._billeteras,
  'com.todo1.mobile': 'Bancolombia',
  'com.bancolombia.mibancolombia': 'Bancolombia',
  'com.nequi.MobileApp': 'Nequi',
  'com.davivienda.daviviendaapp': 'Davivienda',
  'com.davivienda.daviplataapp': 'Daviplata',
  'co.com.bbva.mb': 'BBVA',
  'com.bancodebogota.bancamovil': 'Banco de Bogotá',
  'com.nu.production': 'Nu',
};

final _monto = RegExp(r'(US\$|\$|COP|USD|MXN)\s?(\d[\d.,]*)', caseSensitive: false);
final _entrada = RegExp(
  r'recib|abono|consign|te (envi|transfir)|ingres|reembols|devoluci|retiro',
  caseSensitive: false,
);
final _tarjeta = RegExp(
  r'(?:\*+|•+|x{2,}|terminada en|termina en|final(?:izada)? en)\s*(\d{4})',
  caseSensitive: false,
);
// Comercio después de "en" ("en EXITO CALLE 80") o "a" seguido de mayúscula
// ("a NETFLIX"); se corta antes de la fecha, la hora o la tarjeta
final _comercio = RegExp(r'\b(?:en|a)\s+([A-Z0-9][^\n]*)');
final _corte = RegExp(
  r'\s+(con|el|desde|por|hoy|de tu|fecha|a las|tarjeta|t\.?\s?cred|t\.?\s?deb)\b|\s+\d{1,2}[/-]\d{1,2}|\s+\d{1,2}:\d{2}|[*•.,;\n]',
  caseSensitive: false,
);

/// "85.000", "85,000.00", "85.000,00", "1.234.567" → número.
double? normalizarMonto(String s) {
  s = s.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(RegExp(r'[.,]+$'), '');
  final punto = s.lastIndexOf('.');
  final coma = s.lastIndexOf(',');
  if (punto >= 0 && coma >= 0) {
    // Los dos: el último separa los decimales
    final dec = punto > coma ? '.' : ',';
    final miles = dec == '.' ? ',' : '.';
    s = s.replaceAll(miles, '').replaceAll(dec, '.');
  } else if (punto >= 0 || coma >= 0) {
    // Uno solo: es de miles si cada grupo después del primero tiene 3 cifras
    final sep = punto >= 0 ? '.' : ',';
    final partes = s.split(sep);
    final miles = partes.skip(1).every((p) => p.length == 3);
    s = miles ? partes.join() : s.replaceAll(sep, '.');
  }
  final v = double.tryParse(s);
  return v == null || v <= 0 ? null : v;
}

CompraDetectada? leerCompra(String paquete, String titulo, String texto) {
  final todo = '$titulo\n$texto';
  // Dinero que entra (o un retiro) no es una compra
  if (_entrada.hasMatch(todo)) return null;

  final m = _monto.firstMatch(todo);
  if (m == null) return null;
  final monto = normalizarMonto(m.group(2)!);
  if (monto == null) return null;
  final simbolo = m.group(1)!.toUpperCase();
  final moneda = switch (simbolo) {
    'USD' || r'US$' => 'USD',
    'MXN' => 'MXN',
    _ => null,
  };

  String? comercio;
  if (_billeteras.containsKey(paquete) && !_monto.hasMatch(titulo) && titulo.trim().isNotEmpty) {
    // Las billeteras ponen el comercio como título
    comercio = titulo.trim();
  } else {
    // Buscar después del monto, que es donde suele estar ("…$85.000 en ÉXITO")
    final despues = todo.substring(m.end);
    final c = _comercio.firstMatch(despues) ?? _comercio.firstMatch(todo);
    if (c != null) {
      var nombre = c.group(1)!;
      final corte = _corte.firstMatch(nombre);
      if (corte != null) nombre = nombre.substring(0, corte.start);
      nombre = nombre.trim();
      if (nombre.length >= 2) comercio = nombre;
    }
  }
  if (comercio != null) comercio = _bonito(comercio);

  return CompraDetectada(
    monto: monto,
    moneda: moneda,
    comercio: comercio,
    ultimos4: _tarjeta.firstMatch(todo)?.group(1),
    fuente: _fuentes[paquete],
  );
}

/// "EXITO CALLE 80" → "Exito Calle 80" (máximo 40 caracteres).
String _bonito(String s) {
  final corto = s.length > 40 ? s.substring(0, 40).trim() : s;
  if (corto != corto.toUpperCase()) return corto;
  return corto
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
      .join(' ');
}
