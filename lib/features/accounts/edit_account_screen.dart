import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/utils/monedas_constants.dart';
import 'accounts_provider.dart';

class EditAccountScreen extends ConsumerStatefulWidget {
  final Cuenta cuenta;

  const EditAccountScreen({super.key, required this.cuenta});

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _saldoInicialController;
  late String _selectedTipo;
  late String _selectedMoneda;
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
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cuenta.nombre);
    _descripcionController = TextEditingController(
      text: widget.cuenta.descripcion ?? '',
    );
    _saldoInicialController = TextEditingController(
      text: widget.cuenta.saldoInicial.toStringAsFixed(2),
    );
    _selectedTipo = widget.cuenta.tipo;
    _selectedMoneda = widget.cuenta.moneda;
    _selectedColor = widget.cuenta.color;
    _selectedIcono = widget.cuenta.icono;
  }

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
      appBar: AppBar(
        title: const Text(
          'Editar Cuenta',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vista previa
              _buildPreviewCard(),

                const SizedBox(height: 32),

              // Nombre
              TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la cuenta',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.account_balance, color: Color(0xFF059669)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 24),

              // Tipo
              _buildSectionTitle('Tipo de Cuenta'),
              const SizedBox(height: 16),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tipos.map((tipo) {
                    final isSelected = _selectedTipo == tipo;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTipo = tipo;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF059669)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF059669)
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF059669).withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          tipo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
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
                  initialValue: _selectedMoneda.isNotEmpty && _monedasCodigos.contains(_selectedMoneda)
                      ? _selectedMoneda
                      : _monedasCodigos.first,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.currency_exchange, color: Color(0xFF059669)),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getMonedaInfoText(_selectedMoneda.isNotEmpty && _monedasCodigos.contains(_selectedMoneda)
                            ? _selectedMoneda
                            : _monedasCodigos.first),
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
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF059669)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Color
              _buildSectionTitle('Color'),
              const SizedBox(height: 16),
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
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.actualColor.withOpacity(0.2),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.circle,
                          color: color.actualColor,
                          size: 32,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Icono
              _buildSectionTitle('Icono'),
              const SizedBox(height: 16),
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF059669)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF059669)
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF059669).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icono.icon,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
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
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF059669)),
                  ),
                  maxLines: 3,
                ),

              const SizedBox(height: 40),

              // Botón guardar
              ElevatedButton(
                  onPressed: _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar Cambios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

              const SizedBox(height: 16),

              // Botón eliminar
              OutlinedButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text(
                    'Eliminar Cuenta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
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

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _parseColor(_selectedColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getIcon(_selectedIcono),
              color: _parseColor(_selectedColor),
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nombreController.text.isNotEmpty
                      ? _nombreController.text
                      : 'Nombre',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(_selectedTipo).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedTipo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getTypeColor(_selectedTipo),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  void _handleUpdate() async {
    try {
      final request = UpdateCuentaRequest(
        nombre: _nombreController.text.trim(),
        tipo: _selectedTipo,
        moneda: _selectedMoneda,
        saldoInicial: double.tryParse(_saldoInicialController.text),
        color: _selectedColor,
        icono: _selectedIcono,
        descripcion: _descripcionController.text.trim().isNotEmpty
            ? _descripcionController.text.trim()
            : null,
      );

      await ref
          .read(accountsNotifierProvider.notifier)
          .updateAccount(widget.cuenta.id, request);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta actualizada exitosamente'),
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

  void _showDeleteConfirmation(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final cuentaColor = widget.cuenta.color != null && widget.cuenta.color!.isNotEmpty
        ? Color(int.parse(widget.cuenta.color!.replaceFirst('#', '0xFF')))
        : const Color(0xFF3B82F6);
    
    String getTipoLabel(String tipo) {
      switch (tipo) {
        case 'BANCARIA':
          return 'Bancaria';
        case 'EFECTIVO':
          return 'Efectivo';
        case 'TARJETA_CREDITO':
          return 'Tarjeta de Crédito';
        case 'TARJETA_DEBITO':
          return 'Tarjeta de Débito';
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

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.shade600,
                      Colors.red.shade700,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Eliminar Cuenta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Contenido
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Información de la cuenta
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cuentaColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cuentaColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (widget.cuenta.icono != null && widget.cuenta.icono!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cuentaColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getIconData(widget.cuenta.icono!),
                                    color: cuentaColor,
                                    size: 20,
                                  ),
                                ),
                              if (widget.cuenta.icono != null && widget.cuenta.icono!.isNotEmpty)
                                const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.cuenta.nombre,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: cuentaColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      getTipoLabel(widget.cuenta.tipo),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (widget.cuenta.saldoActual != null) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Saldo actual',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  formatoMoneda.format(widget.cuenta.saldoActual),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: widget.cuenta.saldoActual! >= 0
                                        ? const Color(0xFF10B981)
                                        : Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Mensaje de advertencia
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Esta acción no se puede deshacer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No se puede eliminar si tiene transacciones asociadas o saldo diferente de cero.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade600,
                                  Colors.red.shade700,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop(); // Cerrar diálogo

                                try {
                                  await ref
                                      .read(accountsNotifierProvider.notifier)
                                      .deleteAccount(widget.cuenta.id);

                                  if (context.mounted) {
                                    Navigator.of(context).pop(); // Cerrar pantalla de edición
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            SizedBox(width: 12),
                                            Text('Cuenta eliminada exitosamente'),
                                          ],
                                        ),
                                        backgroundColor: Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        margin: EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    final errorMessage = e.toString().replaceFirst('Exception: ', '');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.white),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(errorMessage)),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'account_balance':
        return Icons.account_balance;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'credit_card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.wallet;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'payments':
        return Icons.payments;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.account_balance;
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

  Color _getTypeColor(String tipo) {
    switch (tipo) {
      case 'BANCARIA':
        return Colors.blue;
      case 'EFECTIVO':
        return Colors.green;
      case 'TARJETA_CREDITO':
      case 'TARJETA_DEBITO':
        return Colors.orange;
      case 'DIGITAL':
        return Colors.purple;
      case 'AHORRO':
        return Colors.teal;
      case 'INVERSION':
        return Colors.indigo;
      default:
        return Colors.grey;
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
