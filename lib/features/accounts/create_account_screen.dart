import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/utils/monedas_constants.dart';
import 'accounts_provider.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _saldoInicialController = TextEditingController();
  String _selectedTipo = 'BANCARIA';
  String _selectedMoneda = 'COP';
  String? _selectedColor;
  String? _selectedIcono;

  // Tipos de cuenta
  final List<String> _tipos = [
    'BANCARIA',
    'EFECTIVO',
    'TARJETA_CREDITO',
    'TARJETA_DEBITO',
    'DIGITAL',
    'AHORRO',
    'INVERSION',
  ];

  // Monedas disponibles (ordenadas por código único)
  List<String> get _monedasCodigos => MonedasConstants.codigosUnicos;

  // Paleta de colores
  final List<ColorOption> _colores = [
    ColorOption('#10B981', 'Verde', Colors.green),
    ColorOption('#3B82F6', 'Azul', Colors.blue),
    ColorOption('#8B5CF6', 'Morado', Colors.purple),
    ColorOption('#EC4899', 'Rosa', Colors.pink),
    ColorOption('#F59E0B', 'Amarillo', Colors.orange),
    ColorOption('#EF4444', 'Rojo', Colors.red),
    ColorOption('#06B6D4', 'Cian', Colors.cyan),
    ColorOption('#6366F1', 'Índigo', Colors.indigo),
  ];

  // Iconos disponibles
  final List<IconOption> _iconos = [
    IconOption('account_balance', 'Banco', Icons.account_balance),
    IconOption(
      'account_balance_wallet',
      'Billetera',
      Icons.account_balance_wallet,
    ),
    IconOption('credit_card', 'Tarjeta', Icons.credit_card),
    IconOption('savings', 'Ahorros', Icons.savings),
    IconOption('wallet', 'Cartera', Icons.wallet),
    IconOption('payments', 'Pagos', Icons.payments),
    IconOption('trending_up', 'Inversión', Icons.trending_up),
    IconOption('attach_money', 'Dinero', Icons.attach_money),
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _saldoInicialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Nueva Cuenta',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con icono
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_card_rounded, color: Colors.white, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crear Nueva Cuenta',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Completa la información',
                            style: TextStyle(
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

              // Nombre
              _buildSectionTitle('Información Básica'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la cuenta',
                  hintText: 'Ej: Banco Principal',
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
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance,
                      color: Color(0xFF10B981), size: 20),
                  ),
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Tipo
              _buildSectionTitle('Tipo de Cuenta'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _tipos.map((tipo) {
                  final isSelected = _selectedTipo == tipo;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTipo = tipo;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _getTipoLabel(tipo),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Moneda
              _buildSectionTitle('Moneda'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedMoneda,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.currency_exchange, color: Color(0xFF10B981)),
                  ),
                  items: _monedasCodigos.map((codigo) {
                    final monedaInfo = MonedasConstants.getMonedaPorCodigo(codigo);
                    final paises = MonedasConstants.getMonedasPorPais(monedaInfo?.pais ?? '');
                    final displayText = paises.length > 1 
                        ? '$codigo (${paises.map((m) => m.pais).join(', ')})'
                        : monedaInfo != null 
                            ? '${monedaInfo.codigo} - ${monedaInfo.pais}'
                            : codigo;
                    
                    return DropdownMenuItem<String>(
                      value: codigo,
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMoneda = value;
                      });
                    }
                  },
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              // Mostrar información adicional de la moneda seleccionada
              if (_selectedMoneda.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getMonedaInfoText(_selectedMoneda),
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF1F2937),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Saldo inicial
              TextFormField(
                controller: _saldoInicialController,
                decoration: InputDecoration(
                  labelText: 'Saldo inicial',
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
                    borderSide:
                        const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.attach_money,
                        color: Color(0xFF10B981), size: 20),
                  ),
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'),
                  ),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty || value.trim().isEmpty) {
                    // Permitir vacío, se tratará como 0
                    return null;
                  }
                  final saldo = double.tryParse(value);
                  if (saldo == null) {
                    return 'Ingresa un número válido';
                  }
                  if (saldo < 0) {
                    return 'El saldo no puede ser negativo';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // Personalización
              _buildSectionTitle('Personalización'),
              const SizedBox(height: 16),

              // Color
              const Text(
                'Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colores.map((color) {
                  final isSelected = _selectedColor == color.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color.value;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.actualColor.withOpacity(0.15),
                        border: Border.all(
                          color: isSelected
                              ? color.actualColor
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 3 : 2,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.actualColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle,
                        color: color.actualColor,
                        size: 32,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Icono
              const Text(
                'Icono',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _iconos.length,
                itemBuilder: (context, index) {
                  final icono = _iconos[index];
                  final isSelected = _selectedIcono == icono.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcono = icono.value;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icono.icon,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF6B7280),
                        size: 28,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Añade notas sobre esta cuenta',
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
                    borderSide:
                        const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: Color(0xFF10B981), size: 20),
                  ),
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 40),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _handleCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Crear Cuenta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
        letterSpacing: -0.3,
      ),
    );
  }

  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'BANCARIA':
        return 'Bancaria';
      case 'EFECTIVO':
        return 'Efectivo';
      case 'TARJETA_CREDITO':
        return 'T. Crédito';
      case 'TARJETA_DEBITO':
        return 'T. Débito';
      case 'DIGITAL':
        return 'Digital';
      case 'AHORRO':
        return 'Ahorro';
      case 'INVERSION':
        return 'Inversión';
      default:
        return tipo;
    }
  }

  String _getMonedaInfoText(String codigo) {
    final monedaInfo = MonedasConstants.getMonedaPorCodigo(codigo);
    if (monedaInfo != null) {
      final paises = MonedasConstants.getMonedasPorPais(monedaInfo.pais);
      if (paises.length > 1) {
        final paisesList = paises.map((m) => m.pais).join(', ');
        return '${monedaInfo.nombreMoneda} - Usado en: $paisesList';
      }
      return '${monedaInfo.nombreMoneda} - ${monedaInfo.pais}';
    }
    return 'Moneda: $codigo';
  }

  void _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final request = CreateCuentaRequest(
        nombre: _nombreController.text.trim(),
        tipo: _selectedTipo,
        moneda: _selectedMoneda,
        saldoInicial: _saldoInicialController.text.trim().isEmpty 
            ? 0 
            : (double.tryParse(_saldoInicialController.text.trim()) ?? 0),
        color: _selectedColor,
        icono: _selectedIcono,
        descripcion: _descripcionController.text.trim().isNotEmpty
            ? _descripcionController.text.trim()
            : null,
      );

      await ref.read(accountsNotifierProvider.notifier).createAccount(request);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada exitosamente'),
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
}

// Helper classes
class ColorOption {
  final String value;
  final String name;
  final Color actualColor;

  ColorOption(this.value, this.name, this.actualColor);
}

class IconOption {
  final String value;
  final String label;
  final IconData icon;

  IconOption(this.value, this.label, this.icon);
}
