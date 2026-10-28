import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/meta_models.dart';
import '../../core/theme/neo_bank_theme.dart';
import '../../features/accounts/accounts_provider.dart';
import 'metas_provider.dart';

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF5B5FEE);
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return const Color(0xFF5B5FEE);
  }
}

class AporteMetaDialog extends ConsumerStatefulWidget {
  final Meta meta;
  const AporteMetaDialog({super.key, required this.meta});

  @override
  ConsumerState<AporteMetaDialog> createState() => _AporteMetaDialogState();
}

class _AporteMetaDialogState extends ConsumerState<AporteMetaDialog>
    with SingleTickerProviderStateMixin {
  final _formKey         = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _notasController = TextEditingController();
  int? _selectedCuentaId;
  bool _isSubmitting = false;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutBack,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _notasController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t              = context.tokens;
    final cuentasAsync   = ref.watch(accountsNotifierProvider);
    final fmt            = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final metaColor      = _parseColor(widget.meta.color);
    final faltante       = widget.meta.faltante;
    final maxHeight      = MediaQuery.of(context).size.height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          constraints: BoxConstraints(maxWidth: 500, maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogHeader(meta: widget.meta, metaColor: metaColor),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProgressInfoCard(
                          meta: widget.meta,
                          metaColor: metaColor,
                          fmt: fmt,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Monto del aporte',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _montoController,
                          decoration: InputDecoration(
                            labelText: 'Monto',
                            hintText: '0',
                            prefixIcon: Icon(
                              Icons.attach_money_rounded,
                              color: metaColor,
                              size: 20,
                            ),
                            suffix: Text(
                              'COP',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: t.textSecondary,
                              ),
                            ),
                            filled: true,
                            fillColor: t.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: t.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: t.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: t.accent, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEF4444)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFEF4444),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El monto es requerido';
                            }
                            final m = double.tryParse(v);
                            if (m == null || m <= 0) return 'Ingresa un monto válido';
                            if (m > faltante) return 'El aporte excede lo faltante';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aporte rápido',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: t.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _QuickChip(
                              label: '25%',
                              porcentaje: 0.25,
                              metaColor: metaColor,
                              faltante: faltante,
                              fmt: fmt,
                              controller: _montoController,
                              onTap: () => setState(() {}),
                            ),
                            const SizedBox(width: 8),
                            _QuickChip(
                              label: '50%',
                              porcentaje: 0.50,
                              metaColor: metaColor,
                              faltante: faltante,
                              fmt: fmt,
                              controller: _montoController,
                              onTap: () => setState(() {}),
                            ),
                            const SizedBox(width: 8),
                            _QuickChip(
                              label: '75%',
                              porcentaje: 0.75,
                              metaColor: metaColor,
                              faltante: faltante,
                              fmt: fmt,
                              controller: _montoController,
                              onTap: () => setState(() {}),
                            ),
                            const SizedBox(width: 8),
                            _QuickChip(
                              label: 'Todo',
                              porcentaje: 1.0,
                              metaColor: metaColor,
                              faltante: faltante,
                              fmt: fmt,
                              controller: _montoController,
                              onTap: () => setState(() {}),
                            ),
                          ],
                        ),
                        _AportePreview(
                          controller: _montoController,
                          meta: widget.meta,
                          metaColor: metaColor,
                          fmt: fmt,
                        ),
                        const SizedBox(height: 20),
                        cuentasAsync.when(
                          data: (cuentas) {
                            if (cuentas.isEmpty) return const SizedBox.shrink();
                            return DropdownButtonFormField<int>(
                              initialValue: _selectedCuentaId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Cuenta (opcional)',
                                hintText: 'Selecciona una cuenta',
                                prefixIcon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: metaColor,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: t.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.accent, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text(
                                    'Sin cuenta específica',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ...cuentas.map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c.id,
                                    child: Text(
                                      c.nombre,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedCuentaId = v),
                            );
                          },
                          loading: () => _buildCuentasLoading(t),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        if (cuentasAsync.hasValue &&
                            cuentasAsync.value!.isNotEmpty)
                          const SizedBox(height: 16),
                        TextFormField(
                          controller: _notasController,
                          decoration: InputDecoration(
                            labelText: 'Notas (opcional)',
                            hintText: 'Ej: Aporte mensual de enero...',
                            prefixIcon: const Icon(
                              Icons.note_outlined,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: t.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: t.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: t.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: t.accent, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _DialogFooter(
                  isSubmitting: _isSubmitting,
                  onCancel: () => Navigator.of(context).pop(),
                  onSubmit: _isSubmitting ? null : _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCuentasLoading(AppTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: t.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: t.accent,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Cargando cuentas...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: t.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final request = AporteMetaRequest(
        metaId:      widget.meta.id,
        cuentaId:    _selectedCuentaId,
        montoAporte: double.parse(_montoController.text),
        notas:       _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
      );
      await ref.read(metasNotifierProvider.notifier).hacerAporte(request);
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Aporte realizado'),
            ]),
            backgroundColor: context.tokens.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            backgroundColor: context.tokens.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ── Dialog header ──────────────────────────────────────────────────────────────
class _DialogHeader extends StatelessWidget {
  final Meta meta;
  final Color metaColor;

  const _DialogHeader({required this.meta, required this.metaColor});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: metaColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.trending_up_rounded, color: metaColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hacer Aporte',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  meta.nombre,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: t.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: t.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: t.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress info card ─────────────────────────────────────────────────────────
class _ProgressInfoCard extends StatelessWidget {
  final Meta meta;
  final Color metaColor;
  final NumberFormat fmt;

  const _ProgressInfoCard({
    required this.meta,
    required this.metaColor,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCol(
                label: 'Faltante',
                value: fmt.format(meta.faltante),
                color: metaColor,
              ),
              _StatCol(
                label: 'Progreso',
                value: '${meta.porcentajeCompletado.toStringAsFixed(1)}%',
                color: metaColor,
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: meta.porcentajeCompletado / 100,
              minHeight: 6,
              backgroundColor: t.border,
              valueColor: AlwaysStoppedAnimation<Color>(metaColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  const _StatCol({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: t.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Live aporte preview ────────────────────────────────────────────────────────
class _AportePreview extends StatelessWidget {
  final TextEditingController controller;
  final Meta meta;
  final Color metaColor;
  final NumberFormat fmt;

  const _AportePreview({
    required this.controller,
    required this.meta,
    required this.metaColor,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final aporte = double.tryParse(controller.text) ?? 0.0;
    if (aporte <= 0) return const SizedBox.shrink();

    final nuevoActual   = meta.montoActual + aporte;
    final nuevoPct      = meta.montoObjetivo > 0
        ? (nuevoActual / meta.montoObjetivo * 100).clamp(0.0, 100.0)
        : 0.0;
    final nuevoFaltante = (meta.montoObjetivo - nuevoActual)
        .clamp(0.0, double.infinity);
    final completada    = nuevoActual >= meta.montoObjetivo;

    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: metaColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: t.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Vista previa',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuevo progreso',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: t.textSecondary,
                        ),
                      ),
                      Text(
                        '${nuevoPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: completada ? t.success : metaColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Nuevo faltante',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: t.textSecondary,
                        ),
                      ),
                      Text(
                        fmt.format(nuevoFaltante),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: completada ? t.success : t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: nuevoPct / 100,
                  minHeight: 6,
                  backgroundColor: t.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completada ? t.success : metaColor,
                  ),
                ),
              ),
              if (completada) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: t.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration_rounded,
                          size: 14,
                          color: Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Meta completada!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Quick chip ─────────────────────────────────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final String label;
  final double porcentaje;
  final Color metaColor;
  final double faltante;
  final NumberFormat fmt;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.porcentaje,
    required this.metaColor,
    required this.faltante,
    required this.fmt,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final monto      = faltante * porcentaje;
    final isSelected = controller.text.isNotEmpty &&
        (double.tryParse(controller.text) ?? 0.0) == monto;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.text = monto.toStringAsFixed(0);
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? metaColor.withValues(alpha: 0.1)
                  : t.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? metaColor : t.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? metaColor : t.textSecondary,
                  ),
                ),
                Text(
                  fmt.format(monto),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: isSelected ? metaColor : t.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dialog footer ──────────────────────────────────────────────────────────────
class _DialogFooter extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;

  const _DialogFooter({
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: t.border),
                ),
                backgroundColor: t.surface,
                foregroundColor: t.textSecondary,
              ),
              child: Text(
                'Cancelar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: isSubmitting
                    ? t.accent.withValues(alpha: 0.6)
                    : t.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hacer Aporte',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
