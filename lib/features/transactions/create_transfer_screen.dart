import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/cuenta_models.dart';
import 'transactions_provider.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart'; // Para apiClientProvider

class CreateTransferScreen extends ConsumerStatefulWidget {
  const CreateTransferScreen({super.key});

  @override
  ConsumerState<CreateTransferScreen> createState() =>
      _CreateTransferScreenState();
}

class _CreateTransferScreenState extends ConsumerState<CreateTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _notasController = TextEditingController();
  
  Cuenta? _selectedCuentaOrigen;
  Cuenta? _selectedCuentaDestino;
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _montoController.dispose();
    _tituloController.dispose();
    _descripcionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateTransfer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCuentaOrigen == null || _selectedCuentaDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona ambas cuentas')),
      );
      return;
    }

    if (_selectedCuentaOrigen!.id == _selectedCuentaDestino!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las cuentas no pueden ser la misma')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final monto = double.parse(_montoController.text);
      
      await apiClient.dio.post(
        '/api/transacciones/transfer',
        data: {
          'cuentaOrigenId': _selectedCuentaOrigen!.id,
          'cuentaDestinoId': _selectedCuentaDestino!.id,
          'monto': monto,
          'moneda': _selectedCuentaOrigen!.moneda,
          'titulo': _tituloController.text.trim().isNotEmpty 
              ? _tituloController.text.trim() 
              : null,
          'descripcion': _descripcionController.text.trim().isNotEmpty 
              ? _descripcionController.text.trim() 
              : null,
          // No enviar fechaTransaccion - el backend usará la fecha/hora actual del servidor
          // 'fechaTransaccion': _selectedDate.toLocal().toIso8601String().substring(0, 19),
          'notas': _notasController.text.trim().isNotEmpty 
              ? _notasController.text.trim() 
              : null,
        },
      );

      // Refrescar transacciones y cuentas
      await ref.read(transactionsNotifierProvider.notifier).refresh();
      await ref.read(accountsNotifierProvider.notifier).refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transferencia realizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al realizar transferencia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Nueva Transferencia',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vista previa del monto
              if (_montoController.text.isNotEmpty && double.tryParse(_montoController.text) != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Transferir',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0)
                            .format(double.parse(_montoController.text)),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_montoController.text.isNotEmpty && double.tryParse(_montoController.text) != null)
                const SizedBox(height: 24),

              // Sección de cuentas
              accountsAsync.when(
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No hay cuentas disponibles'),
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.swap_horiz, color: Color(0xFF8B5CF6), size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Seleccionar Cuentas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Cuenta Origen
                        DropdownButtonFormField<Cuenta>(
                          initialValue: _selectedCuentaOrigen,
                          decoration: InputDecoration(
                            labelText: 'Desde (Origen)',
                            labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                            prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF8B5CF6)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                          ),
                          items: accounts.map((cuenta) {
                            final saldo = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0)
                                .format(cuenta.saldoActual ?? 0);
                            return DropdownMenuItem<Cuenta>(
                              value: cuenta,
                              child: Text('${cuenta.nombre} - $saldo'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCuentaOrigen = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecciona la cuenta de origen';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Flecha divisoria
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_downward,
                              color: Color(0xFF8B5CF6),
                              size: 20,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Cuenta Destino
                        DropdownButtonFormField<Cuenta>(
                          initialValue: _selectedCuentaDestino,
                          decoration: InputDecoration(
                            labelText: 'Hacia (Destino)',
                            labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                            prefixIcon: const Icon(Icons.account_balance, color: Color(0xFF10B981)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                          ),
                          items: accounts.map((cuenta) {
                            final saldo = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0)
                                .format(cuenta.saldoActual ?? 0);
                            return DropdownMenuItem<Cuenta>(
                              value: cuenta,
                              child: Text('${cuenta.nombre} - $saldo'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCuentaDestino = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecciona la cuenta de destino';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text('Error: $err'),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Monto
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments, color: Color(0xFF10B981), size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Monto a Transferir',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _montoController,
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF10B981)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el monto';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'El monto debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Fecha y Hora
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.event, color: Color(0xFF3B82F6), size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Fecha y Hora',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF3B82F6)),
                      label: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(color: Color(0xFF1F2937)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Detalles opcionales
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_note, color: Color(0xFF6B7280), size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Detalles Adicionales (Opcional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Título
                    TextFormField(
                      controller: _tituloController,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        hintText: 'Ej: Transferencia mensual',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.title, color: Color(0xFF6B7280), size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        counterText: '',
                      ),
                      maxLength: 150,
                    ),

                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        hintText: 'Motivo de la transferencia',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.description, color: Color(0xFF6B7280), size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        counterText: '',
                      ),
                      maxLines: 2,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 16),

                    // Notas
                    TextFormField(
                      controller: _notasController,
                      decoration: InputDecoration(
                        labelText: 'Notas',
                        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                        hintText: 'Información adicional',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.note, color: Color(0xFF6B7280), size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        counterText: '',
                      ),
                      maxLines: 2,
                      maxLength: 1000,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botón crear
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleCreateTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              'Realizar Transferencia',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

