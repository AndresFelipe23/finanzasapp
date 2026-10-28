import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../../core/models/auth_models.dart';
import '../../core/theme/glass.dart';
import '../../core/theme/neo_bank_theme.dart';
import '../../features/home/home_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/accounts/accounts_screen.dart';
import '../../features/metas/metas_screen.dart';
import '../../features/prestamos/prestamos_screen.dart';
import '../../features/presupuestos/presupuestos_screen.dart';
// Imports NFC deshabilitados (comentados pero no eliminados para futura reactivación)
// import '../../features/tarjetas_nfc/tarjetas_nfc_screen.dart';
// import '../../features/pagos_nfc/pagar_con_nfc_screen.dart';
// import '../../features/pagos_nfc/pagos_nfc_history2.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/auth/auth_service.dart';
import '../../core/api/api_client.dart';
import '../../features/auth/login_screen.dart';
// Import deshabilitado (comentado pero no eliminado para futura reactivación)
// import '../../features/add_transaction/add_transaction_screen.dart';

class MainNavigation extends StatefulWidget {
  final UserResponse user;

  const MainNavigation({super.key, required this.user});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late PersistentTabController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Inicializar siempre con índice 0 para evitar problemas con índices fuera de rango
    _controller = PersistentTabController(initialIndex: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final screens = _buildScreens();
    final items = _navBarItems(t);

    // Asegurar que el índice del controller no exceda el número de pantallas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.index >= screens.length) {
        _controller.index = 0;
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(context),
      body: AppBackground(
        child: PersistentTabView(
          context,
          controller: _controller,
          screens: screens,
          items: items,
          navBarHeight: 64,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
          backgroundColor: Colors.transparent,
          handleAndroidBackButtonPress: true,
          resizeToAvoidBottomInset: true,
          stateManagement: true,
          hideNavigationBarWhenKeyboardAppears: false,
          animationSettings: const NavBarAnimationSettings(
            navBarItemAnimation: ItemAnimationSettings(
              duration: Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            ),
            screenTransitionAnimation: ScreenTransitionAnimationSettings(
              animateTabTransition: true,
              duration: Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              screenTransitionAnimationType:
                  ScreenTransitionAnimationType.fadeIn,
            ),
          ),
          decoration: NavBarDecoration(
            borderRadius: BorderRadius.circular(22),
            colorBehindNavBar: Colors.transparent,
            border: Border.all(color: t.glassStrokeStart),
            gradient: LinearGradient(
              colors: [_navBarTint(t), _navBarTint(t)],
            ),
            boxShadow: [
              BoxShadow(
                color: t.glassShadow,
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          // style3 del paquete hace cast erróneo si defines textStyle; style1
          // aplica textStyle.apply correctamente y evita overflow de altura.
          navBarStyle: NavBarStyle.style1,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final t = context.tokens;
    final initials = widget.user.nombre
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: t.blurChrome,
            sigmaY: t.blurChrome,
          ),
          child: ColoredBox(
            color: t.surface.withValues(alpha: 0.82),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + 24,
                    left: 24,
                    right: 24,
                    bottom: 26,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [t.accent, t.transfer],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Menú ────────────────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    children: [
                      _drawerLabel(context, 'Gestión'),
                      const SizedBox(height: 8),
                      _drawerItem(
                        context: context,
                        icon: Icons.category_outlined,
                        iconColor: t.transfer,
                        title: 'Categorías',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoriesScreen(),
                            ),
                          );
                        },
                      ),
                      _drawerItem(
                        context: context,
                        icon: Icons.pie_chart_outline_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Presupuestos',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PresupuestosScreen(),
                            ),
                          );
                        },
                      ),
                      _drawerItem(
                        context: context,
                        icon: Icons.request_page_outlined,
                        iconColor: const Color(0xFF06B6D4),
                        title: 'Préstamos',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrestamosScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _drawerLabel(context, 'Cuenta'),
                      const SizedBox(height: 8),
                      _drawerItem(
                        context: context,
                        icon: Icons.person_outline_rounded,
                        iconColor: t.accent,
                        title: 'Mi Perfil',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(user: widget.user),
                            ),
                          );
                        },
                      ),
                      // ── NFC deshabilitado (comentado para futura reactivación) ──
                      /*
                  _drawerItem(
                    context: context,
                    icon: Icons.credit_card,
                    iconColor: const Color(0xFF0EA5E9),
                    title: 'Tarjetas NFC',
                    onTap: () { ... },
                  ),
                  _drawerItem(
                    context: context,
                    icon: Icons.nfc,
                    iconColor: const Color(0xFF22C55E),
                    title: 'Pagar con NFC',
                    onTap: () { ... },
                  ),
                  */
                    ],
                  ),
                ),

                // ── Logout ──────────────────────────────────────────────────
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: t.divider, width: 1)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showLogoutDialog(context),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 18,
                          bottom: 18 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: t.danger.withValues(
                                  alpha: t.isDark ? 0.16 : 0.08,
                                ),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.logout_rounded,
                                color: t.danger,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Cerrar sesión',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: t.danger,
                              ),
                            ),
                          ],
                        ),
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

  Widget _drawerLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: context.tokens.textSecondary.withValues(alpha: 0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final t = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: iconColor.withValues(alpha: 0.06),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: t.isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: t.textSecondary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final t = context.tokens;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          strong: true,
          blurSigma: t.blurChrome,
          borderRadius: BorderRadius.circular(t.radiusLg),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: t.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, size: 30, color: t.danger),
              ),
              const SizedBox(height: 18),
              Text(
                '¿Cerrar sesión?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Deberás iniciar sesión nuevamente para acceder a tu cuenta.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: t.textSecondary,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: t.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _logout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cerrar sesión',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService(ApiClient());
    await authService.logout();
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
        user: widget.user,
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      const TransactionsScreen(),
      const AccountsScreen(),
      const MetasScreen(),
    ];
  }

  // El paquete pinta el gradiente una vez bajo el BackdropFilter y otra encima,
  // así que se compone dos veces: se invierte para llegar a t.glassFill.
  Color _navBarTint(AppTokens t) =>
      Colors.white.withValues(alpha: 1 - math.sqrt(1 - t.glassFill.a));

  List<PersistentBottomNavBarItem> _navBarItems(AppTokens t) {
    const iconActive = 26.0;
    const iconInactive = 24.0;

    PersistentBottomNavBarItem tab({
      required String title,
      required IconData iconOn,
      required IconData iconOff,
    }) {
      return PersistentBottomNavBarItem(
        title: title,
        iconSize: iconActive,
        contentPadding: 4,
        icon: Icon(iconOn, size: iconActive),
        inactiveIcon: Icon(iconOff, size: iconInactive),
        activeColorPrimary: t.accent,
        activeColorSecondary: t.accent,
        inactiveColorPrimary: t.textSecondary,
        filter: ui.ImageFilter.blur(sigmaX: t.blurChrome, sigmaY: t.blurChrome),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.15,
        ),
      );
    }

    return [
      tab(
        title: 'Inicio',
        iconOn: Icons.home_rounded,
        iconOff: Icons.home_outlined,
      ),
      tab(
        title: 'Movimientos',
        iconOn: Icons.receipt_long_rounded,
        iconOff: Icons.receipt_long_outlined,
      ),
      tab(
        title: 'Cuentas',
        iconOn: Icons.account_balance_wallet,
        iconOff: Icons.account_balance_wallet_outlined,
      ),
      tab(
        title: 'Metas',
        iconOn: Icons.flag_rounded,
        iconOff: Icons.flag_outlined,
      ),
    ];
  }
}
