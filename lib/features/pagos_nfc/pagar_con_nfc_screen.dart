import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tarjetas_nfc/tarjetas_nfc_provider.dart' as tprov;
import 'pagos_nfc_service.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../core/device/device_registry.dart';
import '../../core/api/api_client.dart';

class PagarConNfcScreen extends ConsumerStatefulWidget {
  const PagarConNfcScreen({super.key});

  @override
  ConsumerState<PagarConNfcScreen> createState() => _PagarConNfcScreenState();
}

class _PagarConNfcScreenState extends ConsumerState<PagarConNfcScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _tarjetaId;
  int? _cuentaId;
  int? _categoriaId;
  bool _isProcessing = false;
  bool _showQuickScanPrompt = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Iniciar escaneo rápido automáticamente después de un delay corto
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _showQuickScanPrompt) {
        _startQuickScan();
      }
    });
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tarjetasAsync = ref.watch(tprov.tarjetasNfcProvider);
    final cuentasAsync = ref.watch(accountsProvider);
    final categoriasAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagar con NFC',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              'Registra un nuevo pago',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner de escaneo rápido
              if (_showQuickScanPrompt && _tarjetaId == null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF10B981).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.nfc, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡Acerca tu tarjeta!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Detectando tarjeta NFC...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _showQuickScanPrompt = false);
                          NfcManager.instance.stopSession();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Omitir'),
                      ),
                    ],
                  ),
                ),

              // Tarjeta seleccionada preview
              if (_tarjetaId != null) _buildSelectedCardPreview(tarjetasAsync),

              // Sección de monto (principal)
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Monto del Pago', Icons.attach_money),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _montoCtrl,
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.payments, color: Color(0xFF10B981)),
                        prefixText: '\$ ',
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
                        fillColor: Colors.grey[50],
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null || d <= 0) return 'Ingresa un monto válido';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sección de detalles
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Detalles del Pago', Icons.info_outline),
                    const SizedBox(height: 16),

                    // Tarjeta NFC
                    tarjetasAsync.when(
                      data: (tarjetas) {
                        final activeTarjetas = tarjetas.where((t) => t.activa).toList();
                        // Validar que _tarjetaId esté en la lista, si no, usar null
                        final validTarjetaId = activeTarjetas.any((t) => t.id == _tarjetaId) ? _tarjetaId : null;
                        return DropdownButtonFormField<int?>(
                          initialValue: validTarjetaId,
                          decoration: InputDecoration(
                            labelText: 'Tarjeta NFC',
                            hintText: 'Selecciona o escanea',
                            prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF3B82F6)),
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
                          isExpanded: true,
                          items: activeTarjetas.map((t) {
                            final color = _parseColor(t.color) ?? const Color(0xFF3B82F6);
                            return DropdownMenuItem(
                              value: t.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${t.nombrePortador} • ${t.banco ?? 'Sin banco'}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              _tarjetaId = v;
                              // Si se selecciona una tarjeta, heredar su cuenta
                              if (v != null) {
                                final tarjeta = activeTarjetas.firstWhere((t) => t.id == v);
                                _cuentaId = tarjeta.cuentaId;
                              }
                            });
                          },
                          validator: (v) => null, // Opcional, se puede detectar con NFC
                        );
                      },
                      loading: () => const SizedBox(
                        height: 56,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text(
                        'Error al cargar tarjetas: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cuenta
                    cuentasAsync.when(
                      data: (cuentas) => DropdownButtonFormField<int?>(
                        initialValue: _cuentaId,
                        decoration: InputDecoration(
                          labelText: 'Cuenta',
                          hintText: 'Heredará de la tarjeta',
                          prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFFF59E0B)),
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
                            child: Text('Usar cuenta de la tarjeta'),
                          ),
                          ...cuentas.map((c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.nombre),
                              )),
                        ],
                        onChanged: (v) => setState(() => _cuentaId = v),
                      ),
                      loading: () => const SizedBox(
                        height: 56,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text(
                        'Error al cargar cuentas: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Categoría
                    categoriasAsync.when(
                      data: (cats) => DropdownButtonFormField<int?>(
                        initialValue: _categoriaId,
                        decoration: InputDecoration(
                          labelText: 'Categoría',
                          hintText: 'Sin categoría',
                          prefixIcon: const Icon(Icons.category, color: Color(0xFF8B5CF6)),
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
                            child: Text('Sin categoría'),
                          ),
                          ...cats.map((c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.nombre),
                              )),
                        ],
                        onChanged: (v) => setState(() => _categoriaId = v),
                      ),
                      loading: () => const SizedBox(
                        height: 56,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text(
                        'Error al cargar categorías: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Ej: Compra en supermercado',
                        prefixIcon: const Icon(Icons.description, color: Color(0xFF6B7280)),
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
                          borderSide: const BorderSide(color: Color(0xFF6B7280), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón de pagar con NFC
              _buildPayButton(),

              const SizedBox(height: 12),

              // Ayuda
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _tarjetaId == null
                            ? 'Si no seleccionas tarjeta, se detectará automáticamente al acercarla'
                            : 'Presiona el botón y acerca tu tarjeta NFC al teléfono',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1F2937),
                        ),
                      ),
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

  Widget _buildSelectedCardPreview(AsyncValue tarjetasAsync) {
    return tarjetasAsync.when(
      data: (tarjetas) {
        final tarjeta = tarjetas.cast<dynamic>().firstWhere(
              (t) => t.id == _tarjetaId,
              orElse: () => null,
            );
        if (tarjeta == null) return const SizedBox.shrink();

        final color = _parseColor(tarjeta.color) ?? const Color(0xFF3B82F6);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tarjeta.tipo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Icon(Icons.contactless, color: Colors.white, size: 24),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarjeta.nombrePortador.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tarjeta.banco?.toUpperCase() ?? 'SIN BANCO',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
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

  Widget _buildPayButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isProcessing
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981)
                          .withOpacity(0.3 + (_pulseController.value * 0.3)),
                      blurRadius: 20,
                      spreadRadius: _pulseController.value * 5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _handleDetectarYpagar,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isProcessing
                  ? const Color(0xFF10B981)
                  : const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.nfc, size: 28),
            label: Text(
              _isProcessing ? 'Acerca tu tarjeta NFC...' : 'Pagar con NFC',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDetectarYpagar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Si el usuario no seleccionó tarjeta, detectarla por NFC
      if (_tarjetaId == null) {
        // Mostrar diálogo de escaneo
        if (!mounted) return;
        final uid = await _showNfcScanDialog();

        if (uid == null) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          return;
        }

        // Buscar tarjeta que tenga numeroTarjetaHash == uid
        final tarjetasAsync = ref.read(tprov.tarjetasNfcProvider);
        final tarjetas = tarjetasAsync.value;
        dynamic match;
        if (tarjetas != null) {
          for (final t in tarjetas) {
            if (t.numeroTarjetaHash.toUpperCase() == uid.toUpperCase()) {
              match = t;
              break;
            }
          }
        }

        if (match == null) {
          if (!mounted) return;
          _showErrorSnackbar('Tarjeta no registrada en el sistema');
          setState(() => _isProcessing = false);
          return;
        }

        _tarjetaId = match.id;
        _cuentaId ??= match.cuentaId;
      }

      final api = ref.read(tprov.apiClientProvider);
      final dispositivoId = await _ensureDeviceId(api);
      final service = PagosNfcService(api);

      final body = {
        'tarjetaId': _tarjetaId,
        'dispositivoNfcId': dispositivoId,
        'monto': double.parse(_montoCtrl.text),
        // No enviar fechaTransaccion - el backend usará la fecha/hora actual del servidor
        if (_cuentaId != null) 'cuentaId': _cuentaId,
        if (_categoriaId != null) 'categoriaId': _categoriaId,
        if (_descCtrl.text.trim().isNotEmpty) 'descripcion': _descCtrl.text.trim(),
      };

      await service.create(body);

      if (!mounted) return;

      _showSuccessSnackbar('Pago registrado exitosamente');

      // Esperar un momento para que el usuario vea el mensaje
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Error al registrar el pago: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _startQuickScan() async {
    final uid = await _showNfcScanDialog();
    if (uid == null || !mounted) return;

    // Buscar tarjeta con este UID
    final tarjetasAsync = ref.read(tprov.tarjetasNfcProvider);
    final tarjetas = tarjetasAsync.value;
    dynamic match;

    if (tarjetas != null) {
      for (final t in tarjetas) {
        if (t.numeroTarjetaHash.toUpperCase() == uid.toUpperCase()) {
          match = t;
          break;
        }
      }
    }

    if (match == null) {
      _showErrorSnackbar('Tarjeta no registrada en el sistema');
      return;
    }

    // Precargar datos
    setState(() {
      _tarjetaId = match.id;
      _cuentaId = match.cuentaId;
      _showQuickScanPrompt = false;
    });

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Tarjeta detectada: ${match.nombrePortador}'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Auto-focus en el campo de monto
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  Future<String?> _showNfcScanDialog() async {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NfcScanDialog(
        onScan: _leerUid,
      ),
    );
  }

  Future<String?> _leerUid() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        print('❌ NFC no disponible');
        return null;
      }

      print('🔍 Iniciando sesión NFC...');

      // Usar Completer para esperar a que se detecte el tag
      final completer = Completer<String?>();
      bool tagDetected = false;

      // NO usar timeout - dejar sesión abierta hasta detectar
      NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (tag) async {
          if (tagDetected) {
            print('⚠️ Tag ya detectado, ignorando...');
            return;
          }

          print('📱 Tag detectado!');
          tagDetected = true;

          // Vibración para feedback inmediato
          try {
            HapticFeedback.mediumImpact();
          } catch (_) {}

          String? uidHex;
          try {
            print('📊 Leyendo datos del tag...');
            final tagPigeon = tag.data as dynamic;
            print('🔍 Tag type: ${tagPigeon.runtimeType}');

            final id = tagPigeon.id;
            if (id != null) {
              print('✅ ID encontrado: $id');
              final identifier = List<int>.from(id);
              uidHex = identifier
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
              print('✅ UID extraído: $uidHex');
            } else {
              print('❌ ID es null');
            }
          } catch (e, stack) {
            print('❌ Error al leer UID: $e');
            print('Stack: $stack');
          }

          print('🔚 Cerrando sesión NFC...');
          await NfcManager.instance.stopSession();

          // Completar el Future con el UID
          if (!completer.isCompleted) {
            completer.complete(uidHex);
          }
        },
      );

      // Esperar a que se complete la lectura
      final uidHex = await completer.future;
      print('🏁 Sesión finalizada. UID: $uidHex');
      return uidHex;
    } catch (e, stack) {
      print('❌ Error general en _leerUid: $e');
      print('Stack: $stack');
      try {
        await NfcManager.instance.stopSession();
      } catch (_) {
        // Ya estaba cerrada
      }
      return null;
    }
  }

  Future<int> _ensureDeviceId(ApiClient api) async {
    return await DeviceRegistry.ensureRegistered(api);
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    if (h.length == 8) {
      return Color(int.parse(h, radix: 16));
    }
    return null;
  }
}

// Widget para el diálogo de escaneo NFC
class _NfcScanDialog extends StatefulWidget {
  final Future<String?> Function() onScan;

  const _NfcScanDialog({required this.onScan});

  @override
  State<_NfcScanDialog> createState() => _NfcScanDialogState();
}

class _NfcScanDialogState extends State<_NfcScanDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _elapsedSeconds = 0;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _startScan();
    _startTimer();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _cancelled) return;
      setState(() {
        _elapsedSeconds++;
        _startTimer();
      });
    });
  }

  Future<void> _startScan() async {
    try {
      final uid = await widget.onScan();
      if (!mounted || _cancelled) return;
      Navigator.of(context).pop(uid);
    } catch (e) {
      if (!mounted || _cancelled) return;
      Navigator.of(context).pop(null);
    }
  }

  void _cancel() {
    setState(() => _cancelled = true);
    NfcManager.instance.stopSession();
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono NFC animado
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withOpacity(0.2 + (_animController.value * 0.3)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.contactless,
                      size: 50,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Título
            const Text(
              'Acerca tu tarjeta NFC',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Instrucciones
            Column(
              children: [
                Text(
                  'Mantén la tarjeta pegada a la parte trasera del teléfono',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 Mueve lentamente la tarjeta para encontrar el sensor NFC',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Indicador de escaneo continuo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Escaneando... ($_elapsedSeconds seg)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón cancelar
            TextButton(
              onPressed: _cancel,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
