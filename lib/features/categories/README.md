# Feature de Categorías - Flutter

Este módulo implementa la gestión completa de categorías en la aplicación Flutter.

## Estructura

```
features/categories/
├── categories_screen.dart        # Pantalla principal de categorías
├── categories_service.dart       # Servicio de API
├── categories_provider.dart      # Providers y estado (Riverpod)
├── category_form_screen.dart     # Crear y editar categorías (con presupuesto opcional)
├── category_style.dart           # Íconos y paleta de colores compartidos
└── README.md                     # Este archivo
```

## Características Implementadas

### ✅ Pantalla Principal de Categorías
- **Vista de lista**: Muestra todas las categorías organizadas por tarjetas
- **Filtros**: Filtra por tipo (Todas, Ingresos, Gastos)
- **Pull to refresh**: Recarga las categorías desde el servidor
- **Navegación**: Botón para agregar nueva categoría
- **Acciones**: Menú contextual para editar o eliminar

### ✅ Diálogos de Creación/Edición
- **Formulario**: Campos para nombre, tipo, color e icono
- **Selector de tipo**: Botones segmentados para INGRESO/GASTO/AMBOS
- **Paleta de colores**: 12 colores predefinidos con selección visual
- **Selector de iconos**: 14 iconos Material Design predefinidos
- **Validación**: Validación de campos requeridos

### ✅ Funcionalidades
- ✅ Crear categorías personalizadas
- ✅ Editar categorías existentes
- ✅ Eliminar categorías (con validación)
- ✅ Filtrar categorías por tipo
- ✅ Selector de colores
- ✅ Selector de iconos
- ✅ Pull to refresh
- ✅ Manejo de errores
- ✅ Estados de carga

## Modelos de Datos

### Categoria
```dart
class Categoria {
  final int id;
  final int? usuarioId;
  final String nombre;
  final String? icono;
  final String? color;
  final String tipo; // 'INGRESO', 'GASTO', 'AMBOS'
  final bool activo;
  final DateTime fechaCreacion;
}
```

### CreateCategoriaRequest
```dart
class CreateCategoriaRequest {
  final String nombre;
  final String? icono;
  final String? color;
  final String? tipo;
}
```

### UpdateCategoriaRequest
```dart
class UpdateCategoriaRequest {
  final String? nombre;
  final String? icono;
  final String? color;
  final String? tipo;
  final bool? activo;
}
```

## Endpoints de API

La aplicación consume los siguientes endpoints:

- `GET /api/categorias` - Obtiene todas las categorías
- `GET /api/categorias?tipo=GASTO` - Filtra por tipo
- `GET /api/categorias/:id` - Obtiene una categoría por ID
- `POST /api/categorias` - Crea una nueva categoría
- `PATCH /api/categorias/:id` - Actualiza una categoría
- `DELETE /api/categorias/:id` - Elimina una categoría
- `GET /api/categorias/summary` - Obtiene estadísticas de uso
- `POST /api/categorias/default` - Crea categorías predeterminadas

## Providers (Riverpod)

### categoriesNotifierProvider
Provider principal que maneja todas las operaciones de categorías.

**Uso:**
```dart
final categoriesAsync = ref.watch(categoriesNotifierProvider);

categoriesAsync.when(
  data: (categories) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### Operaciones disponibles:
- `createCategory(CreateCategoriaRequest)` - Crea una categoría
- `updateCategory(int id, UpdateCategoriaRequest)` - Actualiza una categoría
- `deleteCategory(int id)` - Elimina una categoría
- `refresh()` - Recarga la lista
- `createDefaultCategories()` - Crea categorías predeterminadas

## Componentes Visuales

### Category Card
Cada categoría se muestra en una tarjeta con:
- Icono con color personalizado
- Nombre de la categoría
- Badge con el tipo (INGRESO/GASTO/AMBOS)
- Menú de acciones (editar/eliminar)

### Filter Chips
Botones segmentados para filtrar por tipo:
- **Todas**: Muestra todas las categorías
- **Ingresos**: Solo categorías de tipo INGRESO
- **Gastos**: Solo categorías de tipo GASTO

## Paleta de Colores Disponibles

1. 🔴 Rojo (#FF6B6B)
2. 🟢 Cian (#4ECDC4)
3. 🔵 Azul (#45B7D1)
4. 🟠 Coral (#FFA07A)
5. 🟢 Verde (#98D8C8)
6. 🟡 Amarillo (#F7DC6F)
7. 🟣 Morado (#BB8FCE)
8. 🔵 Celeste (#85C1E2)
9. 🟢 Verde Esmeralda (#10B981)
10. 🔵 Índigo (#6366F1)
11. 🟣 Violeta (#8B5CF6)
12. 🩷 Rosa (#EC4899)

## Iconos Disponibles

- 🍽️ restaurant - Restaurante
- 🚗 directions_car - Auto
- 🏥 local_hospital - Hospital
- 🎓 school - Educación
- 🎮 sports_esports - Entretenimiento
- 👔 checkroom - Ropa
- 🏠 home - Casa
- 🧾 receipt - Factura
- 🛒 shopping_cart - Compras
- 💼 work - Trabajo
- 💻 computer - Computadora
- 📈 trending_up - Inversión
- 🎁 card_giftcard - Regalo
- 💰 attach_money - Dinero

## Uso en la Aplicación

### Importar el provider:
```dart
import 'features/categories/categories_provider.dart';
```

### Leer categorías:
```dart
final categoriesAsync = ref.watch(categoriesNotifierProvider);

categoriesAsync.when(
  data: (categories) => YourWidget(categories: categories),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error),
);
```

### Crear una categoría:
```dart
await ref.read(categoriesNotifierProvider.notifier).createCategory(
  CreateCategoriaRequest(
    nombre: 'Alimentación',
    tipo: 'GASTO',
    color: '#FF6B6B',
    icono: 'restaurant',
  ),
);
```

### Eliminar una categoría:
```dart
await ref.read(categoriesNotifierProvider.notifier).deleteCategory(categoriaId);
```

## Estados de la Pantalla

### Estado Vacío
Muestra un mensaje cuando no hay categorías y un botón para crear la primera.

### Estado de Carga
Muestra un `CircularProgressIndicator` mientras se cargan las categorías.

### Estado de Error
Muestra un mensaje de error con un botón para reintentar.

### Estado con Datos
Muestra la lista de categorías con sus respectivas tarjetas.

## Notas de Implementación

⚠️ **Nota**: El backend actualmente tiene el `usuarioId` hardcodeado a 1. Una vez que se implemente el JWT guard en el backend, el frontend automáticamente enviará el token correcto a través del interceptor de Dio configurado en `ApiClient`.

## Próximos Pasos

1. Integrar con sistema de autenticación real (JWT)
2. Agregar estadísticas de uso de categorías
3. Implementar búsqueda de categorías
4. Agregar categorías favoritas
5. Implementar ordenamiento por nombre o por uso

