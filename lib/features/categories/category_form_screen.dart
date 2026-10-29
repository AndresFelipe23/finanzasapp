import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category_models.dart';
import '../../core/models/presupuesto_models.dart';
import '../../core/theme/brand.dart';
import '../presupuestos/presupuestos_provider.dart';
import 'categories_provider.dart';
import 'category_style.dart';

/// Crear o editar una categoría propia.
class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.categoria, this.tipoInicial = 'GASTO'});

  /// Null para crear una nueva.
  final Categoria? categoria;
  final String tipoInicial;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  late final _editing = widget.categoria != null;
  late final _nameCtrl = TextEditingController(text: widget.categoria?.nombre ?? '');
  final _budgetCtrl = TextEditingController();

  late String _tipo = widget.categoria?.tipo ?? widget.tipoInicial;
  late String _icono = categoryIcons.containsKey(widget.categoria?.icono)
      ? widget.categoria!.icono!
      : 'shopping_cart';
  late Color _color = _initialColor();
  bool _withBudget = false;
  bool _saving = false;

  Color _initialColor() {
    final c = widget.categoria;
    if (c == null) return categoryPalette.first.$2;
    return categoryColors(c.color, c.tipo).$1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  (Color, Color) get _colors => categoryColors(colorToHex(_color), _tipo);

  Future<void> _save() async {
    final nombre = _nameCtrl.text.trim();
    if (nombre.isEmpty) {
      showBrandSnack(context, 'Ponle un nombre a la categoría');
      return;
    }
    final budget = double.tryParse(_budgetCtrl.text) ?? 0;
    if (_withBudget && budget <= 0) {
      showBrandSnack(context, 'Escribe el monto del presupuesto mensual');
      return;
    }

    setState(() => _saving = true);
    try {
      if (_editing) {
        await ref.read(categoriesNotifierProvider.notifier).updateCategory(
          widget.categoria!.id,
          UpdateCategoriaRequest(
            nombre: nombre,
            icono: _icono,
            color: colorToHex(_color),
            tipo: _tipo,
          ),
        );
      } else {
        // El servicio devuelve la categoría creada: hace falta su id para
        // asociarle el presupuesto
        final nueva = await ref.read(categoriesServiceProvider).createCategory(
          CreateCategoriaRequest(
            nombre: nombre,
            icono: _icono,
            color: colorToHex(_color),
            tipo: _tipo,
          ),
        );
        await ref.read(categoriesNotifierProvider.notifier).refresh();
        if (_withBudget) {
          final now = DateTime.now();
          await ref.read(presupuestosNotifierProvider.notifier).create(
            CreatePresupuestoRequest(
              nombre: nombre,
              periodo: 'MENSUAL',
              montoLimite: budget,
              categoriaId: nueva.id,
              fechaInicio: DateTime(now.year, now.month, 1),
              fechaFin: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
            ),
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete() async {
    final c = widget.categoria!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Eliminar "${c.nombre}"?',
            style: Brand.text(size: 18, weight: FontWeight.w800)),
        content: Text(
          'Los movimientos que la usan se quedarán sin categoría. Esta acción '
          'no se puede deshacer.',
          style: Brand.text(size: 14, color: Brand.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: Brand.text(weight: FontWeight.w700, color: Brand.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Brand.expense),
            child: Text('Eliminar',
                style: Brand.text(weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(categoriesNotifierProvider.notifier).deleteCategory(c.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors;
    final nombre = _nameCtrl.text.trim();
    final canBudget = !_editing && _tipo != 'INGRESO';

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Row(
                    children: [
                      Material(
                        color: Brand.surface,
                        shape: const CircleBorder(
                          side: BorderSide(color: Brand.border),
                        ),
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
                          _editing ? 'Editar categoría' : 'Nueva categoría',
                          style: Brand.text(size: 20, weight: FontWeight.w800),
                        ),
                      ),
                      if (_editing)
                        IconButton(
                          onPressed: _saving ? null : _delete,
                          tooltip: 'Eliminar categoría',
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Brand.expense),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Vista previa
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Brand.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Brand.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(categoryIcon(_icono), size: 26, color: fg),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vista previa',
                                  style: Brand.text(size: 12, color: Brand.muted)),
                              const SizedBox(height: 2),
                              Text(
                                nombre.isEmpty ? 'Tu categoría' : nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Brand.text(
                                  size: 17,
                                  weight: FontWeight.w800,
                                  color: nombre.isEmpty ? Brand.muted : Brand.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  _TypeSelector(
                    value: _tipo,
                    onChanged: (v) => setState(() => _tipo = v),
                  ),
                  const SizedBox(height: 18),

                  BrandField(
                    label: 'Nombre',
                    hint: 'Ej: Mascotas',
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 18),

                  _Label('Color'),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (final (name, c, _) in categoryPalette)
                        _ColorDot(
                          color: c,
                          name: name,
                          selected: c.toARGB32() == _color.toARGB32(),
                          onTap: () => setState(() => _color = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _Label('Ícono'),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (final e in categoryIcons.entries)
                        _IconTile(
                          icon: e.value.$1,
                          name: e.value.$2,
                          selected: e.key == _icono,
                          fg: fg,
                          bg: bg,
                          onTap: () => setState(() => _icono = e.key),
                        ),
                    ],
                  ),

                  if (canBudget) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: Brand.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Brand.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Presupuesto mensual',
                                        style: Brand.text(
                                            size: 14, weight: FontWeight.w700)),
                                    Text(
                                      'Opcional · te avisamos antes de pasarte',
                                      style: Brand.text(size: 12, color: Brand.muted),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _withBudget,
                                activeTrackColor: Brand.accent,
                                onChanged: (v) => setState(() => _withBudget = v),
                              ),
                            ],
                          ),
                          if (_withBudget)
                            Padding(
                              padding: const EdgeInsets.only(right: 8, bottom: 10, top: 4),
                              child: TextField(
                                controller: _budgetCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: Brand.text(weight: FontWeight.w700),
                                decoration: InputDecoration(
                                  prefixText: '\$ ',
                                  hintText: 'Monto al mes',
                                  hintStyle: Brand.text(color: Brand.placeholder),
                                  filled: true,
                                  fillColor: Brand.bg,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: BrandButton(
                  label: _editing ? 'Guardar cambios' : 'Guardar categoría',
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Brand.text(size: 13, weight: FontWeight.w700));
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String v, String label) {
      final on = v == value;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? Brand.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: on
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
                style: Brand.text(
                  size: 14,
                  weight: on ? FontWeight.w700 : FontWeight.w600,
                  color: on ? Brand.ink : Brand.muted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Brand.track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          seg('GASTO', 'Gasto'),
          const SizedBox(width: 4),
          seg('INGRESO', 'Ingreso'),
          const SizedBox(width: 4),
          seg('AMBOS', 'Ambos'),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : color,
              width: 3,
            ),
            boxShadow: selected
                ? [BoxShadow(color: color, spreadRadius: 2)]
                : null,
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.name,
    required this.selected,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String name;
  final bool selected;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name,
      selected: selected,
      button: true,
      child: Material(
        color: selected ? bg : Brand.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? fg : Brand.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Icon(icon, size: 20, color: selected ? fg : Brand.ink),
        ),
      ),
    );
  }
}
