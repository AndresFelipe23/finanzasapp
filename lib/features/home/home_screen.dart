import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/auth_models.dart';
import '../transactions/transactions_provider.dart' as tprov;
import '../accounts/accounts_provider.dart';
// Import deshabilitado (comentado pero no eliminado para futura reactivación)
// import '../presupuestos/presupuestos_screen.dart' show PresupuestosScreen;
// import '../pagos_nfc/pagar_con_nfc_screen.dart' show PagarConNfcScreen;

class HomeScreen extends ConsumerStatefulWidget {
  final UserResponse user;
  final VoidCallback? openDrawer;

  const HomeScreen({super.key, required this.user, this.openDrawer});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono de la app
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                // Nombre de la app
                const Text(
                  'Financially',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Versión
                Text(
                  'Versión 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                // Descripción
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 20,
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Sobre la App',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aplicación de gestión financiera personal diseñada para ayudarte a controlar tus ingresos, gastos y metas financieras de manera sencilla y eficiente.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Información del creador
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Desarrollador',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Desarrollado por AFESDEV',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'afesdev2025@gmail.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Botón de cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM');
    final money = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final cuentasAsync = ref.watch(accountsNotifierProvider);
    final transAsync = ref.watch(tprov.transactionsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // AppBar con gradiente moderno
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            color: Colors.white,
                            iconSize: 24,
                            onPressed: widget.openDrawer,
                            tooltip: 'Menú',
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, ${widget.user.nombre.split(' ').first}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                DateFormat('EEEE, d MMMM', 'es_ES').format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAppInfoDialog(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Contenido
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(accountsNotifierProvider.notifier).refresh();
                await ref.read(tprov.transactionsNotifierProvider.notifier).refresh();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Resumen del mes
                    _ResumenMes(transAsync: transAsync),

                    const SizedBox(height: 24),
                    _sectionTitle('Mis Cuentas', Icons.account_balance_wallet),
                    const SizedBox(height: 12),
                    cuentasAsync.when(
                      data: (cuentas) {
                        if (cuentas.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'No tienes cuentas registradas',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          );
                        }
                        return SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (_, i) {
                              final c = cuentas[i];
                              return _CuentaCard(
                                nombre: c.nombre,
                                saldo: c.saldoActual ?? c.saldoInicial,
                                moneda: c.moneda,
                                colorHex: c.color,
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemCount: cuentas.length,
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('Error al cargar cuentas: $e'),
                      ),
                    ),

                    // Sección "Accesos Rápidos" deshabilitada
                    /*
                    const SizedBox(height: 24),
                    _sectionTitle('Accesos Rápidos', Icons.flash_on),
                    const SizedBox(height: 12),
                    // ============================================
                    // FUNCIONALIDAD NFC DESHABILITADA
                    // (Comentada pero no eliminada para futura reactivación)
                    // ============================================
                    // _Accesos(
                    //   onNfc: () {
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(builder: (_) => const PagarConNfcScreen()),
                    //     );
                    //   },
                    //   onPresupuestos: () {
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(builder: (_) => const PresupuestosScreen()),
                    //     );
                    //   },
                    // ),
                    // Mostrar solo el botón de Presupuestos
                    Row(
                      children: [
                        Expanded(
                          child: _AccesoCard(
                            icon: Icons.assessment,
                            label: 'Presupuestos',
                            color: const Color(0xFF8B5CF6),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PresupuestosScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Espacio vacío donde estaba el botón NFC
                        Expanded(
                          child: Container(),
                        ),
                      ],
                    ),
                    */

                    const SizedBox(height: 24),
                    _sectionTitle('Últimos Movimientos', Icons.history),
                    const SizedBox(height: 12),
                    _UltimosMovimientos(transAsync: transAsync, money: money, df: df),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, IconData icon) => Row(
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
            t,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      );
}

class _ResumenMes extends StatelessWidget {
  final AsyncValue<List<dynamic>> transAsync;
  const _ResumenMes({required this.transAsync});

  @override
  Widget build(BuildContext context) {
    return transAsync.when(
      data: (items) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        double ingresos = 0, gastos = 0;
        for (final t in items) {
          final ft = (t as dynamic).fechaTransaccion as DateTime;
          if (ft.isAfter(start.subtract(const Duration(seconds: 1))) &&
              ft.isBefore(end.add(const Duration(days: 1)))) {
            if (t.tipoNombre == 'INGRESO') ingresos += t.monto;
            if (t.tipoNombre == 'GASTO') gastos += t.monto;
          }
        }
        final balance = ingresos - gastos;
        String fmt(double v) => NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(v);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Resumen del Mes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      'Ingresos',
                      fmt(ingresos),
                      Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _miniStat(
                      'Gastos',
                      fmt(gastos),
                      Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Balance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      fmt(balance),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('Error: $e'),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}

class _CuentaCard extends StatelessWidget {
  final String nombre;
  final double saldo;
  final String moneda;
  final String? colorHex;
  const _CuentaCard({
    required this.nombre,
    required this.saldo,
    required this.moneda,
    this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parse(colorHex) ?? const Color(0xFF3B82F6);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                // Glassmorphism effect
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  // Glassmorphism shadow
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Glassmorphism effect para icono
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              // Glassmorphism effect para moneda
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  moneda,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Número grande y legible con animación
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: saldo),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              // Formatear con separadores de miles (puntos)
              final formatter = NumberFormat('#,###', 'es_CO');
              final formattedValue = animatedValue % 1 == 0
                  ? formatter.format(animatedValue.toInt())
                  : formatter.format(animatedValue).replaceAll(RegExp(r'\.?0+$'), '');
              return Text(
                '\$$formattedValue',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              );
            },
          ),
        ],
      ),
            ),
          ),
        );
      },
    );
  }

  Color? _parse(String? h) {
    if (h == null || h.isEmpty) return null;
    final s = h.replaceAll('#', '');
    try {
      return s.length == 6
          ? Color(int.parse('FF$s', radix: 16))
          : Color(int.parse(s, radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _UltimosMovimientos extends StatelessWidget {
  final AsyncValue<List<dynamic>> transAsync;
  final NumberFormat money;
  final DateFormat df;
  const _UltimosMovimientos({
    required this.transAsync,
    required this.money,
    required this.df,
  });

  @override
  Widget build(BuildContext context) {
    return transAsync.when(
      data: (items) {
        final sorted = [...items]
          ..sort((a, b) => b.fechaTransaccion.compareTo(a.fechaTransaccion));
        final list = sorted.take(5).toList();
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No hay movimientos recientes',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }
        return Container(
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
          child: Column(
            children: list.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              final isIngreso = t.tipoNombre == 'INGRESO';
              final color = isIngreso ? const Color(0xFF10B981) : const Color(0xFFEF4444);
              final isLast = i == list.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      t.titulo?.isNotEmpty == true
                          ? t.titulo!
                          : (t.categoriaNombre ?? 'Transacción'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        df.format(t.fechaTransaccion),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: Text(
                      (isIngreso ? '+' : '-') + money.format(t.monto),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, indent: 72, color: Colors.grey[200]),
                ],
              );
            }).toList(),
          ),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('Error: $e'),
      ),
    );
  }
}

// ============================================
// Widget _Accesos deshabilitado (comentado pero no eliminado para futura reactivación)
// ============================================
/*
class _Accesos extends StatelessWidget {
  final VoidCallback onNfc;
  final VoidCallback onPresupuestos;
  const _Accesos({required this.onNfc, required this.onPresupuestos});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AccesoCard(
            icon: Icons.contactless,
            label: 'Pagar con NFC',
            color: const Color(0xFF3B82F6),
            onTap: onNfc,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AccesoCard(
            icon: Icons.assessment,
            label: 'Presupuestos',
            color: const Color(0xFF8B5CF6),
            onTap: onPresupuestos,
          ),
        ),
      ],
    );
  }
}
*/

// Widget _AccesoCard deshabilitado (comentado pero no eliminado para futura reactivación)
/*
class _AccesoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AccesoCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
