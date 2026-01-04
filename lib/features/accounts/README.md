# Feature de Cuentas - Flutter

Este módulo implementa la gestión completa de cuentas (bancarias, efectivo, wallets) en la aplicación Flutter.

## Estructura

```
features/accounts/
├── accounts_screen.dart         # Pantalla principal de cuentas
├── accounts_service.dart         # Servicio de API
├── accounts_provider.dart        # Providers y estado (Riverpod)
├── create_account_screen.dart    # Pantalla para crear cuentas
├── edit_account_screen.dart      # Pantalla para editar cuentas
└── README.md                      # Este archivo
```

## Características Implementadas

### ✅ Pantalla Principal de Cuentas
- **Vista de lista**: Muestra todas las cuentas con tarjetas visuales
- **Saldo actual**: Muestra el saldo calculado automáticamente (saldo_inicial + transacciones)
- **Filtros**: Filtra por tipo (Todas, Bancaria, Efectivo, Digital)
- **Pull to refresh**: Recarga las cuentas desde el servidor
- **Botón agregar**: Navega a la pantalla de creación
- **Indicador de saldo**: Color verde para positivo, rojo para negativo

### ✅ Pantallas de Creación/Edición
- **Formulario completo**: Campos para nombre, tipo, saldo inicial, color, icono, descripción
- **7 tipos de cuenta**: BANCARIA, EFECTIVO, TARJETA_CREDITO, TARJETA_DEBITO, DIGITAL, AHORRO, INVERSION
- **Selector visual de tipo**: Botones para todos los tipos
- **Paleta de colores**: 8 colores predefinidos con selección visual
- **Selector de iconos**: 8 iconos Material Design predefinidos
- **Vista previa**: Muestra cómo se verá la cuenta en tiempo real
- **Validación**: Validación de campos requeridos y formatos

### ✅ Funcionalidades
- ✅ Crear cuentas con saldo inicial
- ✅ Editar cuentas existentes
- ✅ Eliminar cuentas (con validación)
- ✅ Filtrar cuentas por tipo
- ✅ Cálculo automático de saldo actual
- ✅ Indicador visual de saldo positivo/negativo
- ✅ Pull to refresh
- ✅ Manejo de errores
- ✅ Estados de carga

## Navegación

Las cuentas se muestran en una **nueva pestaña** en la navegación inferior:

```
[Inicio] [Transacciones] [+] [Cuentas] [Categorías] [Perfil]
                          ↑
                     Nueva pestaña
```

## Modelos de Datos

### Cuenta
```dart
class Cuenta {
  final int id;
  final int usuarioId;
  final String nombre;
  final String tipo;
  final String moneda;
  final double saldoInicial;
  final String? color;
  final String? icono;
  final String? descripcion;
  final bool activa;
  final DateTime fechaCreacion;
  final double? saldoActual; // Calculado automáticamente
}
```

## Tipos de Cuentas Soportados

| Tipo | Descripción |
|------|-------------|
| `BANCARIA` | Cuenta bancaria tradicional |
| `EFECTIVO` | Efectivo físico |
| `TARJETA_CREDITO` | Tarjeta de crédito |
| `TARJETA_DEBITO` | Tarjeta de débito |
| `DIGITAL` | Wallet digital (PayPal, Venmo, etc.) |
| `AHORRO` | Cuenta de ahorros |
| `INVERSION` | Cuenta de inversión |

## Paleta de Colores Disponibles

1. 🟢 Verde (#10B981)
2. 🔵 Azul (#3B82F6)
3. 🟣 Morado (#8B5CF6)
4. 🩷 Rosa (#EC4899)
5. 🟠 Amarillo (#F59E0B)
6. 🔴 Rojo (#EF4444)
7. 🔵 Cian (#06B6D4)
8. 🔵 Índigo (#6366F1)

## Iconos Disponibles

- 🏦 account_balance - Banco
- 💼 account_balance_wallet - Billetera
- 💳 credit_card - Tarjeta
- 🏛️ savings - Ahorros
- 💰 wallet - Cartera
- 💸 payments - Pagos
- 📈 trending_up - Inversión
- 💵 attach_money - Dinero

## Cálculo de Saldo Actual

El saldo actual se calcula automáticamente en el backend:
```dart
saldo_actual = saldo_inicial + (suma de ingresos) - (suma de gastos)
```

## Estado de la Pantalla

### Estado Vacío
Muestra un mensaje cuando no hay cuentas y un botón para crear la primera.

### Estado de Carga
Muestra un `CircularProgressIndicator` mientras se cargan las cuentas.

### Estado de Error
Muestra un mensaje de error con un botón para reintentar.

### Estado con Datos
Muestra la lista de cuentas con sus respectivas tarjetas mostrando el saldo.

## Uso en la Aplicación

### Importar el provider:
```dart
import 'features/accounts/accounts_provider.dart';
```

### Leer cuentas:
```dart
final accountsAsync = ref.watch(accountsNotifierProvider);

accountsAsync.when(
  data: (accounts) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error),
);
```

### Crear una cuenta:
```dart
await ref.read(accountsNotifierProvider.notifier).createAccount(
  CreateCuentaRequest(
    nombre: 'Banco Nacional',
    tipo: 'BANCARIA',
    saldoInicial: 5000,
    color: '#10B981',
    icono: 'account_balance',
  ),
);
```

### Eliminar una cuenta:
```dart
await ref.read(accountsNotifierProvider.notifier).deleteAccount(cuentaId);
```

## Validaciones

- ✅ No se puede eliminar si tiene transacciones asociadas
- ✅ No se puede eliminar si tiene saldo diferente de cero
- ✅ El nombre es requerido
- ✅ El saldo inicial debe ser un número válido
- ✅ El saldo inicial no puede ser negativo

