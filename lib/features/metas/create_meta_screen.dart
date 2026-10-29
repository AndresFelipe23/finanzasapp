import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/meta_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import 'metas_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// Crear o editar una meta de ahorro.
class CreateMetaScreen extends ConsumerStatefulWidget {
  final Meta? metaToEdit;
  const CreateMetaScreen({super.key, this.metaToEdit});

  @override
  ConsumerState<CreateMetaScreen> createState() => _CreateMetaScreenState();
}

class _CreateMetaScreenState extends ConsumerState<CreateMetaScreen> {
  late final _meta = widget.metaToEdit;
  late final _nombreCtrl = TextEditingController(text: _meta?.nombre ?? '');
  late final _descCtrl = TextEditingController(text: _meta?.descripcion ?? '');
  late final _montoCtrl = TextEditingController(
    text: _meta == null ? '' : _meta.montoObjetivo.toStringAsFixed(0),
  );
  late DateTime _fecha = _meta?.fechaObjetivo ??
      DateTime(DateTime.now().year + 1, DateTime.now().month, DateTime.now().day);
  bool _saving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  /// Cuánto habría que ahorrar al mes para llegar a la fecha.
  double? _mensual() {
    final objetivo = parseAmount(_montoCtrl.text);
    if (objetivo == null || objetivo <= 0) return null;
    final faltante = objetivo - (_meta?.montoActual ?? 0);
    if (faltante <= 0) return 0;
    final now = DateTime.now();
    final meses = (_fecha.year - now.year) * 12 + _fecha.month - now.month;
    return faltante / (meses < 1 ? 1 : meses);
  }

  Future<void> _save() async {
    final nombre = _nombreCtrl.text.trim();
    final monto = parseAmount(_montoCtrl.text);
    if (nombre.isEmpty) {
      showBrandSnack(context, 'Ponle un nombre a tu meta');
      return;
    }
    if (monto == null || monto <= 0) {
      showBrandSnack(context, 'Escribe cuánto quieres ahorrar');
      return;
    }
    final desc = _descCtrl.text.trim();

    setState(() => _saving = true);
    final request = CreateMetaRequest(
      nombre: nombre,
      descripcion: desc.isEmpty ? null : desc,
      montoObjetivo: monto,
      fechaObjetivo: _fecha,
      // El color se asigna en la lista; se conservan los que ya tenía
      color: _meta?.color,
      icono: _meta?.icono,
    );
    try {
      final notifier = ref.read(metasNotifierProvider.notifier);
      if (_meta != null) {
        await notifier.updateMeta(_meta.id, request);
      } else {
        await notifier.create(request);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showBrandSnack(
        context,
        _meta != null ? 'Meta actualizada' : 'Meta creada',
        error: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandFormPage(
      title: _meta != null ? 'Editar meta' : 'Nueva meta',
      submitLabel: _meta != null ? 'Guardar cambios' : 'Crear meta',
      loading: _saving,
      onSubmit: _save,
      children: [
        BrandField(
          label: '¿Para qué ahorras?',
          hint: 'Ej: Fondo de emergencia',
          controller: _nombreCtrl,
        ),
        const SizedBox(height: 24),
        BrandAmountInput(
          controller: _montoCtrl,
          label: 'Meta',
          color: Brand.accent,
          decimals: true,
        ),
        if (_meta != null && _meta.montoActual > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Ya llevas ${_money.format(_meta.montoActual)} ahorrados',
            textAlign: TextAlign.center,
            style: Brand.text(size: 12, color: Brand.muted),
          ),
        ],
        const SizedBox(height: 24),
        BrandGroup(
          children: [
            BrandGroupRow(
              label: 'Fecha objetivo',
              value: brandDateLabel(_fecha),
              onTap: () async {
                final d = await pickBrandDate(
                  context,
                  initial: _fecha,
                  first: DateTime.now(),
                );
                if (d != null) setState(() => _fecha = d);
              },
            ),
          ],
        ),
        // Se recalcula al escribir el monto
        ListenableBuilder(
          listenable: _montoCtrl,
          builder: (_, __) {
            final m = _mensual();
            if (m == null) return const SizedBox(height: 0);
            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Brand.accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Brand.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m == 0
                          ? '¡Ya alcanzaste este monto!'
                          : 'Para llegar a tiempo necesitas ahorrar '
                                '${_money.format(m)} al mes.',
                      style: Brand.text(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Brand.accentDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const BrandLabel('Descripción (opcional)'),
        BrandTextArea(controller: _descCtrl, hint: '¿Por qué es importante?'),
      ],
    );
  }
}
