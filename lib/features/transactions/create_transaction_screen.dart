import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/category_models.dart';
import '../../core/api/api_client.dart';
import 'transactions_provider.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';
import '../recurring/recurring_service.dart';

class CreateTransactionScreen extends ConsumerStatefulWidget {
  final String tipoTransaccion; // 'INGRESO', 'GASTO'

  const CreateTransactionScreen({super.key, required this.tipoTransaccion});

  @override
  ConsumerState<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState
    extends ConsumerState<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _tituloController = TextEditingController();
  final _notasController = TextEditingController();
  int? _selectedMetodoPagoId;

  Cuenta? _selectedCuenta;
  Categoria? _selectedCategoria;
  int? _tipoTransaccionId;
  DateTime _selectedDate = DateTime.now();
  bool _repetir = false;
  // Recurrencia
  String _frecuencia = 'MENSUAL';
  int? _diaVencimiento; // 1..31 para mensual+
  int? _diaSemana; // 1..7 (1=Lunes)
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    // Obtener IDs de tipos de transacción (asumiendo que existen en la BD)
    _tipoTransaccionId = widget.tipoTransaccion == 'INGRESO' ? 1 : 2;
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    _tituloController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    final isIngreso = widget.tipoTransaccion == 'INGRESO';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isIngreso ? 'Nuevo Ingreso' : 'Nuevo Gasto',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner de tipo mejorado
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isIngreso
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isIngreso
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isIngreso ? 'Registrar Ingreso' : 'Registrar Gasto',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            isIngreso
                                ? 'Dinero que recibes'
                                : 'Dinero que gastas',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Título
              _buildSectionTitle('Título'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ej: Arriendo, Mercado, Nómina',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: const Icon(Icons.title, color: Color(0xFF10B981)),
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                ),
                maxLength: 150,
              ),

              const SizedBox(height: 16),

              // Monto
              _buildSectionTitle('Monto'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoController,
                onChanged: (value) {
                  setState(() {}); // Actualizar para mostrar saldo resultante
                },
                decoration: InputDecoration(
                  labelText: 'Monto',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: const Icon(
                    Icons.attach_money,
                    color: Color(0xFF10B981),
                  ),
                  suffix: const Text(
                    'COP',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El monto es requerido';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null) {
                    return 'Ingresa un número válido';
                  }
                  if (monto <= 0) {
                    return 'El monto debe ser mayor que cero';
                  }
                  // Validar saldo suficiente si es un gasto
                  if (!isIngreso && _selectedCuenta != null) {
                    final saldoActual = _selectedCuenta!.saldoActual ?? _selectedCuenta!.saldoInicial;
                    if (monto > saldoActual) {
                      return 'El monto excede el saldo disponible (${_selectedCuenta!.moneda} ${saldoActual.toStringAsFixed(2)})';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Método de Pago (opcional)
              _buildSectionTitle('Método de Pago (opcional)'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _selectedMetodoPagoId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: const Icon(
                    Icons.payments,
                    color: Color(0xFF10B981),
                  ),
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                ),
                hint: const Text('Selecciona método de pago (opcional)'),
                items: _metodosPagoOptions
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e.id,
                        child: Text(e.nombre, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMetodoPagoId = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Cuenta (dropdown)
              _buildSectionTitle('Cuenta'),
              const SizedBox(height: 12),
              accountsAsync.when(
                data: (cuentas) {
                  if (cuentas.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'No hay cuentas disponibles. Crea una cuenta primero.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  // Eliminar duplicados por ID
                  final cuentasUnicas = cuentas.toSet().toList();

                  return DropdownButtonFormField<Cuenta>(
                    initialValue: _selectedCuenta,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      prefixIcon: const Icon(
                        Icons.account_balance,
                        color: Color(0xFF10B981),
                      ),
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
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
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona una cuenta';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    'Error al cargar cuentas',
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
              ),

              // Mostrar saldo resultante si es un gasto y hay cuenta seleccionada
              if (!isIngreso && _selectedCuenta != null) ...[
                const SizedBox(height: 16),
                _buildSaldoResultante(),
              ],

              const SizedBox(height: 24),

              // Categoría (dropdown)
              _buildSectionTitle('Categoría'),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (categorias) {
                  final categoriasFiltradas = categorias.where((cat) {
                    return cat.tipo == 'AMBOS' ||
                        cat.tipo == widget.tipoTransaccion;
                  }).toList();

                  if (categoriasFiltradas.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'No hay categorías disponibles.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  // Eliminar duplicados por ID
                  final categoriasUnicas = categoriasFiltradas.toSet().toList();

                  return DropdownButtonFormField<Categoria>(
                    initialValue: _selectedCategoria,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      prefixIcon: const Icon(
                        Icons.category,
                        color: Color(0xFF10B981),
                      ),
                      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    hint: const Text('Selecciona una categoría'),
                    items: categoriasUnicas.map((categoria) {
                      return DropdownMenuItem<Categoria>(
                        value: categoria,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _parseColor(categoria.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              categoria.nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (categoria) {
                      setState(() {
                        _selectedCategoria = categoria;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona una categoría';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    'Error al cargar categorías',
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Fecha
              _buildSectionTitle('Fecha'),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                      );
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _formatOnlyDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Descripción
              _buildSectionTitle('Descripción'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej: Compra de supermercado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF10B981),
                  ),
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Notas
              _buildSectionTitle('Notas (opcional)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notasController,
                decoration: InputDecoration(
                  labelText: 'Notas',
                  hintText: 'Notas adicionales...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: const Icon(
                    Icons.note_outlined,
                    color: Color(0xFF10B981),
                  ),
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Checkbox repetir
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _repetir
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Checkbox(
                        value: _repetir,
                        onChanged: (value) {
                          setState(() {
                            _repetir = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF10B981),
                        checkColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Marcar como transacción recurrente',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_repetir) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Configuración de recurrencia'),
                const SizedBox(height: 12),
                // Frecuencia
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _frecuencia,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF10B981),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    prefixIcon: const Icon(
                      Icons.schedule,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DIARIO', child: Text('Diario')),
                    DropdownMenuItem(value: 'SEMANAL', child: Text('Semanal')),
                    DropdownMenuItem(value: 'MENSUAL', child: Text('Mensual')),
                    DropdownMenuItem(
                      value: 'BIMESTRAL',
                      child: Text('Bimestral'),
                    ),
                    DropdownMenuItem(
                      value: 'TRIMESTRAL',
                      child: Text('Trimestral'),
                    ),
                    DropdownMenuItem(
                      value: 'SEMESTRAL',
                      child: Text('Semestral'),
                    ),
                    DropdownMenuItem(value: 'ANUAL', child: Text('Anual')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _frecuencia = val ?? 'MENSUAL';
                      // Defaults según frecuencia
                      if (_frecuencia == 'SEMANAL') {
                        final js = _selectedDate.weekday; // 1=lun..7=dom
                        _diaSemana = js;
                        _diaVencimiento = null;
                      } else if (_frecuencia == 'DIARIO') {
                        _diaSemana = null;
                        _diaVencimiento = null;
                      } else {
                        _diaSemana = null;
                        _diaVencimiento = _selectedDate.day;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_frecuencia == 'SEMANAL')
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _diaSemana ?? (_selectedDate.weekday),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      prefixIcon: const Icon(
                        Icons.event,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Lunes')),
                      DropdownMenuItem(value: 2, child: Text('Martes')),
                      DropdownMenuItem(value: 3, child: Text('Miércoles')),
                      DropdownMenuItem(value: 4, child: Text('Jueves')),
                      DropdownMenuItem(value: 5, child: Text('Viernes')),
                      DropdownMenuItem(value: 6, child: Text('Sábado')),
                      DropdownMenuItem(value: 7, child: Text('Domingo')),
                    ],
                    onChanged: (v) => setState(() => _diaSemana = v),
                  ),
                if (_frecuencia != 'SEMANAL' && _frecuencia != 'DIARIO')
                  TextFormField(
                    initialValue: (_diaVencimiento ?? _selectedDate.day)
                        .toString(),
                    decoration: InputDecoration(
                      labelText: 'Día del mes (1-31)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      prefixIcon: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 1 && n <= 31) _diaVencimiento = n;
                    },
                  ),
                const SizedBox(height: 12),
                // Fechas inicio/fin
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.flag),
                        label: Text('Inicio: ${_formatOnlyDate(_fechaInicio)}'),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _fechaInicio,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) setState(() => _fechaInicio = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.flag_circle),
                        label: Text(
                          _fechaFin != null
                              ? 'Fin: ${_formatOnlyDate(_fechaFin!)}'
                              : 'Sin fecha fin',
                        ),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _fechaFin ?? _fechaInicio,
                            firstDate: _fechaInicio,
                            lastDate: DateTime(2100),
                          );
                          setState(() => _fechaFin = d);
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 40),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                          colors: isIngreso
                              ? [
                                  const Color(0xFF10B981),
                                  const Color(0xFF059669),
                                ]
                              : [
                                  const Color(0xFFEF4444),
                                  const Color(0xFFDC2626),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isIngreso
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444))
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _handleCreate(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Crear ${isIngreso ? 'Ingreso' : 'Gasto'}',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
      ),
    );
  }

  void _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCuenta == null || _selectedCategoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos requeridos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar saldo suficiente si es un gasto
    if (widget.tipoTransaccion != 'INGRESO') {
      final monto = double.tryParse(_montoController.text);
      if (monto != null) {
        final saldoActual = _selectedCuenta!.saldoActual ?? _selectedCuenta!.saldoInicial;
        if (monto > saldoActual) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saldo insuficiente. Saldo disponible: ${_selectedCuenta!.moneda} ${saldoActual.toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }

    try {
      final request = CreateTransaccionRequest(
        cuentaId: _selectedCuenta!.id,
        tipoTransaccionId: _tipoTransaccionId!,
        categoriaId: _selectedCategoria!.id,
        metodoPagoId: _selectedMetodoPagoId,
        monto: double.parse(_montoController.text),
        moneda: 'COP',
        titulo: _tituloController.text.trim().isNotEmpty
            ? _tituloController.text.trim()
            : null,
        descripcion: _descripcionController.text.trim().isNotEmpty
            ? _descripcionController.text.trim()
            : null,
        // Enviar solo la fecha seleccionada (sin hora) - el backend combinará con la hora actual del sistema
        // Extraer solo año, mes, día de la fecha seleccionada
        fechaTransaccion: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          0, // Hora 0 - el servidor usará la hora actual
          0, // Minutos 0
          0, // Segundos 0
        ),
        notas: _notasController.text.trim().isNotEmpty
            ? _notasController.text.trim()
            : null,
        repetir: _repetir,
      );

      await ref
          .read(transactionsNotifierProvider.notifier)
          .createTransaction(request);

      // Si se marcó repetir, crear la regla recurrente
      if (_repetir) {
        final api = RecurringService(ApiClient());
        final freq = _frecuencia;
        int? diaV = (freq != 'SEMANAL' && freq != 'DIARIO')
            ? (_diaVencimiento ?? _selectedDate.day)
            : null;
        int? diaS = (freq == 'SEMANAL')
            ? (_diaSemana ?? _selectedDate.weekday)
            : null;

        String fmt(DateTime d) =>
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

        final ruleReq = CreatePagoRecurrenteRequest(
          categoriaId: _selectedCategoria!.id,
          cuentaId: _selectedCuenta!.id,
          metodoPagoId: _selectedMetodoPagoId,
          monto: double.parse(_montoController.text),
          descripcion: _tituloController.text.trim().isNotEmpty
              ? _tituloController.text.trim()
              : (_descripcionController.text.trim().isNotEmpty
                    ? _descripcionController.text.trim()
                    : 'Pago recurrente'),
          frecuencia: freq,
          diaVencimiento: diaV,
          diaSemana: diaS,
          fechaInicio: fmt(_fechaInicio),
          fechaFin: _fechaFin != null ? fmt(_fechaFin!) : null,
        );
        await api.createRule(ruleReq);
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.tipoTransaccion} creado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatOnlyDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Opciones locales de métodos de pago.
  // IDs basados en los inserts iniciales de la BD (1..8)
  List<_MetodoPagoOption> get _metodosPagoOptions => const [
    _MetodoPagoOption(1, 'Efectivo'),
    _MetodoPagoOption(2, 'Tarjeta de Débito'),
    _MetodoPagoOption(3, 'Tarjeta de Crédito'),
    _MetodoPagoOption(4, 'Transferencia Bancaria'),
    _MetodoPagoOption(5, 'Cheque'),
    _MetodoPagoOption(6, 'PayPal'),
    _MetodoPagoOption(7, 'Apple Pay'),
    _MetodoPagoOption(8, 'Google Pay'),
  ];

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

  Widget _buildSaldoResultante() {
    if (_selectedCuenta == null) return const SizedBox.shrink();
    
    final saldoActual = _selectedCuenta!.saldoActual ?? _selectedCuenta!.saldoInicial;
    final montoTexto = _montoController.text.trim();
    final monto = double.tryParse(montoTexto) ?? 0.0;
    
    if (monto <= 0) {
      return const SizedBox.shrink();
    }
    
    final saldoResultante = saldoActual - monto;
    final tieneSaldoSuficiente = saldoResultante >= 0;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (value * 0.05),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tieneSaldoSuficiente ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tieneSaldoSuficiente ? Colors.green.shade200 : Colors.red.shade200,
                  width: 1.5,
                ),
                // Glassmorphism effect
                boxShadow: [
                  BoxShadow(
                    color: (tieneSaldoSuficiente ? Colors.green : Colors.red).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(-1, -1),
                  ),
                ],
              ),
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tieneSaldoSuficiente ? Icons.check_circle : Icons.error,
                color: tieneSaldoSuficiente ? Colors.green.shade700 : Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Saldo de la cuenta',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tieneSaldoSuficiente ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo actual',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: saldoActual),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedValue, child) {
                          // Formatear con separadores de miles (puntos) y sin decimales .00
                          final formatter = NumberFormat('#,###', 'es_CO');
                          final formattedValue = animatedValue % 1 == 0
                              ? formatter.format(animatedValue.toInt())
                              : formatter.format(animatedValue).replaceAll(RegExp(r'\.?0+$'), '');
                          return Text(
                            '${_selectedCuenta!.moneda} $formattedValue',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Saldo resultante',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: saldoActual, end: saldoResultante),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedValue, child) {
                          // Formatear con separadores de miles (puntos) y sin decimales .00
                          final formatter = NumberFormat('#,###', 'es_CO');
                          final formattedValue = animatedValue % 1 == 0
                              ? formatter.format(animatedValue.toInt())
                              : formatter.format(animatedValue).replaceAll(RegExp(r'\.?0+$'), '');
                          return Text(
                            '${_selectedCuenta!.moneda} $formattedValue',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: tieneSaldoSuficiente ? Colors.green.shade700 : Colors.red.shade700,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (!tieneSaldoSuficiente) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El monto excede el saldo disponible',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
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
          ),
        );
      },
    );
  }
}

class _MetodoPagoOption {
  final int id;
  final String nombre;
  const _MetodoPagoOption(this.id, this.nombre);
}
