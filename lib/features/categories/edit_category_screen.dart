import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category_models.dart';
import 'categories_provider.dart';

class EditCategoryScreen extends ConsumerStatefulWidget {
  final Categoria categoria;

  const EditCategoryScreen({super.key, required this.categoria});

  @override
  ConsumerState<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends ConsumerState<EditCategoryScreen> {
  late final TextEditingController _nombreController;
  late String _selectedTipo;
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
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.categoria.nombre);
    _selectedTipo = widget.categoria.tipo;
    _selectedColor = widget.categoria.color;
    _selectedIcono = widget.categoria.icono;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Categoría',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w300,
            color: Color(0xFF1F2937),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFD1FAE5).withOpacity(0.3), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vista previa
                _buildPreviewCard(),

                const SizedBox(height: 32),

                // Nombre de la categoría
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.category_outlined),
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

                const SizedBox(height: 32),

                // Tipo de categoría
                _buildSectionTitle('Tipo de Categoría'),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'INGRESO',
                      label: Text('Ingreso'),
                      icon: Icon(Icons.trending_up),
                    ),
                    ButtonSegment(
                      value: 'GASTO',
                      label: Text('Gasto'),
                      icon: Icon(Icons.trending_down),
                    ),
                    ButtonSegment(
                      value: 'AMBOS',
                      label: Text('Ambos'),
                      icon: Icon(Icons.swap_horiz),
                    ),
                  ],
                  selected: {_selectedTipo},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _selectedTipo = selection.first;
                    });
                  },
                ),

                const SizedBox(height: 32),

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

                const SizedBox(height: 32),

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
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF059669)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF059669,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
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
                    'Eliminar Categoría',
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
      ),
    );
  }

  Widget _buildPreviewCard() {
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

  void _handleUpdate() async {
    try {
      final request = UpdateCategoriaRequest(
        nombre: _nombreController.text.trim(),
        tipo: _selectedTipo,
        color: _selectedColor,
        icono: _selectedIcono,
      );

      await ref
          .read(categoriesNotifierProvider.notifier)
          .updateCategory(widget.categoria.id, request);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría actualizada exitosamente'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${_nombreController.text}"?\n\n'
          'Esta categoría no se podrá eliminar si tiene transacciones asociadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Cerrar diálogo de confirmación
              Navigator.of(context).pop(); // Cerrar pantalla de edición

              try {
                await ref
                    .read(categoriesNotifierProvider.notifier)
                    .deleteCategory(widget.categoria.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Categoría eliminada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
    if (icono == null) return Icons.category;
    switch (icono) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'checkroom':
        return Icons.checkroom;
      case 'home':
        return Icons.home;
      case 'receipt':
        return Icons.receipt;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'work':
        return Icons.work;
      case 'computer':
        return Icons.computer;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }

  Color _getTypeColor(String tipo) {
    switch (tipo) {
      case 'INGRESO':
        return Colors.green;
      case 'GASTO':
        return Colors.red;
      case 'AMBOS':
        return Colors.orange;
      default:
        return Colors.grey;
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
