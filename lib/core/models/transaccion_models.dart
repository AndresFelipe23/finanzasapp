class Transaccion {
  final int id;
  final int usuarioId;
  final int? cuentaId;
  final String? cuentaNombre;
  final int tipoTransaccionId;
  final String tipoNombre; // 'INGRESO', 'GASTO'
  final int? categoriaId;
  final String? categoriaNombre;
  final String? categoriaColor;
  final String? categoriaIcono;
  final int? metodoPagoId;
  final String? metodoPagoNombre;
  final double monto;
  final String moneda;
  final String? titulo;
  final String? descripcion;
  final DateTime fechaTransaccion;
  final String? archivoAdjunto;
  final String? notas;
  final bool repetir;
  final bool activa;
  final DateTime fechaCreacion;

  Transaccion({
    required this.id,
    required this.usuarioId,
    this.cuentaId,
    this.cuentaNombre,
    required this.tipoTransaccionId,
    required this.tipoNombre,
    this.categoriaId,
    this.categoriaNombre,
    this.categoriaColor,
    this.categoriaIcono,
    this.metodoPagoId,
    this.metodoPagoNombre,
    required this.monto,
    required this.moneda,
    this.titulo,
    this.descripcion,
    required this.fechaTransaccion,
    this.archivoAdjunto,
    this.notas,
    required this.repetir,
    required this.activa,
    required this.fechaCreacion,
  });

  factory Transaccion.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para parsear fechas de forma segura
    // Interpreta las fechas como hora local (no UTC)
    // Las fechas del servidor SQL Server vienen sin zona horaria y deben interpretarse como local
    DateTime parseDateSafe(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        final str = value.toString().trim();
        
        // Formato SQL Server: "2026-01-03 20:53:16.3433333"
        // Parsear manualmente para asegurar que se interprete como hora local
        if (str.contains(' ')) {
          final parts = str.split(' ');
          if (parts.length >= 2) {
            final dateParts = parts[0].split('-');
            final timePart = parts[1];
            final timeParts = timePart.split(':');
            
            if (dateParts.length == 3 && timeParts.length >= 2) {
              final year = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final day = int.parse(dateParts[2]);
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              
              // Manejar segundos y milisegundos
              int second = 0;
              int millisecond = 0;
              if (timeParts.length > 2) {
                final secPart = timeParts[2].split('.');
                second = int.parse(secPart[0]);
                if (secPart.length > 1) {
                  // Tomar solo los primeros 3 dígitos de los milisegundos
                  final msStr = secPart[1].substring(0, secPart[1].length > 3 ? 3 : secPart[1].length);
                  millisecond = int.parse(msStr.padRight(3, '0'));
                }
              }
              
              // Crear DateTime como hora local (sin conversión UTC)
              return DateTime(year, month, day, hour, minute, second, millisecond);
            }
          }
        }
        
        // Si tiene formato ISO con T
        if (str.contains('T')) {
          // Si no tiene Z o información de zona horaria, interpretar como local
          if (!str.contains('Z') && !str.contains('+') && !str.contains('-', 10)) {
            final dateTime = DateTime.parse(str);
            return DateTime(
              dateTime.year,
              dateTime.month,
              dateTime.day,
              dateTime.hour,
              dateTime.minute,
              dateTime.second,
              dateTime.millisecond,
            );
          }
          // Si tiene Z, es UTC, convertir a local
          return DateTime.parse(str).toLocal();
        }
        
        // Fallback: intentar parsear y asumir que es local si no tiene Z
        final parsed = DateTime.parse(str);
        if (str.contains('Z') || str.contains('+') || (str.contains('-') && str.length > 10)) {
          return parsed.toLocal();
        }
        // Si no tiene indicador de zona horaria, asumir que ya es local
        return DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
        );
      } catch (e) {
        return DateTime.now();
      }
    }

    return Transaccion(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      usuarioId: json['usuario_id'] is int
          ? json['usuario_id']
          : int.parse(json['usuario_id'].toString()),
      cuentaId: json['cuenta_id'],
      cuentaNombre: json['cuenta_nombre'],
      tipoTransaccionId: json['tipo_transaccion_id'] is int
          ? json['tipo_transaccion_id']
          : int.parse(json['tipo_transaccion_id'].toString()),
      tipoNombre: json['tipo_nombre'],
      categoriaId: json['categoria_id'],
      categoriaNombre: json['categoria_nombre'],
      categoriaColor: json['categoria_color'],
      categoriaIcono: json['categoria_icono'],
      metodoPagoId: json['metodo_pago_id'],
      metodoPagoNombre: json['metodo_pago_nombre'],
      monto: json['monto']?.toDouble() ?? 0.0,
      moneda: json['moneda'] ?? 'COP',
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      // Usar fecha_transaccion (la correcta según el usuario)
      fechaTransaccion: parseDateSafe(json['fecha_transaccion']),
      archivoAdjunto: json['archivo_adjunto'],
      notas: json['notas'],
      repetir: json['repetir'] ?? false,
      activa: json['activa'] ?? true,
      fechaCreacion: parseDateSafe(json['fecha_creacion']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'cuenta_id': cuentaId,
    'cuenta_nombre': cuentaNombre,
    'tipo_transaccion_id': tipoTransaccionId,
    'tipo_nombre': tipoNombre,
    'categoria_id': categoriaId,
    'categoria_nombre': categoriaNombre,
    'categoria_color': categoriaColor,
    'categoria_icono': categoriaIcono,
    'metodo_pago_id': metodoPagoId,
    'metodo_pago_nombre': metodoPagoNombre,
    'monto': monto,
    'moneda': moneda,
    'titulo': titulo,
    'descripcion': descripcion,
    'fecha_transaccion': fechaTransaccion.toIso8601String(),
    'archivo_adjunto': archivoAdjunto,
    'notas': notas,
    'repetir': repetir,
    'activa': activa,
    'fecha_creacion': fechaCreacion.toIso8601String(),
  };
}

class CreateTransaccionRequest {
  final int? cuentaId;
  final int tipoTransaccionId;
  final int? categoriaId;
  final int? metodoPagoId;
  final double monto;
  final String? moneda;
  final String? titulo;
  final String? descripcion;
  final DateTime? fechaTransaccion;
  final String? archivoAdjunto;
  final String? notas;
  final bool repetir;

  CreateTransaccionRequest({
    this.cuentaId,
    required this.tipoTransaccionId,
    this.categoriaId,
    this.metodoPagoId,
    required this.monto,
    this.moneda,
    this.titulo,
    this.descripcion,
    this.fechaTransaccion,
    this.archivoAdjunto,
    this.notas,
    this.repetir = false,
  });

  Map<String, dynamic> toJson() => {
    'cuentaId': cuentaId,
    'tipoTransaccionId': tipoTransaccionId,
    'categoriaId': categoriaId,
    'metodoPagoId': metodoPagoId,
    'monto': monto,
    'moneda': moneda ?? 'COP',
    if (titulo != null) 'titulo': titulo,
    if (descripcion != null) 'descripcion': descripcion,
    if (fechaTransaccion != null)
      'fechaTransaccion': formatApiDateTime(fechaTransaccion!),
    if (archivoAdjunto != null) 'archivoAdjunto': archivoAdjunto,
    if (notas != null) 'notas': notas,
    'repetir': repetir,
  };
}

class UpdateTransaccionRequest {
  final int? cuentaId;
  final int? tipoTransaccionId;
  final int? categoriaId;
  final int? metodoPagoId;
  final double? monto;
  final String? moneda;
  final String? titulo; // la nota; "" la borra
  final String? descripcion;
  final DateTime? fechaTransaccion;
  final String? archivoAdjunto;
  final String? notas;
  final bool? repetir;
  final bool? activa;

  UpdateTransaccionRequest({
    this.cuentaId,
    this.tipoTransaccionId,
    this.categoriaId,
    this.metodoPagoId,
    this.monto,
    this.moneda,
    this.titulo,
    this.descripcion,
    this.fechaTransaccion,
    this.archivoAdjunto,
    this.notas,
    this.repetir,
    this.activa,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (cuentaId != null) json['cuentaId'] = cuentaId;
    if (tipoTransaccionId != null) {
      json['tipoTransaccionId'] = tipoTransaccionId;
    }
    if (categoriaId != null) json['categoriaId'] = categoriaId;
    if (metodoPagoId != null) json['metodoPagoId'] = metodoPagoId;
    if (monto != null) json['monto'] = monto;
    if (moneda != null) json['moneda'] = moneda;
    if (titulo != null) json['titulo'] = titulo;
    if (descripcion != null) json['descripcion'] = descripcion;
    if (fechaTransaccion != null) {
      final dt = fechaTransaccion!.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      final y = dt.year.toString().padLeft(4, '0');
      final mo = two(dt.month);
      final da = two(dt.day);
      final hh = two(dt.hour);
      final mm = two(dt.minute);
      final ss = two(dt.second);
      json['fechaTransaccion'] = '$y-$mo-$da' 'T' '$hh:$mm:$ss';
    }
    if (archivoAdjunto != null) json['archivoAdjunto'] = archivoAdjunto;
    if (notas != null) json['notas'] = notas;
    if (repetir != null) json['repetir'] = repetir;
    if (activa != null) json['activa'] = activa;
    return json;
  }
}

class TransaccionSummary {
  final int totalTransacciones;
  final double totalIngresos;
  final double totalGastos;
  final double balance;

  TransaccionSummary({
    required this.totalTransacciones,
    required this.totalIngresos,
    required this.totalGastos,
    required this.balance,
  });

  factory TransaccionSummary.fromJson(Map<String, dynamic> json) =>
      TransaccionSummary(
        totalTransacciones: json['total_transacciones'] ?? 0,
        totalIngresos: json['total_ingresos']?.toDouble() ?? 0.0,
        totalGastos: json['total_gastos']?.toDouble() ?? 0.0,
        balance: json['balance']?.toDouble() ?? 0.0,
      );
}

/// Fecha y hora del teléfono sin zona ("2026-10-28T21:40:12"). La API la
/// guarda tal cual: así la hora es la del país del usuario, no la de Colombia.
String formatApiDateTime(DateTime dateTime) {
  final dt = dateTime.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final y = dt.year.toString().padLeft(4, '0');
  final mo = two(dt.month);
  final da = two(dt.day);
  final hh = two(dt.hour);
  final mm = two(dt.minute);
  final ss = two(dt.second);
  // Formato local sin Z ni milisegundos
  return '$y-$mo-$da' 'T' '$hh:$mm:$ss';
}
