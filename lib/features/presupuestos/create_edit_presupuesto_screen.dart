import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/presupuesto_models.dart';
import 'presupuestos_provider.dart';
import '../categories/categories_provider.dart';
import '../accounts/accounts_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const Color bg = Color(0xFFF4F6FB);
  static const Color primary = Color(0xFF1E2340);
  static const Color accent = Color(0xFF5B5FEE);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textSub = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
}

class CreateEditPresupuestoScreen extends ConsumerStatefulWidget {
  final Presupuesto? presupuesto;
  const CreateEditPresupuestoScreen({super.key, this.presupuesto});

  @override
  ConsumerState<CreateEditPresupuestoScreen> createState() =>
      _CreateEditPresupuestoScreenState();
}

class _CreateEditPresupuestoScreenState
    extends ConsumerState<CreateEditPresupuestoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  String _periodo = 'MENSUAL';
  DateTime? _inicio;
  DateTime? _fin;
  int? _categoriaId;
  int? _cuentaId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.presupuesto != null) {
      final p = widget.presupuesto!;
      _nombreCtrl.text = p.nombre;
      _montoCtrl.text = p.montoLimite.toStringAsFixed(0);
      _notasCtrl.text = p.notas ?? '';
      _periodo = p.periodo;
      _inicio = p.fechaInicio;
      _fin = p.fechaFin;
      _categoriaId = p.categoriaId;
      _cuentaId = p.cuentaId;
    }
    _autocalcularFechas();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(expenseCategoriesProvider);
    final cuentasAsync = ref.watch(accountsProvider);
    final isEdit = widget.presupuesto != null;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _C.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? 'Editar presupuesto' : 'Nuevo presupuesto',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _C.primary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Información básica ────────────────────────────────────
              _SectionLabel(label: 'Información básica'),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  children: [
                    _Field(
                      controller: _nombreCtrl,
                      label: 'Nombre',
                      hint: 'Ej: Supermercado, Entretenimiento',
                      icon: Icons.label_outline_rounded,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'El nombre es requerido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _MontoField(
                      controller: _montoCtrl,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Periodo ───────────────────────────────────────────────
              _SectionLabel(label: 'Periodo'),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PeriodoSelector(
                      selected: _periodo,
                      onChanged: (v) => setState(() {
                        _periodo = v;
                        _autocalcularFechas();
                      }),
                    ),
                    const SizedBox(height: 16),
                    _FechasRow(
                      inicio: _inicio,
                      fin: _fin,
                      periodo: _periodo,
                      onInicioChanged: (d) => setState(() {
                        _inicio = d;
                        _autocalcularFechas(alCambiarInicio: true);
                      }),
                      onFinChanged: (d) => setState(() => _fin = d),
                    ),
                    if (_inicio != null) ...[
                      const SizedBox(height: 12),
                      _RangoInfo(
                          inicio: _inicio!, fin: _fin, periodo: _periodo),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Filtros opcionales ────────────────────────────────────
              _SectionLabel(label: 'Filtros', optional: true),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  children: [
                    categoriasAsync.when(
                      data: (cats) => _CategoriaDropdown(
                        categorias: cats,
                        value: _categoriaId,
                        onChanged: (v) => setState(() => _categoriaId = v),
                      ),
                      loading: () => const _DropdownLoading(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                    cuentasAsync.when(
                      data: (cuentas) => _CuentaDropdown(
                        cuentas: cuentas,
                        value: _cuentaId,
                        onChanged: (v) => setState(() => _cuentaId = v),
                      ),
                      loading: () => const _DropdownLoading(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Notas ─────────────────────────────────────────────────
              _SectionLabel(label: 'Notas', optional: true),
              const SizedBox(height: 12),
              _Card(
                child: TextFormField(
                  controller: _notasCtrl,
                  decoration: InputDecoration(
                    hintText: 'Agrega notas o recordatorios...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: _C.textSub.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.sticky_note_2_outlined,
                        color: _C.textSub, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: _C.primary),
                  maxLines: 4,
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────────
              _SubmitButton(
                isLoading: _isLoading,
                isEdit: isEdit,
                monto: double.tryParse(_montoCtrl.text) ?? 0,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Lógica ──────────────────────────────────────────────────────────────────
  void _autocalcularFechas({bool alCambiarInicio = false}) {
    final hoy = DateTime.now();
    final base = _inicio ?? DateTime(hoy.year, hoy.month, hoy.day);

    if (_periodo == 'SEMANAL') {
      _inicio = DateTime(base.year, base.month, base.day);
      final fin = base.add(const Duration(days: 6));
      _fin = DateTime(fin.year, fin.month, fin.day);
    } else if (_periodo == 'MENSUAL') {
      _inicio = DateTime(base.year, base.month, 1);
      final next = DateTime(base.year, base.month + 1, 1);
      _fin = next.subtract(const Duration(days: 1));
    } else if (_periodo == 'ANUAL') {
      _inicio = DateTime(base.year, 1, 1);
      _fin = DateTime(base.year, 12, 31);
    } else {
      if (alCambiarInicio && (_fin == null || _fin!.isBefore(_inicio!))) {
        _fin = _inicio;
      }
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final req = CreatePresupuestoRequest(
      nombre: _nombreCtrl.text.trim(),
      periodo: _periodo,
      montoLimite: double.parse(_montoCtrl.text),
      fechaInicio: _inicio,
      fechaFin: _periodo == 'PERSONALIZADO' ? _fin : null,
      categoriaId: _categoriaId,
      cuentaId: _cuentaId,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );

    try {
      if (widget.presupuesto == null) {
        await ref.read(presupuestosNotifierProvider.notifier).create(req);
      } else {
        await ref
            .read(presupuestosNotifierProvider.notifier)
            .update(widget.presupuesto!.id, req.toJson());
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  widget.presupuesto != null
                      ? 'Presupuesto actualizado'
                      : 'Presupuesto creado',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: _C.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: _C.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool optional;
  const _SectionLabel({required this.label, this.optional = false});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.primary,
              letterSpacing: 0.1,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: 6),
            Text(
              'opcional',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: _C.textSub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );
}

// ─── Card wrapper ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
}

// ─── Input field ──────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _C.primary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: _C.textSub, fontWeight: FontWeight.w500),
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: _C.textSub.withValues(alpha: 0.55)),
          prefixIcon: Icon(icon, color: _C.accent, size: 20),
          filled: true,
          fillColor: _C.bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.danger, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
      );
}

// ─── Monto field ──────────────────────────────────────────────────────────────
class _MontoField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _MontoField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _C.primary,
          letterSpacing: -0.5,
        ),
        decoration: InputDecoration(
          labelText: 'Monto límite',
          labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: _C.textSub, fontWeight: FontWeight.w500),
          hintText: '0',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _C.textSub.withValues(alpha: 0.3),
          ),
          prefixIcon: const Icon(Icons.attach_money_rounded,
              color: _C.success, size: 22),
          suffixText: 'COP',
          suffixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: _C.textSub, fontWeight: FontWeight.w600),
          filled: true,
          fillColor: _C.success.withValues(alpha: 0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: _C.success.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.success, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.danger, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        validator: (v) {
          final d = double.tryParse(v ?? '');
          if (d == null || d <= 0) return 'Ingresa un monto válido';
          return null;
        },
        onChanged: (_) => onChanged(),
      );
}

// ─── Periodo selector ─────────────────────────────────────────────────────────
class _PeriodoSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _PeriodoSelector(
      {required this.selected, required this.onChanged});

  static const _options = [
    (value: 'SEMANAL', label: 'Semanal', icon: Icons.calendar_view_week_rounded),
    (value: 'MENSUAL', label: 'Mensual', icon: Icons.calendar_view_month_rounded),
    (value: 'ANUAL', label: 'Anual', icon: Icons.calendar_today_rounded),
    (value: 'PERSONALIZADO', label: 'Personalizado', icon: Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _options.map((opt) {
          final isSel = selected == opt.value;
          return GestureDetector(
            onTap: () => onChanged(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? _C.accent : _C.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSel ? _C.accent : _C.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    opt.icon,
                    size: 16,
                    color: isSel ? Colors.white : _C.textSub,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    opt.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : _C.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
}

// ─── Fechas row ───────────────────────────────────────────────────────────────
class _FechasRow extends StatelessWidget {
  final DateTime? inicio;
  final DateTime? fin;
  final String periodo;
  final void Function(DateTime) onInicioChanged;
  final void Function(DateTime) onFinChanged;

  const _FechasRow({
    required this.inicio,
    required this.fin,
    required this.periodo,
    required this.onInicioChanged,
    required this.onFinChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _FechaBtn(
              label: 'Inicio',
              date: inicio,
              icon: Icons.event_rounded,
              enabled: true,
              onTap: () async {
                final d = await _pick(context, inicio);
                if (d != null) onInicioChanged(d);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FechaBtn(
              label: 'Fin',
              date: fin,
              icon: Icons.event_available_rounded,
              enabled: periodo == 'PERSONALIZADO',
              onTap: () async {
                final d = await _pick(context, fin);
                if (d != null) onFinChanged(d);
              },
            ),
          ),
        ],
      );

  Future<DateTime?> _pick(BuildContext ctx, DateTime? current) {
    return showDatePicker(
      context: ctx,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _C.accent),
        ),
        child: child!,
      ),
    );
  }
}

class _FechaBtn extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _FechaBtn({
    required this.label,
    required this.date,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    final color = enabled ? _C.accent : _C.textSub.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: enabled
              ? (hasDate
                  ? _C.accent.withValues(alpha: 0.06)
                  : _C.bg)
              : _C.divider,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? (hasDate ? _C.accent.withValues(alpha: 0.3) : _C.border)
                : _C.border.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasDate ? _fmt(date!) : 'Seleccionar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: enabled ? _C.primary : _C.textSub.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Rango info ───────────────────────────────────────────────────────────────
class _RangoInfo extends StatelessWidget {
  final DateTime inicio;
  final DateTime? fin;
  final String periodo;
  const _RangoInfo(
      {required this.inicio, required this.fin, required this.periodo});

  @override
  Widget build(BuildContext context) {
    final dias =
        fin != null ? fin!.difference(inicio).inDays + 1 : 0;
    final text = periodo == 'PERSONALIZADO'
        ? 'Rango personalizado — $dias días'
        : 'Periodo automático — $dias días';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 15, color: _C.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _C.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dropdowns ────────────────────────────────────────────────────────────────
InputDecoration _dropdownDecoration({
  required String label,
  required String hint,
  required IconData icon,
  required Color iconColor,
}) =>
    InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13, color: _C.textSub, fontWeight: FontWeight.w500),
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13, color: _C.textSub.withValues(alpha: 0.55)),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      filled: true,
      fillColor: _C.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _C.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: iconColor, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

TextStyle _dropdownItemStyle() => GoogleFonts.plusJakartaSans(
      fontSize: 14,
      color: _C.primary,
      fontWeight: FontWeight.w500,
    );

class _CategoriaDropdown extends StatelessWidget {
  final List categorias;
  final int? value;
  final void Function(int?) onChanged;
  const _CategoriaDropdown(
      {required this.categorias,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int?>(
        initialValue: value,
        isExpanded: true,
        style: _dropdownItemStyle(),
        decoration: _dropdownDecoration(
          label: 'Categoría',
          hint: 'Todas las categorías',
          icon: Icons.label_rounded,
          iconColor: const Color(0xFF8B5CF6),
        ),
        items: [
          DropdownMenuItem<int?>(
            value: null,
            child: Text('Todas las categorías',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: _C.textSub)),
          ),
          ...categorias.map(
            (c) => DropdownMenuItem<int?>(
              value: c.id as int,
              child: Text(c.nombre as String),
            ),
          ),
        ],
        onChanged: onChanged,
      );
}

class _CuentaDropdown extends StatelessWidget {
  final List cuentas;
  final int? value;
  final void Function(int?) onChanged;
  const _CuentaDropdown(
      {required this.cuentas, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int?>(
        initialValue: value,
        isExpanded: true,
        style: _dropdownItemStyle(),
        decoration: _dropdownDecoration(
          label: 'Cuenta',
          hint: 'Todas las cuentas',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFFF59E0B),
        ),
        items: [
          DropdownMenuItem<int?>(
            value: null,
            child: Text('Todas las cuentas',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: _C.textSub)),
          ),
          ...cuentas.map(
            (c) => DropdownMenuItem<int?>(
              value: c.id as int,
              child: Text(c.nombre as String),
            ),
          ),
        ],
        onChanged: onChanged,
      );
}

class _DropdownLoading extends StatelessWidget {
  const _DropdownLoading();

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        decoration: BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _C.accent),
          ),
        ),
      );
}

// ─── Submit button ────────────────────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isEdit;
  final double monto;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.isEdit,
    required this.monto,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _C.accent.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _C.accent.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 17),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? 'Guardar cambios' : 'Crear presupuesto',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (monto > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Límite: ${fmt.format(monto)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
