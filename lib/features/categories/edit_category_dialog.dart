import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category_models.dart';
import 'categories_provider.dart';

class EditCategoryDialog extends ConsumerStatefulWidget {
  final Categoria categoria;

  const EditCategoryDialog({super.key, required this.categoria});

  @override
  ConsumerState<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends ConsumerState<EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late String _selectedTipo;
  String? _color;
  String? _icono;

  final List<Map<String, dynamic>> _colores = [
    {'color': '#FF6B6B', 'name': 'Rojo'},
    {'color': '#4ECDC4', 'name': 'Cian'},
    {'color': '#45B7D1', 'name': 'Azul'},
    {'color': '#FFA07A', 'name': 'Coral'},
    {'color': '#98D8C8', 'name': 'Verde'},
    {'color': '#F7DC6F', 'name': 'Amarillo'},
    {'color': '#BB8FCE', 'name': 'Morado'},
    {'color': '#85C1E2', 'name': 'Celeste'},
    {'color': '#10B981', 'name': 'Verde'},
    {'color': '#6366F1', 'name': 'Índigo'},
    {'color': '#8B5CF6', 'name': 'Violeta'},
    {'color': '#EC4899', 'name': 'Rosa'},
  ];

  final List<Map<String, dynamic>> _iconos = [
    {'icon': 'restaurant', 'label': 'Restaurante'},
    {'icon': 'directions_car', 'label': 'Auto'},
    {'icon': 'local_hospital', 'label': 'Hospital'},
    {'icon': 'school', 'label': 'Educación'},
    {'icon': 'sports_esports', 'label': 'Entretenimiento'},
    {'icon': 'checkroom', 'label': 'Ropa'},
    {'icon': 'home', 'label': 'Casa'},
    {'icon': 'receipt', 'label': 'Factura'},
    {'icon': 'shopping_cart', 'label': 'Compras'},
    {'icon': 'work', 'label': 'Trabajo'},
    {'icon': 'computer', 'label': 'Computadora'},
    {'icon': 'trending_up', 'label': 'Inversión'},
    {'icon': 'card_giftcard', 'label': 'Regalo'},
    {'icon': 'attach_money', 'label': 'Dinero'},
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.categoria.nombre);
    _selectedTipo = widget.categoria.tipo;
    _color = widget.categoria.color;
    _icono = widget.categoria.icono;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Categoría'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Seleccionar tipo
              const Text(
                'Tipo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'INGRESO', label: Text('Ingreso')),
                  ButtonSegment(value: 'GASTO', label: Text('Gasto')),
                  ButtonSegment(value: 'AMBOS', label: Text('Ambos')),
                ],
                selected: {_selectedTipo},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _selectedTipo = selection.first;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Seleccionar color
              const Text(
                'Color',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colores.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final colorData = _colores[index];
                    final isSelected = _color == colorData['color'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _color = colorData['color'] as String;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _parseColor(colorData['color'] as String),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Seleccionar icono
              const Text(
                'Icono',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconos.map((iconData) {
                  final isSelected = _icono == iconData['icon'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _icono = iconData['icon'] as String;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF059669)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF059669)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getIcon(iconData['icon'] as String),
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final request = UpdateCategoriaRequest(
        nombre: _nombreController.text.trim(),
        tipo: _selectedTipo,
        color: _color,
        icono: _icono,
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
  }

  IconData _getIcon(String icono) {
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

  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
