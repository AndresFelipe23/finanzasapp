import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/tarjeta_nfc_models.dart';
import '../accounts/accounts_provider.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'tarjetas_nfc_provider.dart';

class CreateEditTarjetaNfcScreen extends ConsumerStatefulWidget {
  final TarjetaNfc? tarjeta;
  const CreateEditTarjetaNfcScreen({super.key, this.tarjeta});

  @override
  ConsumerState<CreateEditTarjetaNfcScreen> createState() =>
      _CreateEditTarjetaNfcScreenState();
}

class _CreateEditTarjetaNfcScreenState
    extends ConsumerState<CreateEditTarjetaNfcScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _portadorCtrl = TextEditingController();
  final _hashCtrl = TextEditingController();
  final _bancoCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String _tipo = 'DEBITO';
  int? _cuentaId;
  bool _isLoading = false;
  bool _isReadingNfc = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    final t = widget.tarjeta;
    if (t != null) {
      _portadorCtrl.text = t.nombrePortador;
      _hashCtrl.text = t.numeroTarjetaHash;
      _bancoCtrl.text = t.banco ?? '';
      _colorCtrl.text = t.color ?? '';
      _tipo = t.tipo;
      _cuentaId = t.cuentaId;
    }
  }

  @override
  void dispose() {
    _portadorCtrl.dispose();
    _hashCtrl.dispose();
    _bancoCtrl.dispose();
    _colorCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _cardColor {
    final colorText = _colorCtrl.text.trim();
    if (colorText.isEmpty || !colorText.startsWith('#')) {
      return _tipo == 'DEBITO'
          ? const Color(0xFF3B82F6)
          : const Color(0xFF8B5CF6);
    }
    try {
      return Color(int.parse(colorText.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return _tipo == 'DEBITO'
          ? const Color(0xFF3B82F6)
          : const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentasAsync = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.tarjeta == null ? 'Nueva Tarjeta NFC' : 'Editar Tarjeta NFC',
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
              // Vista previa de la tarjeta
              _buildCardPreview(),

              const SizedBox(height: 32),

              // Tipo de tarjeta
              _sectionTitle('Tipo de Tarjeta', Icons.credit_card),
              const SizedBox(height: 12),
              _buildTipoSelector(),

              const SizedBox(height: 24),

              // Información del titular
              _sectionTitle('Información del Titular', Icons.person_outline),
              const SizedBox(height: 12),
              _buildCard(
                child: _buildTextField(
                  controller: _portadorCtrl,
                  label: 'Nombre del portador',
                  icon: Icons.badge_outlined,
                  hint: 'Ej: Juan Pérez',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'El nombre es requerido'
                      : null,
                ),
              ),

              const SizedBox(height: 24),

              // Lectura NFC
              _sectionTitle('Identificación NFC', Icons.nfc),
              const SizedBox(height: 12),
              _buildNfcSection(),

              const SizedBox(height: 24),

              // Detalles adicionales
              _sectionTitle('Detalles Adicionales', Icons.info_outline),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _bancoCtrl,
                      label: 'Banco (opcional)',
                      icon: Icons.account_balance,
                      hint: 'Ej: Bancolombia',
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
                      error: (e, _) => Text('Error al cargar cuentas: $e'),
                    ),
                    const SizedBox(height: 16),
                    _buildColorPicker(),
                  ],
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

  Widget _buildCardPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardColor, _cardColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Patrón de fondo
          Positioned.fill(
            child: CustomPaint(
              painter: CardPatternPainter(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _tipo == 'DEBITO' ? 'DÉBITO' : 'CRÉDITO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.contactless,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _hashCtrl.text.isEmpty
                      ? '•••• •••• •••• ••••'
                      : _hashCtrl.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TITULAR',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _portadorCtrl.text.isEmpty
                              ? 'NOMBRE APELLIDO'
                              : _portadorCtrl.text.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_bancoCtrl.text.isNotEmpty)
                      Text(
                        _bancoCtrl.text.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTipoSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTipoChip(
            tipo: 'DEBITO',
            label: 'Débito',
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTipoChip(
            tipo: 'CREDITO',
            label: 'Crédito',
            icon: Icons.credit_card,
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildTipoChip({
    required String tipo,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _tipo == tipo;

    return InkWell(
      onTap: () => setState(() => _tipo = tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
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
      inputFormatters: inputFormatters,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildNfcSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildTextField(
            controller: _hashCtrl,
            label: 'Hash / UID de la tarjeta',
            icon: Icons.fingerprint,
            hint: 'Ej: A1B2C3D4',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'El hash es requerido' : null,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_.]')),
            ],
          ),
          const SizedBox(height: 16),
          _buildNfcButton(),
        ],
      ),
    );
  }

  Widget _buildNfcButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isReadingNfc
                ? [
                    BoxShadow(
                      color: const Color(
                        0xFF10B981,
                      ).withValues(alpha: 0.3 + (_pulseController.value * 0.3)),
                      blurRadius: 20,
                      spreadRadius: _pulseController.value * 5,
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton.icon(
            onPressed: _isReadingNfc ? null : _leerNfcYCompletar,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isReadingNfc
                  ? const Color(0xFF10B981)
                  : const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: _isReadingNfc ? 0 : 2,
            ),
            icon: _isReadingNfc
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.nfc, size: 24),
            label: Text(
              _isReadingNfc
                  ? 'Acerca tu tarjeta al teléfono...'
                  : 'Escanear Tarjeta NFC',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCuentaDropdown(List cuentas) {
    return DropdownButtonFormField<int?>(
      initialValue: _cuentaId,
      decoration: InputDecoration(
        labelText: 'Cuenta asociada (opcional)',
        hintText: 'Vincula con una cuenta',
        prefixIcon: const Icon(
          Icons.account_balance_outlined,
          color: Color(0xFFF59E0B),
        ),
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
        const DropdownMenuItem<int?>(value: null, child: Text('Sin cuenta')),
        ...cuentas.map(
          (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.nombre)),
        ),
      ],
      onChanged: (v) => setState(() => _cuentaId = v),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _colorCtrl,
          decoration: InputDecoration(
            labelText: 'Color de la tarjeta (opcional)',
            hintText: '#3B82F6',
            prefixIcon: Icon(Icons.palette_outlined, color: _cardColor),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
            ),
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
              borderSide: BorderSide(color: _cardColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '#3B82F6', // Azul
            '#8B5CF6', // Morado
            '#10B981', // Verde
            '#F59E0B', // Naranja
            '#EF4444', // Rojo
            '#EC4899', // Rosa
            '#14B8A6', // Teal
            '#6366F1', // Indigo
          ].map((color) => _buildColorChip(color)).toList(),
        ),
      ],
    );
  }

  Widget _buildColorChip(String hexColor) {
    final color = Color(
      int.parse(hexColor.substring(1), radix: 16) + 0xFF000000,
    );

    return InkWell(
      onTap: () => setState(() => _colorCtrl.text = hexColor),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _colorCtrl.text == hexColor
                ? Colors.white
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _colorCtrl.text == hexColor
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
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
                    widget.tarjeta != null
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.tarjeta != null
                        ? 'Guardar Cambios'
                        : 'Registrar Tarjeta',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final req = CreateTarjetaNfcRequest(
      cuentaId: _cuentaId,
      nombrePortador: _portadorCtrl.text.trim(),
      numeroTarjetaHash: _hashCtrl.text.trim(),
      tipo: _tipo,
      banco: _bancoCtrl.text.trim().isEmpty ? null : _bancoCtrl.text.trim(),
      color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
    );

    try {
      if (widget.tarjeta == null) {
        await ref.read(tarjetasNfcProvider.notifier).create(req);
      } else {
        await ref
            .read(tarjetasNfcProvider.notifier)
            .update(widget.tarjeta!.id, req.toJson());
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  widget.tarjeta != null
                      ? 'Tarjeta actualizada correctamente'
                      : 'Tarjeta registrada correctamente',
                ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _leerNfcYCompletar() async {
    setState(() => _isReadingNfc = true);

    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('NFC no está disponible en este dispositivo'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isReadingNfc = false);
        return;
      }

      String? uidHex;
      bool tagDetected = false;

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (tag) async {
          tagDetected = true;

          try {
            // En nfc_manager 4.1.1, tag.data es TagPigeon con propiedad 'id'
            final tagPigeon = tag.data as dynamic;

            // Extraer UID directamente de TagPigeon.id
            try {
              final id = tagPigeon.id;
              if (id != null) {
                final identifier = List<int>.from(id);
                uidHex = _convertListToHex(identifier);

                // Actualizar UI inmediatamente desde el callback
                if (mounted && uidHex != null && uidHex!.isNotEmpty) {
                  setState(() {
                    _hashCtrl.text = uidHex!;
                    _isReadingNfc = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Tarjeta leída correctamente'),
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
              }
            } catch (e) {
              // Error al extraer UID
            }
          } catch (e) {
            // Error en onDiscovered
          } finally {
            await NfcManager.instance.stopSession();
          }
        },
      );

      // Si no se detectó tarjeta o no se obtuvo UID, mostrar error
      if (!tagDetected || uidHex == null || uidHex!.isEmpty) {
        setState(() => _isReadingNfc = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No se pudo leer el UID de la tarjeta. Intenta de nuevo.',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      await NfcManager.instance.stopSession().catchError((_) {});
      setState(() => _isReadingNfc = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error al leer NFC: $e')),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String? _extractUid(Map data) {
    print('DEBUG: Buscando UID en la estructura del tag...');

    // Intento 1: Buscar directamente en nivel superior
    final direct = data['id'] ?? data['identifier'];
    if (direct is List) {
      print('DEBUG: UID encontrado en nivel superior (id/identifier)');
      return _convertListToHex(direct);
    }

    // Si viene como String directamente
    if (direct is String && direct.isNotEmpty) {
      print('DEBUG: UID encontrado como String en nivel superior');
      return direct.toUpperCase();
    }

    // Intento 2: Buscar en tecnologías específicas (orden de más común a menos común)
    const techs = [
      'nfca', // Android NFC-A (más común)
      'mifare', // MIFARE Classic/Ultralight
      'iso15693', // Tarjetas ISO 15693
      'nfcb', // NFC-B
      'nfcf', // NFC-F (FeliCa)
      'nfcv', // NFC-V (ISO 15693)
      'isoDep', // ISO-DEP (tarjetas EMV)
      'ndef', // NDEF
      'iso7816', // ISO 7816
      'felica', // FeliCa
      'mifareClassic',
      'mifareUltralight',
    ];

    for (final k in techs) {
      final m = data[k];
      if (m is Map) {
        print('DEBUG: Explorando tecnología: $k');
        print('DEBUG: Claves disponibles en $k: ${m.keys.toList()}');

        // Buscar identifier, id, uid
        final id = m['identifier'] ?? m['id'] ?? m['uid'] ?? m['atqa'];

        if (id is List) {
          print('DEBUG: UID encontrado en $k como List');
          return _convertListToHex(id);
        }

        if (id is String && id.isNotEmpty) {
          print('DEBUG: UID encontrado en $k como String');
          return id.toUpperCase();
        }
      }
    }

    // Intento 3: Búsqueda recursiva en toda la estructura
    print('DEBUG: Realizando búsqueda recursiva...');
    for (final entry in data.entries) {
      print('DEBUG: Explorando clave: ${entry.key}');
      final v = entry.value;

      if (v is Map) {
        final found = _extractUid(v);
        if (found != null) {
          print('DEBUG: UID encontrado recursivamente en ${entry.key}');
          return found;
        }
      }
    }

    print('DEBUG: No se pudo extraer UID de ninguna fuente');
    return null;
  }

  String _convertListToHex(List list) {
    try {
      return list
          .map((e) {
            // Manejar diferentes tipos de datos
            if (e is int) {
              return e.toRadixString(16).padLeft(2, '0');
            } else if (e is String) {
              return e;
            } else {
              return e.toString();
            }
          })
          .join('')
          .toUpperCase();
    } catch (e) {
      print('DEBUG: Error al convertir lista a hex: $e');
      return '';
    }
  }
}

// Custom painter para el patrón de fondo de la tarjeta
class CardPatternPainter extends CustomPainter {
  final Color color;

  CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Círculos decorativos
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 40, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.7), 30, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
