import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/presupuesto_models.dart';
import 'presupuestos_provider.dart';
import '../categories/categories_provider.dart';
import '../accounts/accounts_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(expenseCategoriesProvider);
    final cuentasAsync = ref.watch(accountsProvider);
    final formato = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.presupuesto != null ? 'Editar Presupuesto' : 'Nuevo Presupuesto',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con icono
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6),
                      const Color(0xFF2563EB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.presupuesto != null
                                ? 'Actualiza tu presupuesto'
                                : 'Crea un nuevo presupuesto',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Controla tus gastos y alcanza tus metas',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Información básica
              _sectionTitle('Información Básica', Icons.edit_note),
              const SizedBox(height: 12),

              _buildCard(
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nombreCtrl,
                      label: 'Nombre del presupuesto',
                      icon: Icons.label_outline,
                      hint: 'Ej: Supermercado, Entretenimiento',
                      validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildMontoField(formato),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Periodo y fechas
              _sectionTitle('Periodo', Icons.calendar_month_rounded),
              const SizedBox(height: 12),

              _buildCard(
                child: Column(
                  children: [
                    _buildPeriodoSelector(),
                    const SizedBox(height: 16),
                    _buildFechasRow(),
                    if (_inicio != null) ...[
                      const SizedBox(height: 12),
                      _buildRangoInfo(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Filtros opcionales
              _sectionTitle('Filtros (Opcional)', Icons.filter_list_rounded),
              const SizedBox(height: 12),

              _buildCard(
                child: Column(
                  children: [
                    categoriasAsync.when(
                      data: (categorias) => _buildCategoriaDropdown(categorias),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 16),
                    cuentasAsync.when(
                      data: (cuentas) => _buildCuentaDropdown(cuentas),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Notas
              _sectionTitle('Notas', Icons.note_alt_outlined),
              const SizedBox(height: 12),

              _buildCard(
                child: TextFormField(
                  controller: _notasCtrl,
                  decoration: InputDecoration(
                    hintText: 'Agrega notas o recordatorios...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.note_outlined, color: Colors.grey[400]),
                  ),
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              const SizedBox(height: 32),

              // Botón de guardar
              _buildSubmitButton(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildMontoField(NumberFormat formato) {
    return TextFormField(
      controller: _montoCtrl,
      decoration: InputDecoration(
        labelText: 'Monto límite',
        hintText: 'Ej: 500000',
        prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFF10B981)),
        suffixText: 'COP',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF10B981).withOpacity(0.05),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (v) {
        final d = double.tryParse(v ?? '');
        if (d == null || d <= 0) return 'Ingresa un monto válido';
        return null;
      },
      onChanged: (v) => setState(() {}),
    );
  }

  Widget _buildPeriodoSelector() {
    final periodos = [
      {'value': 'SEMANAL', 'label': 'Semanal', 'icon': Icons.calendar_view_week},
      {'value': 'MENSUAL', 'label': 'Mensual', 'icon': Icons.calendar_view_month},
      {'value': 'ANUAL', 'label': 'Anual', 'icon': Icons.calendar_today},
      {'value': 'PERSONALIZADO', 'label': 'Personalizado', 'icon': Icons.event_note},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona el periodo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: periodos.map((p) {
            final isSelected = _periodo == p['value'];
            return InkWell(
              onTap: () {
                setState(() {
                  _periodo = p['value'] as String;
                  _autocalcularFechas();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6),
                            const Color(0xFF2563EB),
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      p['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      p['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFechasRow() {
    return Row(
      children: [
        Expanded(child: _buildFechaButton(true)),
        const SizedBox(width: 12),
        Expanded(child: _buildFechaButton(false)),
      ],
    );
  }

  Widget _buildFechaButton(bool isInicio) {
    final fecha = isInicio ? _inicio : _fin;
    final label = isInicio ? 'Fecha Inicio' : 'Fecha Fin';
    final icon = isInicio ? Icons.play_circle_outline : Icons.stop_circle_outlined;
    final enabled = isInicio || _periodo == 'PERSONALIZADO';

    return InkWell(
      onTap: enabled
          ? () async {
              final d = await showDatePicker(
                context: context,
                initialDate: fecha ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF3B82F6),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (d != null) {
                setState(() {
                  if (isInicio) {
                    _inicio = d;
                    _autocalcularFechas(alCambiarInicio: true);
                  } else {
                    _fin = d;
                  }
                });
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? Colors.grey[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: enabled ? const Color(0xFF3B82F6) : Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              fecha == null ? 'Seleccionar' : _fmt(fecha),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: enabled ? const Color(0xFF1F2937) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangoInfo() {
    if (_inicio == null) return const SizedBox.shrink();

    final dias = _fin != null ? _fin!.difference(_inicio!).inDays + 1 : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF2563EB).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _periodo == 'PERSONALIZADO'
                  ? 'Rango: ${_fmt(_inicio)} - ${_fin == null ? '—' : _fmt(_fin)} ($dias días)'
                  : 'Periodo automático: ${_fmt(_inicio)} - ${_fmt(_fin)} ($dias días)',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaDropdown(List categorias) {
    return DropdownButtonFormField<int?>(
      initialValue: _categoriaId,
      decoration: InputDecoration(
        labelText: 'Categoría',
        hintText: 'Selecciona una categoría',
        prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF8B5CF6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Todas las categorías'),
        ),
        ...categorias.map(
          (c) => DropdownMenuItem<int?>(
            value: c.id,
            child: Text(c.nombre),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _categoriaId = v),
    );
  }

  Widget _buildCuentaDropdown(List cuentas) {
    return DropdownButtonFormField<int?>(
      initialValue: _cuentaId,
      decoration: InputDecoration(
        labelText: 'Cuenta',
        hintText: 'Selecciona una cuenta',
        prefixIcon: const Icon(Icons.account_balance_outlined, color: Color(0xFFF59E0B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Todas las cuentas'),
        ),
        ...cuentas.map(
          (c) => DropdownMenuItem<int?>(
            value: c.id,
            child: Text(c.nombre),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _cuentaId = v),
    );
  }

  Widget _buildSubmitButton() {
    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    final formato = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.presupuesto != null ? Icons.check_circle_outline : Icons.add_circle_outline,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.presupuesto != null ? 'Guardar Cambios' : 'Crear Presupuesto',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (monto > 0)
                        Text(
                          'Límite: ${formato.format(monto)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
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
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(widget.presupuesto != null
                    ? 'Presupuesto actualizado'
                    : 'Presupuesto creado exitosamente'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _autocalcularFechas({bool alCambiarInicio = false}) {
    final hoy = DateTime.now();
    final inicioBase = _inicio ?? DateTime(hoy.year, hoy.month, hoy.day);

    if (_periodo == 'SEMANAL') {
      final fin = inicioBase.add(const Duration(days: 6));
      _inicio = DateTime(inicioBase.year, inicioBase.month, inicioBase.day);
      _fin = DateTime(fin.year, fin.month, fin.day);
    } else if (_periodo == 'MENSUAL') {
      final first = DateTime(inicioBase.year, inicioBase.month, 1);
      final nextMonth = DateTime(inicioBase.year, inicioBase.month + 1, 1);
      final last = nextMonth.subtract(const Duration(days: 1));
      _inicio = first;
      _fin = last;
    } else if (_periodo == 'ANUAL') {
      _inicio = DateTime(inicioBase.year, 1, 1);
      _fin = DateTime(inicioBase.year, 12, 31);
    } else {
      // PERSONALIZADO
      if (alCambiarInicio && (_fin == null || _fin!.isBefore(_inicio!))) {
        _fin = _inicio;
      }
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
