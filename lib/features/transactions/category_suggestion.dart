import '../../core/models/transaccion_models.dart';

/// Categoría que más se usó antes con una nota parecida ("Uber" →
/// Transporte), entre las de [validas]. Null si no hay coincidencias.
int? sugerirCategoriaPorNota(
  String nota,
  String tipo,
  Iterable<Transaccion> trans,
  Set<int> validas,
) {
  final q = nota.trim().toLowerCase();
  if (q.length < 3) return null;
  final votos = <int, int>{};
  for (final t in trans) {
    final titulo = t.titulo?.toLowerCase();
    final id = t.categoriaId;
    if (titulo == null || id == null || !validas.contains(id)) continue;
    if (t.tipoNombre != tipo) continue;
    if (titulo == q || titulo.contains(q) || q.contains(titulo)) {
      votos[id] = (votos[id] ?? 0) + 1;
    }
  }
  if (votos.isEmpty) return null;
  return (votos.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
      .first
      .key;
}
