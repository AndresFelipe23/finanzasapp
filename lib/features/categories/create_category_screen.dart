import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category_models.dart';
import 'categories_provider.dart';

class CreateCategoryScreen extends ConsumerStatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  ConsumerState<CreateCategoryScreen> createState() =>
      _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends ConsumerState<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  String _selectedTipo = 'GASTO';
  String? _selectedColor;
  String? _selectedIcono;

  // Paleta de colores
  final List<ColorOption> _colores = [
    ColorOption('#FF6B6B', 'Rojo', Icons.circle, Colors.red),
    ColorOption('#4ECDC4', 'Cian', Icons.circle, Colors.cyan),
    ColorOption('#45B7D1', 'Azul', Icons.circle, Colors.blue),
    ColorOption('#FFA07A', 'Coral', Icons.circle, Colors.orange),
    ColorOption('#98D8C8', 'Verde menta', Icons.circle, Colors.teal),
    ColorOption('#F7DC6F', 'Amarillo', Icons.circle, Colors.yellow),
    ColorOption('#BB8FCE', 'Morado', Icons.circle, Colors.purple),
    ColorOption('#85C1E2', 'Celeste', Icons.circle, Colors.lightBlue),
    ColorOption('#10B981', 'Verde', Icons.circle, Colors.green),
    ColorOption('#6366F1', 'Índigo', Icons.circle, Colors.indigo),
    ColorOption('#8B5CF6', 'Violeta', Icons.circle, Colors.deepPurple),
    ColorOption('#EC4899', 'Rosa', Icons.circle, Colors.pink),
  ];

  // Iconos disponibles
  final List<IconOption> _iconos = [
    IconOption('restaurant', 'Alimentación', Icons.restaurant),
    IconOption('directions_car', 'Transporte', Icons.directions_car),
    IconOption('local_hospital', 'Salud', Icons.local_hospital),
    IconOption('school', 'Educación', Icons.school),
    IconOption('sports_esports', 'Entretenimiento', Icons.sports_esports),
    IconOption('checkroom', 'Ropa', Icons.checkroom),
    IconOption('home', 'Hogar', Icons.home),
    IconOption('receipt', 'Facturas', Icons.receipt),
    IconOption('shopping_cart', 'Compras', Icons.shopping_cart),
    IconOption('work', 'Trabajo', Icons.work),
    IconOption('computer', 'Tecnología', Icons.computer),
    IconOption('trending_up', 'Inversiones', Icons.trending_up),
    IconOption('card_giftcard', 'Regalo', Icons.card_giftcard),
    IconOption('attach_money', 'Dinero', Icons.attach_money),
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Nueva Categoría',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview de la categoría
              _buildPreviewCard(),

              const SizedBox(height: 32),

              // Nombre de la categoría
              _buildSectionTitle('Nombre'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la categoría',
                  hintText: 'Ej: Alimentación, Transporte',
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
                    borderSide: const BorderSide(
                      color: Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF10B981),
                  ),
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                ),
                onChanged: (value) => setState(() {}),
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

              const SizedBox(height: 32),

              // Tipo de categoría
              _buildSectionTitle('Tipo de Categoría'),
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
                    _buildTypeChip('INGRESO', 'Ingreso', Icons.arrow_upward_rounded, const Color(0xFF10B981)),
                    _buildTypeChip('GASTO', 'Gasto', Icons.arrow_downward_rounded, const Color(0xFFEF4444)),
                    _buildTypeChip('AMBOS', 'Ambos', Icons.swap_vert_rounded, const Color(0xFFF59E0B)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Color
              _buildSectionTitle('Elige un Color'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
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
                          gradient: LinearGradient(
                            colors: [
                              color.actualColor.withOpacity(0.8),
                              color.actualColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.actualColor.withOpacity(isSelected ? 0.5 : 0.2),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 28,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),

              // Icono
              _buildSectionTitle('Elige un Icono'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _iconos.length,
                  itemBuilder: (context, index) {
                    final icono = _iconos[index];
                    final isSelected = _selectedIcono == icono.value;
                    final categoryColor = _getPreviewColor();

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
                              ? LinearGradient(
                                  colors: [
                                    categoryColor.withOpacity(0.8),
                                    categoryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? categoryColor
                                : const Color(0xFFE5E7EB),
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: categoryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icono.icon,
                          color: isSelected ? Colors.white : const Color(0xFF6B7280),
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),

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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                      child: ElevatedButton(
                        onPressed: _handleCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Crear Categoría',
                          style: TextStyle(
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

  Widget _buildPreviewCard() {
    final previewColor = _getPreviewColor();
    final previewIcon = _getPreviewIcon();
    final previewName = _nombreController.text.isEmpty
        ? 'Vista Previa'
        : _nombreController.text;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: previewColor.withOpacity(0.15),
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
                colors: [
                  previewColor.withOpacity(0.8),
                  previewColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: previewColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              previewIcon,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            previewName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getTypeColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTypeIcon(),
                  size: 16,
                  color: _getTypeColor(),
                ),
                const SizedBox(width: 6),
                Text(
                  _getTypeLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon, Color color) {
    final isSelected = _selectedTipo == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTipo = value;
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
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
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

  Color _getPreviewColor() {
    if (_selectedColor == null) return const Color(0xFF6B7280);
    try {
      return Color(int.parse(_selectedColor!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6B7280);
    }
  }

  IconData _getPreviewIcon() {
    if (_selectedIcono == null) return Icons.category_rounded;
    final iconOption = _iconos.firstWhere(
      (i) => i.value == _selectedIcono,
      orElse: () => _iconos[0],
    );
    return iconOption.icon;
  }

  Color _getTypeColor() {
    switch (_selectedTipo) {
      case 'INGRESO':
        return const Color(0xFF10B981);
      case 'GASTO':
        return const Color(0xFFEF4444);
      case 'AMBOS':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (_selectedTipo) {
      case 'INGRESO':
        return Icons.arrow_upward_rounded;
      case 'GASTO':
        return Icons.arrow_downward_rounded;
      case 'AMBOS':
        return Icons.swap_vert_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getTypeLabel() {
    switch (_selectedTipo) {
      case 'INGRESO':
        return 'Ingreso';
      case 'GASTO':
        return 'Gasto';
      case 'AMBOS':
        return 'Ambos';
      default:
        return _selectedTipo;
    }
  }

  void _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final request = CreateCategoriaRequest(
        nombre: _nombreController.text.trim(),
        tipo: _selectedTipo,
        color: _selectedColor,
        icono: _selectedIcono,
      );

      await ref
          .read(categoriesNotifierProvider.notifier)
          .createCategory(request);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría creada exitosamente'),
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
  final IconData iconData;
  final Color actualColor;

  ColorOption(this.value, this.name, this.iconData, this.actualColor);
}

class IconOption {
  final String value;
  final String label;
  final IconData icon;

  IconOption(this.value, this.label, this.icon);
}
