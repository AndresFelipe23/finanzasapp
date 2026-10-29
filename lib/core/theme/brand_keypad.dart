import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'brand.dart';

// Monedas que en la práctica no usan centavos: su teclado tiene "000" en vez
// de la coma decimal
const _sinCentavos = {'COP', 'CLP', 'PYG', 'CRC', 'ARS', 'VES'};

bool monedaConCentavos(String moneda) => !_sinCentavos.contains(moneda);

/// Monto que se escribe con [AmountKeypad]. Guarda el texto tal cual se
/// tecleó ("12500" o "12,5") y lo expone como número y como texto formateado.
class AmountEntry extends ChangeNotifier {
  String _raw = '';

  String get raw => _raw;
  bool get isEmpty => _raw.isEmpty;

  double? get value =>
      _raw.isEmpty ? null : double.tryParse(_raw.replaceAll(',', '.'));

  /// Con separador de miles: "12.500" o "12.500,5".
  String get display {
    if (_raw.isEmpty) return '0';
    final parts = _raw.split(',');
    final entero = int.tryParse(parts.first) ?? 0;
    final miles = NumberFormat.decimalPattern('es_CO').format(entero);
    return parts.length > 1 ? '$miles,${parts[1]}' : miles;
  }

  void set(double? v) {
    if (v == null || v <= 0) {
      _raw = '';
    } else if (v == v.roundToDouble()) {
      _raw = v.toStringAsFixed(0);
    } else {
      _raw = v.toStringAsFixed(2).replaceAll('.', ',');
    }
    notifyListeners();
  }

  void press(String key) {
    final next = switch (key) {
      '⌫' => _raw.isEmpty ? '' : _raw.substring(0, _raw.length - 1),
      ',' => _raw.contains(',') ? _raw : (_raw.isEmpty ? '0,' : '$_raw,'),
      '000' => _raw.isEmpty ? '' : '${_raw}000',
      _ => _raw == '0' ? key : '$_raw$key',
    };
    // Máximo 2 decimales y 12 cifras enteras
    final parts = next.split(',');
    if (parts.length > 1 && parts[1].length > 2) return;
    if (parts.first.length > 12) return;
    if (next == _raw) return;
    _raw = next;
    notifyListeners();
  }

  void clear() {
    if (_raw.isEmpty) return;
    _raw = '';
    notifyListeners();
  }
}

/// Monto grande y centrado que refleja lo tecleado en [AmountKeypad].
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.entry,
    this.label = 'Monto',
    this.color = Brand.ink,
    this.badge,
  });

  final AmountEntry entry;
  final String label;
  final Color color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: entry,
      builder: (context, _) => Column(
        children: [
          Text(label, style: Brand.text(size: 13, color: Brand.muted)),
          const SizedBox(height: 2),
          SizedBox(
            height: 62,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$',
                    style: Brand.text(size: 28, weight: FontWeight.w700, color: color),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.display,
                    style: Brand.text(
                      size: 52,
                      weight: FontWeight.w800,
                      color: entry.isEmpty ? Brand.inputBorder : color,
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Brand.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Brand.border),
              ),
              child: Text(
                badge!,
                style: Brand.text(size: 12, weight: FontWeight.w600, color: Brand.muted),
              ),
            ),
        ],
      ),
    );
  }
}

/// Teclado numérico en pantalla: evita el teclado del sistema, que tapa la
/// mitad del formulario.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.entry,
    this.decimals = false,
    this.expand = false,
  });

  final AmountEntry entry;

  /// true: la tecla de abajo a la izquierda es la coma; false: "000".
  final bool decimals;

  /// true: las teclas crecen hasta llenar el alto disponible (va dentro de
  /// un Expanded), como en el diseño de "Nueva transacción".
  final bool expand;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1', '2', '3', //
      '4', '5', '6',
      '7', '8', '9',
      decimals ? ',' : '000', '0', '⌫',
    ];
    Widget grid(double ratio) => GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: _gap,
      crossAxisSpacing: _gap,
      childAspectRatio: ratio,
      children: [for (final k in keys) _Key(label: k, entry: entry)],
    );
    if (!expand) return grid(2.4);

    return LayoutBuilder(
      builder: (context, c) {
        if (!c.hasBoundedHeight) return grid(2.4);
        final w = (c.maxWidth - _gap * 2) / 3;
        final h = (c.maxHeight - _gap * 3) / 4;
        // Con mucho alto las teclas no pasan de casi cuadradas; el teclado
        // queda abajo, junto al botón de guardar
        final ratio = h <= 0 ? 2.4 : (w / h < 1.3 ? 1.3 : w / h);
        return Align(alignment: Alignment.bottomCenter, child: grid(ratio));
      },
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.entry});

  final String label;
  final AmountEntry entry;

  @override
  Widget build(BuildContext context) {
    final isBack = label == '⌫';
    // Tecla blanca con una línea inferior de sombra, como en el diseño
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Brand.border, offset: Offset(0, 1)),
        ],
      ),
      child: Material(
      color: Brand.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          entry.press(label);
        },
        // Mantener presionado el borrar limpia todo el monto
        onLongPress: isBack
            ? () {
                HapticFeedback.mediumImpact();
                entry.clear();
              }
            : null,
        child: Center(
          child: isBack
              ? const Icon(
                  Icons.backspace_outlined,
                  size: 24,
                  color: Brand.ink,
                  semanticLabel: 'Borrar (mantén presionado para borrar todo)',
                )
              : Text(
                  label,
                  style: Brand.text(size: label == '000' ? 22 : 26, weight: FontWeight.w700),
                ),
        ),
      ),
      ),
    );
  }
}
