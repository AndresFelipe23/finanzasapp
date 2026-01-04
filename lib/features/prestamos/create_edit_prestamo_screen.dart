import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/prestamo_models.dart';
import '../../core/models/cuenta_models.dart';
import 'prestamos_provider.dart';
import '../accounts/accounts_provider.dart';

class CreateEditPrestamoScreen extends ConsumerStatefulWidget {
  final Prestamo? prestamo;
  const CreateEditPrestamoScreen({super.key, this.prestamo});

  @override
  ConsumerState<CreateEditPrestamoScreen> createState() =>
      _CreateEditPrestamoScreenState();
}

class _CreateEditPrestamoScreenState
    extends ConsumerState<CreateEditPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _montoController = TextEditingController();
  final _tasaController = TextEditingController();
  final _notasController = TextEditingController();
  String _tipo = 'DEUDA';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  Cuenta? _selectedCuenta;

  @override
  void initState() {
    super.initState();
    if (widget.prestamo != null) {
      final p = widget.prestamo!;
      _nombreController.text = p.nombre;
      _montoController.text = p.montoTotal.toStringAsFixed(0);
      if (p.tasaInteres != null) {
        _tasaController.text = p.tasaInteres!.toStringAsFixed(2);
      }
      _notasController.text = p.notas ?? '';
      _tipo = p.tipo;
      _fechaInicio = p.fechaInicio;
      _fechaFin = p.fechaFin;
      // La cuenta se cargará desde el provider si existe
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _tasaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.prestamo != null;
    final tipoColor = _tipo == 'DEUDA'
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final accountsAsync = ref.watch(accountsNotifierProvider);
    
    // Si estamos editando y no hay cuenta seleccionada, intentar cargarla
    if (isEdit && widget.prestamo?.cuentaId != null && _selectedCuenta == null) {
      accountsAsync.whenData((cuentas) {
        try {
          final cuenta = cuentas.firstWhere(
            (c) => c.id == widget.prestamo?.cuentaId,
          );
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedCuenta = cuenta;
              });
            });
          }
        } catch (e) {
          // Cuenta no encontrada, dejar _selectedCuenta como null
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Color(0xFF1F2937),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? 'Editar Préstamo' : 'Nuevo Préstamo',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vista previa
              _buildPreviewCard(tipoColor),

              const SizedBox(height: 24),

              // Tipo de préstamo
              const Text(
                'Tipo de préstamo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildTipoChip(
                      'DEUDA',
                      'Yo debo',
                      Icons.arrow_downward_rounded,
                      const Color(0xFFEF4444),
                    ),
                    _buildTipoChip(
                      'PRESTAMO',
                      'Yo presto',
                      Icons.arrow_upward_rounded,
                      const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Información del préstamo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del préstamo *',
                  hintText: 'Ej: Préstamo a Juan',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: tipoColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: tipoColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => setState(() {}),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'El nombre es requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoController,
                decoration: InputDecoration(
                  labelText: 'Monto total *',
                  hintText: '0',
                  prefixIcon: Icon(Icons.attach_money_rounded, color: tipoColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: tipoColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixText: 'COP',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) => setState(() {}),
                validator: (v) {
                  final d = double.tryParse(v ?? '');
                  if (d == null || d <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Cuenta asociada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              accountsAsync.when(
                data: (cuentas) {
                  if (cuentas.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Text(
                        'No hay cuentas disponibles. Crea una cuenta primero.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    );
                  }
                  final cuentasUnicas = cuentas.toSet().toList();
                  return DropdownButtonFormField<Cuenta>(
                    initialValue: _selectedCuenta,
                    decoration: InputDecoration(
                      labelText: 'Cuenta (opcional)',
                      prefixIcon: Icon(Icons.account_balance_wallet, color: tipoColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: tipoColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text('Selecciona una cuenta'),
                    items: cuentasUnicas.map((cuenta) {
                      return DropdownMenuItem<Cuenta>(
                        value: cuenta,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIcon(cuenta.icono),
                              color: _parseColor(cuenta.color),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              cuenta.nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (cuenta) {
                      setState(() {
                        _selectedCuenta = cuenta;
                      });
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    'Error al cargar cuentas',
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tasaController,
                decoration: InputDecoration(
                  labelText: 'Tasa de interés anual (opcional)',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.percent_rounded, color: Color(0xFF6B7280)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: tipoColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Fechas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDateButton(
                      'Fecha de inicio',
                      _fechaInicio,
                      Icons.calendar_today_rounded,
                      () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _fechaInicio ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _fechaInicio = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateButton(
                      'Fecha de fin',
                      _fechaFin,
                      Icons.event_rounded,
                      () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _fechaFin ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _fechaFin = d);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Notas adicionales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notasController,
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Agrega información adicional...',
                  prefixIcon: const Icon(Icons.note_outlined, color: Color(0xFF6B7280)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: tipoColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 2,
                        ),
                        foregroundColor: const Color(0xFF6B7280),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [tipoColor.withOpacity(0.8), tipoColor],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: tipoColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isEdit ? 'Guardar Cambios' : 'Crear Préstamo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(Color color) {
    final nombre = _nombreController.text.isEmpty
        ? 'Vista previa'
        : _nombreController.text;
    final monto = _montoController.text.isEmpty
        ? '0'
        : _montoController.text;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Vista Previa',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _tipo == 'DEUDA'
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '\$$monto COP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _tipo == 'DEUDA' ? 'Yo debo' : 'Yo presto',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoChip(String value, String label, IconData icon, Color color) {
    final isSelected = _tipo == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tipo = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(
    String label,
    DateTime? date,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date == null
                  ? 'Sin definir'
                  : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: date == null ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final req = CreatePrestamoRequest(
      nombre: _nombreController.text.trim(),
      tipo: _tipo,
      montoTotal: double.parse(_montoController.text),
      tasaInteres: _tasaController.text.trim().isEmpty
          ? null
          : double.parse(_tasaController.text),
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      cuentaId: _selectedCuenta?.id,
      notas: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
    );
    try {
      if (widget.prestamo == null) {
        await ref.read(prestamosNotifierProvider.notifier).create(req);
      } else {
        await ref
            .read(prestamosNotifierProvider.notifier)
            .update(widget.prestamo!.id, req);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return const Color(0xFF059669);
    }
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF059669);
    }
  }

  IconData _getIcon(String? icono) {
    if (icono == null) return Icons.account_balance;
    switch (icono) {
      case 'account_balance':
        return Icons.account_balance;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'wallet':
        return Icons.wallet;
      case 'payments':
        return Icons.payments;
      case 'trending_up':
        return Icons.trending_up;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.account_balance;
    }
  }
}
