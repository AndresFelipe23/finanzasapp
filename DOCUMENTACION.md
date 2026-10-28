# Financially — Documentación de la App

## Objetivo

**Financially** es una aplicación de gestión financiera personal diseñada para ayudar a los usuarios a controlar sus ingresos, gastos, cuentas, metas de ahorro, presupuestos y préstamos en un solo lugar.

La app consume una API REST construida con **NestJS** + **SQL Server**, donde toda la lógica de negocio reside en **stored procedures**.

---

## Funcionalidades Actuales

### 1. Autenticación
- Registro de usuario (nombre, email, password, teléfono, fecha de nacimiento, moneda predeterminada)
- Inicio de sesión con JWT
- Cierre de sesión
- Token almacenado de forma segura con `flutter_secure_storage`

### 2. Dashboard / Inicio
- Saludo personalizado según la hora del día
- Resumen del balance del mes actual (ingresos vs gastos)
- Tarjetas de cuentas con saldo animado
- Últimos movimientos (top 5)
- Indicador de metas y resumen general

### 3. Transacciones
- **Crear** ingresos, gastos y transferencias entre cuentas
- **Listar** agrupado por fecha (Hoy, Ayer, fecha específica)
- **Ver detalle** en modal bottom sheet (cuenta, categoría, método de pago, monto, descripción, notas)
- **Soporte para 18 monedas** de países de habla hispana
- Formato de moneda en pesos colombianos (`$`)
- Pull-to-refresh para recargar datos

### 4. Cuentas
- **CRUD completo** de cuentas bancarias y de efectivo
- Tipos: `BANCARIA` y `EFECTIVO`
- Cada cuenta tiene: nombre, tipo, saldo inicial, saldo actual, moneda y color personalizable
- Resumen de cuentas con estadísticas
- Validación: no permite eliminar cuentas con saldo o transacciones activas

### 5. Categorías
- **CRUD completo** de categorías para clasificar transacciones
- Asociadas a tipo de transacción (INGRESO/GASTO)
- Cada categoría tiene: nombre, ícono, color y tipo asociado

### 6. Metas de Ahorro
- **CRUD completo** de metas financieras
- Seguimiento de progreso con barra de progreso y porcentaje
- **Aportes** a metas (registrar abonos)
- Estados: Activa, Pausada, Completada, Vencida
- Filtros: Activas, Completadas, Todas
- Indicador de días restantes hasta la fecha objetivo
- Animaciones de entrada en las tarjetas

### 7. Presupuestos
- **CRUD completo** de presupuestos por período (Semanal, Mensual, Anual)
- Seguimiento de gasto vs límite con barra de progreso
- Estados: Dentro del límite, Sobrepasado, Pausado
- Filtros: Activos, Pausados, Sobrepasados, Todos
- Resumen general con total límite, gastado y disponible
- Alertas visuales al superar el 75% y 90% del límite
- Pausar/Reanudar presupuesto

### 8. Préstamos
- **CRUD completo** de préstamos (deudas y créditos)
- Tipos: `DEUDA` (yo debo) y `PRESTAMO` (me deben)
- Seguimiento de saldo pendiente vs monto total
- **Registro de pagos** con abono a capital
- Soporte para tasa de interés
- Estados: Activo, Pausado, Completado, Pagado
- Filtros: Activos, Pausados, Pagados, Completados, Todos
- Resumen KPI con total pendiente, desglose de deudas y créditos

### 9. Pagos Recurrentes
- Servicio backend para gestión de pagos recurrentes (sin UI por ahora)
- Programación automática vía scheduler

### 10. Perfil
- Visualización de información del usuario
- Opciones de configuración personal

---

## Funcionalidades Deshabilitadas (NFC)

El código existe pero está **comentado en la navegación**. No modificar ni eliminar — mantener para futura reactivación:

- **Tarjetas NFC**: gestión de tarjetas para pagos sin contacto
- **Pagos NFC**: realizar pagos y ver historial de transacciones NFC
- **Dispositivos NFC**: registro de dispositivos compatibles

---

## Stack Técnico

| Capa           | Tecnología                                   |
|----------------|----------------------------------------------|
| Frontend       | Flutter + Dart 3.9                           |
| Estado         | Riverpod (flutter_riverpod)                  |
| HTTP           | Dio (con interceptors JWT + logging)         |
| Navegación     | persistent_bottom_nav_bar + Drawer           |
| Diseño         | NeoBankTheme (Plus Jakarta Sans, Material 3) |
| Backend        | NestJS 11 + TypeScript 5                     |
| Base de datos  | SQL Server (stored procedures)               |
| Auth           | JWT + bcrypt                                 |
| Tiempo         | America/Bogota (UTC-5)                       |
| Producción     | gestiondinero.site                           |

### Dependencias principales (Flutter)

| Paquete                    | Versión   | Uso                          |
|----------------------------|-----------|------------------------------|
| flutter_riverpod           | ^2.6.1    | State management             |
| dio                        | ^5.7.0    | HTTP client                  |
| flutter_secure_storage     | ^9.2.2    | Token storage                |
| persistent_bottom_nav_bar  | ^6.2.1    | Bottom navigation            |
| google_fonts               | ^6.2.1    | Plus Jakarta Sans            |
| fl_chart                   | ^0.69.0   | Gráficos                     |
| intl                       | ^0.20.2   | Formato fechas/monedas       |
| flutter_dotenv             | ^5.1.0    | Variables de entorno         |
| lottie                     | ^3.1.2    | Animaciones                  |
| nfc_manager                | ^4.1.1    | NFC (deshabilitado)          |
| device_info_plus           | ^11.1.0   | Info del dispositivo         |

---

## Arquitectura (Flutter)

```
lib/
├── core/          # Infraestructura compartida
│   ├── api/       # ApiClient (Dio + JWT)
│   ├── config/    # AppConfig (URLs, timeouts)
│   ├── models/    # Modelos compartidos
│   ├── navigation/# MainNavigation (4 tabs + drawer)
│   ├── theme/     # NeoBankTheme (design system)
│   └── utils/     # Helpers (iconos, monedas)
│
└── features/      # Módulos funcionales
    ├── accounts/  # provider + service + screen
    ├── auth/      # service + screen
    ├── categories/# provider + service + screen + dialog
    ├── home/      # screen
    ├── metas/     # provider + service + screen + dialog
    ├── prestamos/ # provider + service + screen + dialog
    ├── presupuestos/ # provider + service + screen
    └── transactions/ # provider + service + screen
```

### Patrón por feature
- `*_provider.dart` — Riverpod providers (servicio, estado, notificadores)
- `*_service.dart` — Comunicación con la API (captura DioException)
- `*_screen.dart` — UI con ConsumerWidget/ConsumerStatefulWidget
- Todos los providers retornan `AsyncValue<T>` para usar `.when(data:, loading:, error:)`
- `apiClientProvider` se define en `categories_provider.dart` y se reusa globalmente
