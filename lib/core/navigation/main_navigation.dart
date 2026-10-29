import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/home_widget/home_widget_sync.dart';
import '../../core/models/auth_models.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/notifications/quick_record.dart';
import '../../core/quick_launch/quick_launch.dart';
import '../../core/session/current_user.dart';
import '../../core/theme/brand.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/new_transaction_sheet.dart';
import '../../features/transactions/create_transaction_screen.dart';
import '../../features/transactions/create_transfer_screen.dart';
import '../../features/accounts/accounts_provider.dart';
import '../../features/transactions/transaction_detail_sheet.dart';
import '../../features/transactions/transactions_provider.dart';
import '../../features/transactions/transactions_service.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/accounts/accounts_screen.dart';
import '../../features/metas/metas_screen.dart';
import '../../features/prestamos/prestamos_screen.dart';
import '../../features/presupuestos/presupuestos_screen.dart';
import '../../features/recurring/recurring_screen.dart';
import '../../features/export/export_sheet.dart';
// Imports NFC deshabilitados (comentados pero no eliminados para futura reactivación)
// import '../../features/tarjetas_nfc/tarjetas_nfc_screen.dart';
// import '../../features/pagos_nfc/pagar_con_nfc_screen.dart';
// import '../../features/pagos_nfc/pagos_nfc_history2.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/auth/auth_service.dart';
import '../../core/api/api_client.dart';
import '../../features/auth/login_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final UserResponse user;

  const MainNavigation({super.key, required this.user});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Pestañas: 0 Inicio · 1 Movimientos · 2 Metas · 3 Perfil (el + no es pestaña)
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Programa recordatorios y revisa presupuestos al entrar
    NotificationService.instance.syncFromServer(ApiClient());
    NotificationService.instance.showQuickRecord();
    // Gastos del registro rápido que quedaron guardados sin conexión
    QuickRecord.enviarPendientes();
    // El perfil de esta sesión (moneda base de los totales, nombre)
    Future.microtask(() {
      if (!mounted) return;
      final actual = ref.read(currentUserProvider);
      if (actual?.id != widget.user.id) {
        ref.read(currentUserProvider.notifier).state = widget.user;
      }
    });
    // Pedidos del ícono, el widget o una notificación (incluido el que abrió
    // la app, que llegó antes de iniciar sesión)
    QuickLaunch.pending.addListener(_openPending);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
  }

  @override
  void dispose() {
    QuickLaunch.pending.removeListener(_openPending);
    super.dispose();
  }

  void _openPending() {
    if (!mounted || QuickLaunch.pending.value == null) return;
    final r = QuickLaunch.take()!;
    if (r.destino == QuickRequest.movimiento) {
      _abrirMovimiento(r.id);
      return;
    }
    final Widget screen = switch (r.destino) {
      QuickRequest.ingreso => CreateTransactionScreen(
        tipoTransaccion: 'INGRESO',
        montoInicial: r.monto,
        notaInicial: r.nota,
      ),
      QuickRequest.transferencia => const CreateTransferScreen(),
      QuickRequest.recurrentes => const RecurringScreen(),
      QuickRequest.presupuestos => const PresupuestosScreen(),
      _ => CreateTransactionScreen(
        tipoTransaccion: 'GASTO',
        montoInicial: r.monto,
        notaInicial: r.nota,
      ),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Detalle de un movimiento creado fuera de la app (compra registrada
  /// automáticamente): se recarga la lista porque es nuevo.
  Future<void> _abrirMovimiento(int? id) async {
    if (id == null) return;
    final notifier = ref.read(transactionsNotifierProvider.notifier);
    await notifier.refresh();
    ref.read(accountsNotifierProvider.notifier).refresh();
    var t = ref.read(transactionsNotifierProvider).valueOrNull
        ?.where((x) => x.id == id)
        .firstOrNull;
    if (t == null) {
      try {
        t = await TransactionsService(ApiClient()).getTransactionById(id);
      } catch (_) {
        return; // Ya no existe (p. ej. se borró)
      }
    }
    if (!mounted) return;
    showTransactionDetail(context, t);
  }

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // El widget de la pantalla de inicio refleja los movimientos cargados
    ref.listen(transactionsNotifierProvider, (_, next) {
      final trans = next.valueOrNull;
      if (trans != null) HomeWidgetSync.update(trans);
    });

    return PopScope(
      // Atrás desde otra pestaña vuelve a Inicio antes de salir de la app
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Brand.bg,
        drawer: _buildDrawer(context),
        body: IndexedStack(index: _index, children: _buildScreens()),
        bottomNavigationBar: _BottomBar(
          index: _index,
          onSelect: _goTo,
          onAdd: () => showNewTransactionSheet(context),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final nombre = vigente(ref, widget.user).nombre.trim();
    final initials = nombre
        .split(RegExp(r'\s+'))
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    // Cierra el menú y abre una pantalla encima de las pestañas
    void open(Widget screen) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    return Drawer(
      backgroundColor: Brand.bg,
      elevation: 0,
      width: 304,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Usuario ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Material(
                color: Brand.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: Brand.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    Navigator.pop(context);
                    _goTo(3);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Brand.ink,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            initials,
                            style: Brand.text(
                              size: 16,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Brand.text(weight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                vigente(ref, widget.user).email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Brand.text(size: 12, color: Brand.muted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Brand.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Menú ────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  _DrawerSection(
                    title: 'Mis finanzas',
                    items: [
                      _DrawerItem(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Cuentas',
                        onTap: () => open(const AccountsScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.pie_chart_outline_rounded,
                        label: 'Presupuestos',
                        onTap: () => open(const PresupuestosScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Préstamos',
                        onTap: () => open(const PrestamosScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.autorenew_rounded,
                        label: 'Pagos recurrentes',
                        onTap: () => open(const RecurringScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DrawerSection(
                    title: 'Organizar',
                    items: [
                      _DrawerItem(
                        icon: Icons.grid_view_rounded,
                        label: 'Categorías',
                        onTap: () => open(const CategoriesScreen()),
                      ),
                      _DrawerItem(
                        icon: Icons.file_download_outlined,
                        label: 'Exportar movimientos',
                        onTap: () {
                          Navigator.pop(context);
                          showExportSheet(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Cerrar sesión ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    'Cerrar sesión',
                    style: Brand.text(
                      weight: FontWeight.w700,
                      color: Brand.expense,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Brand.expense,
                    backgroundColor: Brand.surface,
                    side: const BorderSide(color: Brand.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '¿Cerrar sesión?',
          style: Brand.text(size: 18, weight: FontWeight.w800),
        ),
        content: Text(
          'Tendrás que iniciar sesión con tu contraseña la próxima vez.',
          style: Brand.text(size: 14, color: Brand.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: Brand.text(weight: FontWeight.w700, color: Brand.muted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Brand.expense),
            child: Text(
              'Cerrar sesión',
              style: Brand.text(weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService(ApiClient()).logout();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        user: vigente(ref, widget.user),
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        openProfile: () => _goTo(3),
        openMovements: () => _goTo(1),
      ),
      const TransactionsScreen(),
      const MetasScreen(),
      ProfileScreen(user: widget.user),
    ];
  }
}

/// Barra inferior del diseño: 4 pestañas y un botón + elevado al centro.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.onSelect,
    required this.onAdd,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    Widget tab(int i, IconData on, IconData off, String label) {
      final selected = index == i;
      final color = selected ? Brand.accent : Brand.muted;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => onSelect(i),
            radius: 32,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? on : off, size: 24, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.text(
                    size: 11,
                    weight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Brand.surface,
        border: Border(top: BorderSide(color: Brand.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              tab(0, Icons.home_rounded, Icons.home_outlined, 'Inicio'),
              tab(1, Icons.receipt_long_rounded, Icons.receipt_long_outlined,
                  'Movimientos'),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: Semantics(
                      button: true,
                      label: 'Nuevo movimiento',
                      excludeSemantics: true,
                      child: Material(
                        color: Brand.accent,
                        shape: const CircleBorder(),
                        elevation: 3,
                        shadowColor: Brand.accent.withValues(alpha: 0.4),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onAdd,
                          child: const SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.add_rounded,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              tab(2, Icons.track_changes_rounded, Icons.track_changes_outlined,
                  'Metas'),
              tab(3, Icons.person_rounded, Icons.person_outline_rounded,
                  'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menú lateral ─────────────────────────────────────────────────────────────
class _DrawerSection extends StatelessWidget {
  const _DrawerSection({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Brand.text(
              size: 11,
              weight: FontWeight.w700,
              color: Brand.muted,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Brand.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Brand.border),
          ),
          child: Column(
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0) const Divider(height: 1, color: Brand.border),
                item,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Brand.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: Brand.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Brand.text(weight: FontWeight.w600)),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Brand.muted,
            ),
          ],
        ),
      ),
    );
  }
}
