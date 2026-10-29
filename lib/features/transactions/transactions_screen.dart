import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/theme/brand.dart';
import '../accounts/accounts_provider.dart';
import 'transaction_list.dart';
import 'transactions_provider.dart';

enum _Tipo { todos, ingresos, gastos }

enum _Periodo { todo, esteMes, mesPasado, tresMeses }

const _periodoLabels = {
  _Periodo.todo: 'Todo',
  _Periodo.esteMes: 'Este mes',
  _Periodo.mesPasado: 'Mes pasado',
  _Periodo.tresMeses: 'Últimos 3 meses',
};

// ─── Movimientos ──────────────────────────────────────────────────────────────
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  _Tipo _tipo = _Tipo.todos;
  _Periodo _periodo = _Periodo.todo;
  int? _cuentaId;

  bool get _hasFilters => _periodo != _Periodo.todo || _cuentaId != null;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _inPeriod(DateTime d) {
    final now = DateTime.now();
    return switch (_periodo) {
      _Periodo.todo => true,
      _Periodo.esteMes => d.year == now.year && d.month == now.month,
      _Periodo.mesPasado => () {
        final m = DateTime(now.year, now.month - 1);
        return d.year == m.year && d.month == m.month;
      }(),
      _Periodo.tresMeses => !d.isBefore(DateTime(now.year, now.month - 2)),
    };
  }

  List<Transaccion> _apply(List<Transaccion> all) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return all.where((t) {
      if (_tipo == _Tipo.ingresos && t.tipoNombre != 'INGRESO') return false;
      if (_tipo == _Tipo.gastos && t.tipoNombre != 'GASTO') return false;
      if (_cuentaId != null && t.cuentaId != _cuentaId) return false;
      if (!_inPeriod(t.fechaTransaccion)) return false;
      if (q.isEmpty) return true;
      return [t.titulo, t.descripcion, t.categoriaNombre, t.cuentaNombre]
          .any((s) => s != null && s.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) => b.fechaTransaccion.compareTo(a.fechaTransaccion));
  }

  @override
  Widget build(BuildContext context) {
    final transAsync = ref.watch(transactionsNotifierProvider);

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Movimientos', style: Brand.title(size: 26)),
                      ),
                      _FilterButton(
                        active: _hasFilters,
                        onTap: _openFilters,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SearchField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _Segmented(
                    value: _tipo,
                    onChanged: (v) => setState(() => _tipo = v),
                  ),
                  if (_hasFilters) ...[
                    const SizedBox(height: 12),
                    _ActiveFilters(
                      periodo: _periodo,
                      cuenta: _cuentaNombre(),
                      onClear: () => setState(() {
                        _periodo = _Periodo.todo;
                        _cuentaId = null;
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: Brand.accent,
                onRefresh: () =>
                    ref.read(transactionsNotifierProvider.notifier).refresh(),
                child: transAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Brand.accent,
                    ),
                  ),
                  error: (e, _) => _Message(
                    icon: Icons.wifi_off_rounded,
                    title: 'No se pudieron cargar tus movimientos',
                    body: 'Revisa tu conexión y desliza hacia abajo para '
                        'reintentar.',
                  ),
                  data: (all) {
                    if (all.isEmpty) {
                      return const _Message(
                        icon: Icons.receipt_long_outlined,
                        title: 'Aún no tienes movimientos',
                        body: 'Toca el botón + para registrar tu primer '
                            'ingreso o gasto.',
                      );
                    }
                    final groups = groupTransactionsByDay(_apply(all));
                    if (groups.isEmpty) {
                      return const _Message(
                        icon: Icons.search_off_rounded,
                        title: 'Sin resultados',
                        body: 'Prueba con otra búsqueda o quita los filtros.',
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => TransactionDayGroup(
                        day: groups[i].key,
                        items: groups[i].value,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _cuentaNombre() {
    if (_cuentaId == null) return null;
    final cuentas = ref.read(accountsNotifierProvider).valueOrNull ?? const [];
    for (final c in cuentas) {
      if (c.id == _cuentaId) return c.nombre;
    }
    return null;
  }

  Future<void> _openFilters() async {
    final cuentas = ref.read(accountsNotifierProvider).valueOrNull ?? const [];
    final result = await showModalBottomSheet<(_Periodo, int?)>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Brand.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FiltersSheet(
        periodo: _periodo,
        cuentaId: _cuentaId,
        cuentas: cuentas.where((c) => c.activa).toList(),
      ),
    );
    if (result != null) {
      setState(() {
        _periodo = result.$1;
        _cuentaId = result.$2;
      });
    }
  }
}

// ─── Controles de la parte superior ───────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Brand.ink : Brand.surface,
      shape: CircleBorder(
        side: BorderSide(color: active ? Brand.ink : Brand.border),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.tune_rounded,
            size: 20,
            color: active ? Colors.white : Brand.ink,
            semanticLabel: 'Filtrar',
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Brand.border),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Brand.text(size: 14),
      cursorColor: Brand.accent,
      decoration: InputDecoration(
        hintText: 'Buscar por concepto o categoría',
        hintStyle: Brand.text(size: 14, color: Brand.placeholder),
        prefixIcon: const Icon(Icons.search_rounded, color: Brand.muted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar búsqueda',
                icon: const Icon(Icons.close_rounded, color: Brand.muted),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: Brand.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Brand.accent, width: 1.5),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.onChanged});

  final _Tipo value;
  final ValueChanged<_Tipo> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(_Tipo v, String label) {
      final on = v == value;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 40,
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
                  size: 13,
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
          seg(_Tipo.todos, 'Todos'),
          const SizedBox(width: 4),
          seg(_Tipo.ingresos, 'Ingresos'),
          const SizedBox(width: 4),
          seg(_Tipo.gastos, 'Gastos'),
        ],
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.periodo,
    required this.cuenta,
    required this.onClear,
  });

  final _Periodo periodo;
  final String? cuenta;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (periodo != _Periodo.todo) _periodoLabels[periodo]!,
      ?cuenta,
    ];
    return Row(
      children: [
        const Icon(Icons.filter_alt_outlined, size: 16, color: Brand.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Brand.text(size: 13, weight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: onClear,
          style: TextButton.styleFrom(minimumSize: const Size(44, 36)),
          child: Text(
            'Quitar filtros',
            style: Brand.text(
              size: 13,
              weight: FontWeight.w700,
              color: Brand.accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    // ListView para que el gesto de recargar funcione también aquí
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      children: [
        Icon(icon, size: 44, color: Brand.inputBorder),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Brand.text(size: 16, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Brand.text(size: 13, color: Brand.muted, height: 1.45),
        ),
      ],
    );
  }
}

// ─── Hoja de filtros ──────────────────────────────────────────────────────────
class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.periodo,
    required this.cuentaId,
    required this.cuentas,
  });

  final _Periodo periodo;
  final int? cuentaId;
  final List<Cuenta> cuentas;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late _Periodo _periodo = widget.periodo;
  late int? _cuentaId = widget.cuentaId;

  Widget _chip(String label, bool on, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: Brand.ink,
      backgroundColor: Brand.surface,
      side: BorderSide(color: on ? Brand.ink : Brand.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: Brand.text(
        size: 13,
        weight: FontWeight.w700,
        color: on ? Colors.white : Brand.ink,
      ),
    );
  }

  Text _title(String s) => Text(
    s.toUpperCase(),
    style: Brand.text(
      size: 11,
      weight: FontWeight.w700,
      color: Brand.muted,
      letterSpacing: 1.1,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 20),
            Text('Filtrar', style: Brand.text(size: 20, weight: FontWeight.w800)),
            const SizedBox(height: 18),
            _title('Periodo'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _Periodo.values)
                  _chip(
                    _periodoLabels[p]!,
                    _periodo == p,
                    () => setState(() => _periodo = p),
                  ),
              ],
            ),
            if (widget.cuentas.isNotEmpty) ...[
              const SizedBox(height: 20),
              _title('Cuenta'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Todas', _cuentaId == null,
                      () => setState(() => _cuentaId = null)),
                  for (final c in widget.cuentas)
                    _chip(c.nombre, _cuentaId == c.id,
                        () => setState(() => _cuentaId = c.id)),
                ],
              ),
            ],
            const SizedBox(height: 28),
            BrandButton(
              label: 'Aplicar',
              onPressed: () => Navigator.pop(context, (_periodo, _cuentaId)),
            ),
          ],
        ),
      ),
    );
  }
}
