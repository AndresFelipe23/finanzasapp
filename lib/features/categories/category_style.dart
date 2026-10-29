import 'package:flutter/material.dart';
import '../../core/theme/brand.dart';

/// Íconos de categoría: el nombre es lo que se guarda en `categorias.icono`.
/// Incluye los que ya usaba la app para que las categorías viejas se vean bien.
const categoryIcons = <String, (IconData, String)>{
  'shopping_cart': (Icons.shopping_cart_outlined, 'Compras'),
  'restaurant': (Icons.restaurant_outlined, 'Comida'),
  'home': (Icons.home_outlined, 'Hogar'),
  'directions_car': (Icons.directions_car_outlined, 'Transporte'),
  'star': (Icons.star_outline_rounded, 'Ocio'),
  'bolt': (Icons.bolt_outlined, 'Servicios'),
  'local_hospital': (Icons.local_hospital_outlined, 'Salud'),
  'school': (Icons.school_outlined, 'Educación'),
  'pets': (Icons.pets_outlined, 'Mascotas'),
  'local_cafe': (Icons.local_cafe_outlined, 'Café'),
  'checkroom': (Icons.checkroom_outlined, 'Ropa'),
  'receipt': (Icons.receipt_long_outlined, 'Facturas'),
  'sports_esports': (Icons.sports_esports_outlined, 'Entretenimiento'),
  'work': (Icons.work_outline_rounded, 'Trabajo'),
  'computer': (Icons.computer_outlined, 'Tecnología'),
  'sell': (Icons.sell_outlined, 'Ventas'),
  'card_giftcard': (Icons.card_giftcard_outlined, 'Regalo'),
  'trending_up': (Icons.trending_up_rounded, 'Inversiones'),
  'percent': (Icons.percent_rounded, 'Intereses'),
  'attach_money': (Icons.attach_money_rounded, 'Dinero'),
  'more_horiz': (Icons.more_horiz_rounded, 'Otros'),
};

IconData categoryIcon(String? name) =>
    categoryIcons[name]?.$1 ?? Icons.category_outlined;

/// Paleta del diseño: (nombre, color del ícono, fondo suave). El color de
/// texto se guarda en `categorias.color` como #RRGGBB.
const categoryPalette = <(String, Color, Color)>[
  ('Verde', Brand.accent, Brand.accentSoft),
  ('Azul', Brand.blue, Brand.blueSoft),
  ('Morado', Color(0xFF6B3FA0), Color(0xFFEEE8F5)),
  ('Naranja', Brand.expense, Brand.expenseSoft),
  ('Ocre', Color(0xFF8A6A00), Color(0xFFF6EFD6)),
  ('Grafito', Brand.ink, Brand.track),
];

String colorToHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Color del ícono y su fondo. Si el color guardado es de la paleta se usa
/// su fondo exacto; si es uno de los colores anteriores, un tono suave de él.
(Color fg, Color bg) categoryColors(String? hex, String tipo) {
  final parsed = _parse(hex);
  if (parsed != null) {
    for (final (_, fg, bg) in categoryPalette) {
      if (fg.toARGB32() == parsed.toARGB32()) return (fg, bg);
    }
    return (parsed, parsed.withValues(alpha: 0.14));
  }
  return tipo == 'INGRESO'
      ? (Brand.accent, Brand.accentSoft)
      : (Brand.expense, Brand.expenseSoft);
}

Color? _parse(String? h) {
  if (h == null || h.isEmpty) return null;
  final s = h.replaceAll('#', '');
  try {
    return s.length == 6
        ? Color(int.parse('FF$s', radix: 16))
        : Color(int.parse(s, radix: 16));
  } catch (_) {
    return null;
  }
}
