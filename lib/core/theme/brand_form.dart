import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'brand.dart';

/// Piezas comunes de los formularios con el diseño nuevo.

String brandDateLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final fecha = DateFormat('d MMM yyyy', 'es_ES').format(d).replaceAll('.', '');
  final diff = day.difference(today).inDays;
  return switch (diff) {
    0 => 'Hoy, $fecha',
    -1 => 'Ayer, $fecha',
    1 => 'Mañana, $fecha',
    _ => fecha,
  };
}

Future<DateTime?> pickBrandDate(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
}) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(2000),
    lastDate: last ?? DateTime(2100),
    locale: const Locale('es', 'ES'),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(
          primary: Brand.accent,
          onPrimary: Colors.white,
          surface: Brand.surface,
          onSurface: Brand.ink,
        ),
      ),
      child: child!,
    ),
  );
}

/// Pantalla de formulario: encabezado con cerrar, contenido desplazable y
/// botón principal fijo abajo.
class BrandFormPage extends StatelessWidget {
  const BrandFormPage({
    super.key,
    required this.title,
    required this.children,
    required this.submitLabel,
    required this.onSubmit,
    this.loading = false,
    this.actions = const [],
  });

  final String title;
  final List<Widget> children;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool loading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Material(
                    color: Brand.surface,
                    shape: const CircleBorder(side: BorderSide(color: Brand.border)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.close_rounded,
                            color: Brand.ink, semanticLabel: 'Cerrar'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(size: 20, weight: FontWeight.w800),
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: children,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: BrandButton(
                  label: submitLabel,
                  loading: loading,
                  onPressed: onSubmit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Control segmentado del diseño (pestañas grises con la activa en blanco).
class BrandSegmented<T> extends StatelessWidget {
  const BrandSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Brand.track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (i, (v, label)) in options.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                selected: v == value,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == value ? Brand.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: v == value
                          ? const [
                              BoxShadow(
                                color: Color(0x1410201B),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(
                        size: 14,
                        weight: v == value ? FontWeight.w700 : FontWeight.w600,
                        color: v == value ? Brand.ink : Brand.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Monto grande y centrado, como en "Nueva transacción".
class BrandAmountInput extends StatelessWidget {
  const BrandAmountInput({
    super.key,
    required this.controller,
    this.label = 'Monto',
    this.color = Brand.ink,
    this.badge,
    this.autofocus = false,
    this.decimals = false,
  });

  final TextEditingController controller;
  final String label;
  final Color color;
  final String? badge;
  final bool autofocus;
  final bool decimals;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Brand.text(size: 13, color: Brand.muted)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('\$', style: Brand.text(size: 28, weight: FontWeight.w700, color: color)),
            const SizedBox(width: 6),
            IntrinsicWidth(
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.numberWithOptions(decimal: decimals),
                inputFormatters: [
                  decimals
                      ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                      : FilteringTextInputFormatter.digitsOnly,
                ],
                cursorColor: color,
                style: Brand.text(
                  size: 48,
                  weight: FontWeight.w800,
                  color: color,
                  letterSpacing: -1.4,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '0',
                  hintStyle: Brand.text(
                    size: 48,
                    weight: FontWeight.w800,
                    color: Brand.inputBorder,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (badge != null) ...[
          const SizedBox(height: 4),
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
      ],
    );
  }
}

/// Etiqueta de sección de formulario.
class BrandLabel extends StatelessWidget {
  const BrandLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Brand.text(size: 13, weight: FontWeight.w700)),
  );
}

/// Tarjeta blanca con filas separadas por líneas (Cuenta, Fecha, Nota…).
class BrandGroup extends StatelessWidget {
  const BrandGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) const Divider(height: 1, color: Brand.border),
            c,
          ],
        ],
      ),
    );
  }
}

/// Fila con etiqueta a la izquierda y valor a la derecha; al tocar abre algo.
class BrandGroupRow extends StatelessWidget {
  const BrandGroupRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.placeholder = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              Text(label, style: Brand.text(size: 14, color: Brand.muted)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.text(
                    size: 14,
                    weight: placeholder ? FontWeight.w500 : FontWeight.w700,
                    color: placeholder ? Brand.placeholder : Brand.ink,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Brand.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila con un campo de texto alineado a la derecha.
class BrandGroupTextRow extends StatelessWidget {
  const BrandGroupTextRow({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Text(label, style: Brand.text(size: 14, color: Brand.muted)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.right,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                cursorColor: Brand.accent,
                style: Brand.text(size: 14, weight: FontWeight.w700),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: hint,
                  hintStyle: Brand.text(size: 14, color: Brand.placeholder),
                  suffixText: suffix,
                  suffixStyle: Brand.text(size: 14, color: Brand.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila con interruptor y texto de ayuda.
class BrandSwitchRow extends StatelessWidget {
  const BrandSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Brand.text(size: 14, weight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: Brand.text(size: 12, color: Brand.muted, height: 1.35)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: Brand.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Opción de una lista de selección.
class BrandOption<T> {
  const BrandOption(this.value, this.label, {this.subtitle, this.icon, this.color});

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
}

/// Hoja inferior para elegir una opción de una lista.
Future<T?> showBrandPicker<T>(
  BuildContext context, {
  required String title,
  required List<BrandOption<T>> options,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Brand.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.75),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Brand.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(title, style: Brand.text(size: 20, weight: FontWeight.w800)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                children: [
                  for (final o in options)
                    ListTile(
                      onTap: () => Navigator.pop(ctx, o.value),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: o.icon == null
                          ? null
                          : Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: (o.color ?? Brand.ink).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(o.icon, size: 18, color: o.color ?? Brand.ink),
                            ),
                      title: Text(o.label, style: Brand.text(weight: FontWeight.w600)),
                      subtitle: o.subtitle == null
                          ? null
                          : Text(o.subtitle!,
                              style: Brand.text(size: 12, color: Brand.muted)),
                      trailing: o.value == selected
                          ? const Icon(Icons.check_rounded, color: Brand.accent)
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Campo de texto de varias líneas con el borde del diseño.
class BrandTextArea extends StatelessWidget {
  const BrandTextArea({super.key, required this.controller, this.hint});

  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Brand.inputBorder),
    );
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      style: Brand.text(size: 14),
      cursorColor: Brand.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Brand.text(size: 14, color: Brand.placeholder),
        filled: true,
        fillColor: Brand.surface,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Brand.accent, width: 1.5),
        ),
      ),
    );
  }
}

/// Lee un monto de un campo (acepta coma o punto como separador decimal).
double? parseAmount(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));
