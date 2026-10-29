import 'package:flutter/material.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_keypad.dart';

// Piezas del encabezado de color de "Nueva transacción" (diseño): un panel
// del color del tipo (gasto, ingreso, transferencia) con todo en blanco.

const _onPanel = Colors.white;
const _soft = Color(0x29FFFFFF); // blanco 16%
const _shade = Color(0x2E000000); // negro 18%

/// Panel redondeado del color del movimiento.
class FormPanel extends StatelessWidget {
  const FormPanel({super.key, required this.color, required this.children});

  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Botón circular translúcido (cerrar).
class PanelCircleButton extends StatelessWidget {
  const PanelCircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _soft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: _onPanel, size: 20, semanticLabel: label),
        ),
      ),
    );
  }
}

/// Círculo translúcido con un texto corto (la moneda).
class PanelBadge extends StatelessWidget {
  const PanelBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: _soft, shape: BoxShape.circle),
      child: Text(
        text,
        style: Brand.text(size: 11, weight: FontWeight.w800, color: _onPanel),
      ),
    );
  }
}

/// Selector de tipo: fondo oscurecido y la opción elegida en blanco.
class PanelTabs<T> extends StatelessWidget {
  const PanelTabs({
    super.key,
    required this.options,
    required this.value,
    required this.tone,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T value;
  final Color tone;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _shade,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (v, label) in options)
            Semantics(
              selected: v == value,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == value ? _onPanel : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: Brand.text(
                      size: 13,
                      weight: v == value ? FontWeight.w800 : FontWeight.w600,
                      color: v == value ? tone : _onPanel,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Etiqueta y monto grande en blanco.
class PanelAmount extends StatelessWidget {
  const PanelAmount({
    super.key,
    required this.entry,
    required this.label,
    this.sign = '',
  });

  final AmountEntry entry;
  final String label;
  final String sign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Brand.text(
              size: 13,
              weight: FontWeight.w600,
              color: const Color(0xD9FFFFFF),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 66,
            child: ListenableBuilder(
              listenable: entry,
              builder: (context, _) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$sign\$',
                      style: Brand.text(
                        size: 28,
                        weight: FontWeight.w700,
                        color: _onPanel,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.display,
                      style: Brand.text(
                        size: 54,
                        weight: FontWeight.w800,
                        letterSpacing: -1.6,
                        // Sin monto: el 0 se ve apagado
                        color: entry.isEmpty ? const Color(0x80FFFFFF) : _onPanel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Píldora de categoría dentro del panel: blanca si está elegida.
class PanelPill extends StatelessWidget {
  const PanelPill({
    super.key,
    required this.label,
    required this.selected,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _onPanel : _soft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Brand.text(
              size: 13,
              weight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? tone : _onPanel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de cuenta dentro del panel (transferencia: "Desde" / "Hacia").
class PanelAccountRow extends StatelessWidget {
  const PanelAccountRow({
    super.key,
    required this.label,
    required this.name,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String name;
  final String? detail;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _soft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: _onPanel, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Brand.text(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xD9FFFFFF),
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(
                        size: 15,
                        weight: FontWeight.w800,
                        color: _onPanel,
                      ),
                    ),
                  ],
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: Brand.text(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xD9FFFFFF),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, color: _onPanel, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón blanco con borde, ícono y texto (Cuenta · Hoy · Nota).
class FormActionButton extends StatelessWidget {
  const FormActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// true cuando el dato ya no es el predeterminado (fecha distinta, nota…)
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: highlighted ? Brand.ink : Brand.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: Brand.ink),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.text(size: 13, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
