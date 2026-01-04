/// Constantes de monedas de países de habla hispana
/// Incluye el código ISO 4217 de la moneda y el nombre del país
library;

class MonedaInfo {
  final String codigo; // Código ISO 4217 (ej: COP, USD, EUR)
  final String pais; // Nombre del país
  final String nombreMoneda; // Nombre de la moneda

  const MonedaInfo({
    required this.codigo,
    required this.pais,
    required this.nombreMoneda,
  });

  String get displayName => '$codigo - $pais';
  String get fullName => '$nombreMoneda ($pais)';
}

/// Lista completa de monedas de países de habla hispana
class MonedasConstants {
  // Monedas principales ordenadas por uso común
  static const List<MonedaInfo> monedasHispanas = [
    // América del Sur
    MonedaInfo(codigo: 'COP', pais: 'Colombia', nombreMoneda: 'Peso Colombiano'),
    MonedaInfo(codigo: 'ARS', pais: 'Argentina', nombreMoneda: 'Peso Argentino'),
    MonedaInfo(codigo: 'CLP', pais: 'Chile', nombreMoneda: 'Peso Chileno'),
    MonedaInfo(codigo: 'PEN', pais: 'Perú', nombreMoneda: 'Sol Peruano'),
    MonedaInfo(codigo: 'BOB', pais: 'Bolivia', nombreMoneda: 'Boliviano'),
    MonedaInfo(codigo: 'PYG', pais: 'Paraguay', nombreMoneda: 'Guaraní'),
    MonedaInfo(codigo: 'UYU', pais: 'Uruguay', nombreMoneda: 'Peso Uruguayo'),
    MonedaInfo(codigo: 'VES', pais: 'Venezuela', nombreMoneda: 'Bolívar Soberano'),
    
    // América Central y Caribe
    MonedaInfo(codigo: 'MXN', pais: 'México', nombreMoneda: 'Peso Mexicano'),
    MonedaInfo(codigo: 'GTQ', pais: 'Guatemala', nombreMoneda: 'Quetzal'),
    MonedaInfo(codigo: 'HNL', pais: 'Honduras', nombreMoneda: 'Lempira'),
    MonedaInfo(codigo: 'NIO', pais: 'Nicaragua', nombreMoneda: 'Córdoba'),
    MonedaInfo(codigo: 'CRC', pais: 'Costa Rica', nombreMoneda: 'Colón'),
    MonedaInfo(codigo: 'PAB', pais: 'Panamá', nombreMoneda: 'Balboa'),
    MonedaInfo(codigo: 'DOP', pais: 'República Dominicana', nombreMoneda: 'Peso Dominicano'),
    MonedaInfo(codigo: 'CUP', pais: 'Cuba', nombreMoneda: 'Peso Cubano'),
    
    // Países que usan USD
    MonedaInfo(codigo: 'USD', pais: 'Ecuador', nombreMoneda: 'Dólar Estadounidense'),
    MonedaInfo(codigo: 'USD', pais: 'El Salvador', nombreMoneda: 'Dólar Estadounidense'),
    MonedaInfo(codigo: 'USD', pais: 'Panamá (USD)', nombreMoneda: 'Dólar Estadounidense'),
    
    // Europa
    MonedaInfo(codigo: 'EUR', pais: 'España', nombreMoneda: 'Euro'),
  ];

  /// Obtener solo los códigos de moneda únicos (sin duplicados)
  static List<String> get codigosUnicos {
    final codigos = monedasHispanas.map((m) => m.codigo).toSet().toList();
    codigos.sort();
    return codigos;
  }

  /// Obtener información de una moneda por su código
  static MonedaInfo? getMonedaPorCodigo(String codigo) {
    try {
      return monedasHispanas.firstWhere(
        (m) => m.codigo == codigo.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtener todas las monedas de un país específico
  static List<MonedaInfo> getMonedasPorPais(String pais) {
    return monedasHispanas
        .where((m) => m.pais.toLowerCase().contains(pais.toLowerCase()))
        .toList();
  }

  /// Verificar si un código de moneda es válido
  static bool esMonedaValida(String codigo) {
    return codigosUnicos.contains(codigo.toUpperCase());
  }

  /// Obtener el nombre del país para un código de moneda
  /// Si hay múltiples países con la misma moneda, devuelve el primero
  static String? getPaisPorCodigo(String codigo) {
    final moneda = getMonedaPorCodigo(codigo);
    return moneda?.pais;
  }

  /// Obtener el nombre completo de la moneda para un código
  static String? getNombreMonedaPorCodigo(String codigo) {
    final moneda = getMonedaPorCodigo(codigo);
    return moneda?.nombreMoneda;
  }
}

