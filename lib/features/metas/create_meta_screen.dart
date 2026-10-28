import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/meta_models.dart';
import 'metas_provider.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
class _C {
  static const primary       = Color(0xFF1E2340);
  static const accent        = Color(0xFF5B5FEE);
  static const success       = Color(0xFF22C55E);
  static const background    = Color(0xFFF4F6FB);
  static const surface       = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF1E2340);
  static const textSecondary = Color(0xFF64748B);
  static const border        = Color(0xFFE2E8F0);
}

// ── Top-level data ─────────────────────────────────────────────────────────────
class ColorOption {
  final String hex;
  final String name;
  final Color color;
  const ColorOption(this.hex, this.name, this.color);
}

class IconOption {
  final String key;
  final String name;
  final IconData iconData;
  const IconOption(this.key, this.name, this.iconData);
}

const _kColores = [
  ColorOption('#3B82F6', 'Azul',     Color(0xFF3B82F6)),
  ColorOption('#10B981', 'Verde',    Color(0xFF10B981)),
  ColorOption('#8B5CF6', 'Morado',   Color(0xFF8B5CF6)),
  ColorOption('#EC4899', 'Rosa',     Color(0xFFEC4899)),
  ColorOption('#F59E0B', 'Amarillo', Color(0xFFF59E0B)),
  ColorOption('#EF4444', 'Rojo',     Color(0xFFEF4444)),
  ColorOption('#06B6D4', 'Cian',     Color(0xFF06B6D4)),
  ColorOption('#6366F1', 'Índigo',   Color(0xFF6366F1)),
];

const _kIconos = [
  IconOption('flag',           'Meta',        Icons.flag_rounded),
  IconOption('home',           'Casa',        Icons.home_rounded),
  IconOption('directions_car', 'Auto',        Icons.directions_car_rounded),
  IconOption('flight',         'Viaje',       Icons.flight_rounded),
  IconOption('shopping_bag',   'Compras',     Icons.shopping_bag_rounded),
  IconOption('school',         'Educación',   Icons.school_rounded),
  IconOption('favorite',       'Salud',       Icons.favorite_rounded),
  IconOption('savings',        'Ahorros',     Icons.savings_rounded),
  IconOption('work',           'Trabajo',     Icons.work_rounded),
  IconOption('celebration',    'Celebración', Icons.celebration_rounded),
  IconOption('star',           'Estrella',    Icons.star_rounded),
  IconOption('card_giftcard',  'Regalo',      Icons.card_giftcard_rounded),
  IconOption('beach_access',   'Vacaciones',  Icons.beach_access_rounded),
  IconOption('fitness_center', 'Fitness',     Icons.fitness_center_rounded),
  IconOption('restaurant',     'Restaurante', Icons.restaurant_rounded),
  IconOption('music_note',     'Música',      Icons.music_note_rounded),
];

IconData _iconData(String? key) {
  for (final o in _kIconos) {
    if (o.key == key) return o.iconData;
  }
  return Icons.flag_rounded;
}

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return _C.accent;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return _C.accent;
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class CreateMetaScreen extends ConsumerStatefulWidget {
  final Meta? metaToEdit;
  const CreateMetaScreen({super.key, this.metaToEdit});

  @override
  ConsumerState<CreateMetaScreen> createState() => _CreateMetaScreenState();
}

class _CreateMetaScreenState extends ConsumerState<CreateMetaScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _nombreController     = TextEditingController();
  final _descripcionController = TextEditingController();
  final _montoController      = TextEditingController();
  DateTime _fechaObjetivo = DateTime.now().add(const Duration(days: 30));
  String? _selectedColor;
  String? _selectedIcono;
  bool _isSubmitting = false;

  bool get isEdit => widget.metaToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.metaToEdit != null) {
      final m = widget.metaToEdit!;
      _nombreController.text       = m.nombre;
      _descripcionController.text  = m.descripcion ?? '';
      _montoController.text        = m.montoObjetivo.toStringAsFixed(0);
      _fechaObjetivo               = m.fechaObjetivo;
      _selectedColor               = m.color;
      _selectedIcono               = m.icono;
    } else {
      _selectedColor = _kColores[0].hex;
      _selectedIcono = _kIconos[0].key;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metaColor     = _parseColor(_selectedColor);
    final fmt           = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final montoObjetivo = double.tryParse(_montoController.text) ?? 0.0;
    final diasRestantes = _fechaObjetivo.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: _C.background,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: _C.textPrimary),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? 'Editar Meta' : 'Nueva Meta',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _C.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PreviewCard(
                nombre:       _nombreController.text,
                metaColor:    metaColor,
                icono:        _selectedIcono,
                monto:        montoObjetivo,
                fmt:          fmt,
                dias:         diasRestantes,
                isEdit:       isEdit,
                metaOriginal: widget.metaToEdit,
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Información básica'),
              const SizedBox(height: 12),
              _Field(
                controller: _nombreController,
                label: 'Nombre de la meta',
                hint: 'Ej: Viaje a Europa',
                prefixIcon: Icon(_iconData(_selectedIcono), color: metaColor, size: 20),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El nombre es requerido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _descripcionController,
                label: 'Descripción (opcional)',
                hint: 'Describe tu meta...',
                prefixIcon: const Icon(Icons.description_outlined, color: _C.textSecondary, size: 20),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Objetivo'),
              const SizedBox(height: 12),
              _Field(
                controller: _montoController,
                label: 'Monto objetivo',
                hint: '0',
                prefixIcon: Icon(Icons.attach_money_rounded, color: metaColor, size: 20),
                suffix: Text(
                  'COP',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _C.textSecondary),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El monto es requerido';
                  final m = double.tryParse(v);
                  if (m == null || m <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DateField(
                fecha: _fechaObjetivo,
                accentColor: metaColor,
                onTap: () async {
                  final f = await showDatePicker(
                    context: context,
                    initialDate: _fechaObjetivo,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (f != null) setState(() => _fechaObjetivo = f);
                },
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Personalización'),
              const SizedBox(height: 16),
              Text(
                'Color',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _C.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _ColorPicker(
                selected: _selectedColor,
                onSelect: (hex) => setState(() => _selectedColor = hex),
              ),
              const SizedBox(height: 20),
              Text(
                'Icono',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _C.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _IconGrid(
                selected: _selectedIcono,
                accentColor: metaColor,
                onSelect: (key) => setState(() => _selectedIcono = key),
              ),
              const SizedBox(height: 32),
              _SubmitRow(
                isEdit:       isEdit,
                isSubmitting: _isSubmitting,
                onSubmit:     _handleSubmit,
                onCancel:     () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final request = CreateMetaRequest(
        nombre:        _nombreController.text.trim(),
        descripcion:   _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        montoObjetivo: double.parse(_montoController.text),
        fechaObjetivo: _fechaObjetivo,
        color:         _selectedColor,
        icono:         _selectedIcono,
      );
      if (isEdit) {
        await ref
            .read(metasNotifierProvider.notifier)
            .updateMeta(widget.metaToEdit!.id, request);
      } else {
        await ref.read(metasNotifierProvider.notifier).create(request);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(isEdit ? 'Meta actualizada' : 'Meta creada'),
            ]),
            backgroundColor: _C.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: ${e.toString()}')),
            ]),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ── Preview card ───────────────────────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  final String nombre;
  final Color metaColor;
  final String? icono;
  final double monto;
  final NumberFormat fmt;
  final int dias;
  final bool isEdit;
  final Meta? metaOriginal;

  const _PreviewCard({
    required this.nombre,
    required this.metaColor,
    required this.icono,
    required this.monto,
    required this.fmt,
    required this.dias,
    required this.isEdit,
    required this.metaOriginal,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = nombre.isEmpty ? 'Vista previa' : nombre;
    final montoActual = metaOriginal?.montoActual ?? 0.0;
    final porcentaje  = monto > 0
        ? (montoActual / monto * 100).clamp(0.0, 100.0)
        : 0.0;
    final faltante   = (monto - montoActual).clamp(0.0, double.infinity);
    final completada = montoActual >= monto && monto > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: _C.surface,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: metaColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: metaColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_iconData(icono), color: metaColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _C.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  monto > 0 ? fmt.format(monto) : '\$0',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: metaColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (dias > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: metaColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$dias d',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: metaColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isEdit && metaOriginal != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _C.textSecondary),
                            ),
                            Text(
                              '${porcentaje.toStringAsFixed(1)}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: completada ? _C.success : metaColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: porcentaje / 100,
                            minHeight: 5,
                            backgroundColor: _C.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              completada ? _C.success : metaColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ahorrado: ${fmt.format(montoActual)}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _C.textSecondary),
                            ),
                            Text(
                              'Faltante: ${fmt.format(faltante)}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _C.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _C.textPrimary,
        ),
      );
}

// ── Reusable field ─────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Widget? prefixIcon;
  final Widget? suffix;
  final int? maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
          suffix: suffix,
          filled: true,
          fillColor: _C.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _C.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        validator: validator,
      );
}

// ── Date field ─────────────────────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  final DateTime fecha;
  final Color accentColor;
  final VoidCallback onTap;

  const _DateField({
    required this.fecha,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: accentColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha objetivo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _C.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy').format(fecha),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Color picker ───────────────────────────────────────────────────────────────
class _ColorPicker extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;

  const _ColorPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _kColores.map((c) {
        final isSel = selected == c.hex;
        return GestureDetector(
          onTap: () => onSelect(c.hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.color,
              shape: BoxShape.circle,
              border: isSel
                  ? Border.all(color: _C.surface, width: 2.5)
                  : Border.all(color: _C.border, width: 1.5),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: c.color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isSel
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ── Icon grid ──────────────────────────────────────────────────────────────────
class _IconGrid extends StatelessWidget {
  final String? selected;
  final Color accentColor;
  final void Function(String) onSelect;

  const _IconGrid({
    required this.selected,
    required this.accentColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: _kIconos.map((o) {
        final isSel = selected == o.key;
        return GestureDetector(
          onTap: () => onSelect(o.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSel ? accentColor.withValues(alpha: 0.1) : _C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? accentColor : _C.border,
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  o.iconData,
                  color: isSel ? accentColor : _C.textSecondary,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  o.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                    color: isSel ? accentColor : _C.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Submit row ─────────────────────────────────────────────────────────────────
class _SubmitRow extends StatelessWidget {
  final bool isEdit;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _SubmitRow({
    required this.isEdit,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onCancel,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border),
              ),
              alignment: Alignment.center,
              child: Text(
                'Cancelar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _C.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: isSubmitting ? null : onSubmit,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isSubmitting
                    ? _C.accent.withValues(alpha: 0.6)
                    : _C.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEdit ? 'Guardar Cambios' : 'Crear Meta',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
