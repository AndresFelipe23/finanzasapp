import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/meta_models.dart';
import 'metas_provider.dart';

class CreateMetaScreen extends ConsumerStatefulWidget {
  final Meta? metaToEdit;

  const CreateMetaScreen({super.key, this.metaToEdit});

  @override
  ConsumerState<CreateMetaScreen> createState() => _CreateMetaScreenState();
}

class _CreateMetaScreenState extends ConsumerState<CreateMetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _montoObjetivoController = TextEditingController();
  DateTime _fechaObjetivo = DateTime.now().add(const Duration(days: 30));
  String? _selectedColor;
  String? _selectedIcono;

  // Paleta de colores
  final List<ColorOption> _colores = [
    ColorOption('#3B82F6', 'Azul', Colors.blue),
    ColorOption('#10B981', 'Verde', Colors.green),
    ColorOption('#8B5CF6', 'Morado', Colors.purple),
    ColorOption('#EC4899', 'Rosa', Colors.pink),
    ColorOption('#F59E0B', 'Amarillo', Colors.orange),
    ColorOption('#EF4444', 'Rojo', Colors.red),
    ColorOption('#06B6D4', 'Cian', Colors.cyan),
    ColorOption('#6366F1', 'Índigo', Colors.indigo),
  ];

  // Iconos disponibles
  final List<IconOption> _iconos = [
    IconOption('flag', 'Meta', Icons.flag_rounded),
    IconOption('home', 'Casa', Icons.home_rounded),
    IconOption('directions_car', 'Auto', Icons.directions_car_rounded),
    IconOption('flight', 'Viaje', Icons.flight_rounded),
    IconOption('shopping_bag', 'Compras', Icons.shopping_bag_rounded),
    IconOption('school', 'Educación', Icons.school_rounded),
    IconOption('favorite', 'Salud', Icons.favorite_rounded),
    IconOption('savings', 'Ahorros', Icons.savings_rounded),
    IconOption('work', 'Trabajo', Icons.work_rounded),
    IconOption('celebration', 'Celebración', Icons.celebration_rounded),
    IconOption('star', 'Estrella', Icons.star_rounded),
    IconOption('card_giftcard', 'Regalo', Icons.card_giftcard_rounded),
    IconOption('beach_access', 'Vacaciones', Icons.beach_access_rounded),
    IconOption('fitness_center', 'Fitness', Icons.fitness_center_rounded),
    IconOption('restaurant', 'Restaurante', Icons.restaurant_rounded),
    IconOption('music_note', 'Música', Icons.music_note_rounded),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.metaToEdit != null) {
      final meta = widget.metaToEdit!;
      _nombreController.text = meta.nombre;
      _descripcionController.text = meta.descripcion ?? '';
      _montoObjetivoController.text = meta.montoObjetivo.toStringAsFixed(0);
      _fechaObjetivo = meta.fechaObjetivo;
      _selectedColor = meta.color;
      _selectedIcono = meta.icono;
    } else {
      // Valores por defecto para nueva meta
      _selectedColor = _colores[0].hex;
      _selectedIcono = _iconos[0].key;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _montoObjetivoController.dispose();
    super.dispose();
  }

  Color _getSelectedColor() {
    if (_selectedColor == null) return const Color(0xFF3B82F6);
    try {
      return Color(int.parse(_selectedColor!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF3B82F6);
    }
  }

  bool get isEdit => widget.metaToEdit != null;

  @override
  Widget build(BuildContext context) {
    final selectedColor = _getSelectedColor();
    final formatoMoneda = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final montoObjetivo = double.tryParse(_montoObjetivoController.text) ?? 0.0;
    final diasRestantes = _fechaObjetivo.difference(DateTime.now()).inDays;

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
          isEdit ? 'Editar Meta' : 'Nueva Meta',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vista previa
              _buildPreviewCard(selectedColor, formatoMoneda, montoObjetivo, diasRestantes),
              const SizedBox(height: 24),
              // Información básica
              const Text(
                'Información básica',
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
                  labelText: 'Nombre de la meta *',
                  hintText: 'Ej: Viaje a Europa',
                  prefixIcon: Icon(
                    _selectedIcono != null
                        ? _getIconData(_selectedIcono!)
                        : Icons.flag_rounded,
                    color: selectedColor,
                  ),
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
                    borderSide: BorderSide(color: selectedColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Describe tu meta...',
                  prefixIcon: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF6B7280),
                  ),
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
                    borderSide: BorderSide(color: selectedColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Monto y fecha
              const Text(
                'Objetivo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoObjetivoController,
                decoration: InputDecoration(
                  labelText: 'Monto objetivo *',
                  hintText: '0',
                  prefixIcon: Icon(
                    Icons.attach_money_rounded,
                    color: selectedColor,
                  ),
                  suffixText: 'COP',
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
                    borderSide: BorderSide(color: selectedColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El monto objetivo es requerido';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null || monto <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaObjetivo,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (fecha != null) {
                    setState(() {
                      _fechaObjetivo = fecha;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: selectedColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha objetivo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_fechaObjetivo),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Personalización
              const Text(
                'Personalización',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colores.map((color) {
                  final isSelected = _selectedColor == color.hex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color.hex;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : Border.all(color: Colors.grey[300]!, width: 2),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.color.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Icono',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _iconos.map((icono) {
                  final isSelected = _selectedIcono == icono.key;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcono = icono.key;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: selectedColor, width: 2)
                            : Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: selectedColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icono.iconData,
                        color: isSelected ? selectedColor : const Color(0xFF6B7280),
                        size: 26,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // Botón crear
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
                          colors: [
                            selectedColor.withOpacity(0.8),
                            selectedColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: selectedColor.withOpacity(0.3),
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
                          isEdit ? 'Guardar Cambios' : 'Crear Meta',
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

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final request = CreateMetaRequest(
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        montoObjetivo: double.parse(_montoObjetivoController.text),
        fechaObjetivo: _fechaObjetivo,
        color: _selectedColor,
        icono: _selectedIcono,
      );

      if (widget.metaToEdit != null) {
        await ref
            .read(metasNotifierProvider.notifier)
            .updateMeta(widget.metaToEdit!.id, request);
      } else {
        await ref.read(metasNotifierProvider.notifier).create(request);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEdit
                        ? 'Meta actualizada exitosamente'
                        : 'Meta creada exitosamente',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildPreviewCard(
    Color color,
    NumberFormat formato,
    double montoObjetivo,
    int diasRestantes,
  ) {
    final nombre = _nombreController.text.isEmpty
        ? 'Vista previa'
        : _nombreController.text;
    final monto = montoObjetivo > 0
        ? formato.format(montoObjetivo)
        : '0';
    
    // Información de la meta original si se está editando
    final metaOriginal = widget.metaToEdit;
    final montoActual = metaOriginal?.montoActual ?? 0.0;
    final porcentaje = montoObjetivo > 0 
        ? (montoActual / montoObjetivo * 100).clamp(0, 100)
        : 0.0;
    final estaCompletada = montoActual >= montoObjetivo;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit ? 'Editando Meta' : 'Vista Previa',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isEdit ? color : const Color(0xFF6B7280),
                ),
              ),
              if (isEdit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Modo edición',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
            ],
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
              _selectedIcono != null
                  ? _getIconData(_selectedIcono!)
                  : Icons.flag_rounded,
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
            monto,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (isEdit && metaOriginal != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progreso actual',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '${porcentaje.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: estaCompletada
                              ? const Color(0xFF10B981)
                              : color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: porcentaje / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        estaCompletada ? const Color(0xFF10B981) : color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ahorrado',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            formato.format(montoActual),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: estaCompletada
                                  ? const Color(0xFF10B981)
                                  : color,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Faltante',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            formato.format((montoObjetivo - montoActual).clamp(0, double.infinity)),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: estaCompletada
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (diasRestantes > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$diasRestantes días restantes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ] else if (diasRestantes <= 0 && !isEdit) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Fecha vencida',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'flag': Icons.flag_rounded,
      'home': Icons.home_rounded,
      'directions_car': Icons.directions_car_rounded,
      'flight': Icons.flight_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'school': Icons.school_rounded,
      'favorite': Icons.favorite_rounded,
      'savings': Icons.savings_rounded,
      'work': Icons.work_rounded,
      'celebration': Icons.celebration_rounded,
      'star': Icons.star_rounded,
      'card_giftcard': Icons.card_giftcard_rounded,
      'beach_access': Icons.beach_access_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'restaurant': Icons.restaurant_rounded,
      'music_note': Icons.music_note_rounded,
    };
    return iconMap[iconName] ?? Icons.flag_rounded;
  }
}

class ColorOption {
  final String hex;
  final String name;
  final Color color;

  ColorOption(this.hex, this.name, this.color);
}

class IconOption {
  final String key;
  final String name;
  final IconData iconData;

  IconOption(this.key, this.name, this.iconData);
}
