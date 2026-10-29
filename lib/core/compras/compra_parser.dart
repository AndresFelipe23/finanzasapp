/// Lee una notificación de pago (Google Wallet, app del banco) y saca el
/// monto, el comercio y la tarjeta. Es genérico: no depende del formato de un
/// banco en particular, así que puede no entender algún mensaje; en ese caso
/// devuelve null y no se registra nada.
class CompraDetectada {
  const CompraDetectada({
    required this.monto,
    this.ingreso = false,
    this.moneda,
    this.comercio,
    this.ultimos4,
    this.fuente,
  });

  final double monto;

  /// true: dinero que entra ("Recibiste $50.000 de…"), no una compra.
  final bool ingreso;

  /// Solo si el mensaje la dice (USD, MXN…); si no, la de la cuenta.
  final String? moneda;
  /// Comercio de la compra, o quién envió el dinero en un ingreso.
  final String? comercio;
  final String? ultimos4;

  /// "Google Wallet", "Bancolombia"… (null si la app no se conoce).
  final String? fuente;

  @override
  String toString() =>
      '${ingreso ? 'Ingreso' : 'Compra'}($monto ${moneda ?? ''} '
      '${ingreso ? 'de' : 'en'} ${comercio ?? '?'} *${ultimos4 ?? '?'} · ${fuente ?? '?'})';
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
// Ni compra ni ingreso: retiros en cajero y pagos a tu propia tarjeta
final _ignorar = RegExp(
  r'retiro|recibimos (tu|el) pago|pago (a|de) tu tarjeta|abono a (tu )?tarjeta|pago recibido',
  caseSensitive: false,
);
// Dinero que entra
final _entrada = RegExp(
  r'recib|te (envi|transfir|consign)|abono|consign|dep[oó]sit|reembols|devoluci|te lleg',
  caseSensitive: false,
);
// Quién lo envió: "de Juan Perez", "desde BANCOLOMBIA"
final _origen = RegExp(r'\b(?:de|desde)\s+([A-ZÁÉÍÓÚÑ][^\n]*)');
final _tarjeta = RegExp(
  r'(?:\*+|•+|x{2,}|terminada en|termina en|final(?:izada)? en)\s*(\d{4})',
  caseSensitive: false,
);
// Comercio después de "en" ("en EXITO CALLE 80") o "a" seguido de mayúscula
// ("a NETFLIX"); se corta antes de la fecha, la hora o la tarjeta
final _comercio = RegExp(r'\b(?:en|a)\s+([A-Z0-9][^\n]*)');
final _corte = RegExp(
  r'\s+(con|el|desde|por|hoy|de tu|fecha|a las|a tu|a su|en tu|en su|para|tarjeta|t\.?\s?cred|t\.?\s?deb)\b|\s+\d{1,2}[/-]\d{1,2}|\s+\d{1,2}:\d{2}|[*•.,;\n]',
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
  if (_ignorar.hasMatch(todo)) return null;
  final ingreso = _entrada.hasMatch(todo);

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
  if (ingreso) {
    // Quién envió el dinero
    final o = _origen.firstMatch(todo.substring(m.end)) ?? _origen.firstMatch(todo);
    if (o != null) {
      var nombre = o.group(1)!;
      final corte = _corte.firstMatch(nombre);
      if (corte != null) nombre = nombre.substring(0, corte.start);
      nombre = nombre.trim();
      if (nombre.length >= 2) comercio = nombre;
    }
  } else if (_billeteras.containsKey(paquete) &&
      !_monto.hasMatch(titulo) &&
      titulo.trim().isNotEmpty) {
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
    ingreso: ingreso,
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
