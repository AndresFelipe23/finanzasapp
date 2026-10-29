import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/auth_models.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/security/app_lock.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/monedas_constants.dart';
import '../accounts/accounts_provider.dart';
import '../accounts/accounts_screen.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../categories/categories_provider.dart';
import '../categories/categories_screen.dart';
import '../export/export_sheet.dart';
import '../prestamos/prestamos_screen.dart';
import '../presupuestos/presupuestos_screen.dart';
import '../recurring/recurring_screen.dart';
import '../../core/session/current_user.dart';
import '../../core/quick_launch/quick_tiles.dart';
import '../../core/theme/brand_form.dart';
import '../../core/compras/compra_automatica.dart';
import 'compras_automaticas_screen.dart';

// USD aparece varias veces (Ecuador, El Salvador, Panamá): una por código
final _monedas = {
  for (final m in MonedasConstants.monedasHispanas) m.codigo: m,
}.values.toList();

// ─── Perfil ───────────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  final UserResponse user;

  const ProfileScreen({super.key, required this.user});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _auth = AuthService(ApiClient());
  late UserResponse _user = widget.user;
  bool _savingMoneda = false;

  void _push(Widget screen) => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute(builder: (_) => screen));

  Future<UserResponse?> _save({
    String? nombre,
    String? telefono,
    DateTime? fechaNacimiento,
    String? moneda,
  }) async {
    try {
      final updated = await _auth.updateProfile(
        nombre: nombre ?? _user.nombre,
        telefono: telefono ?? _user.telefono,
        fechaNacimiento: fechaNacimiento ?? _user.fechaNacimiento,
        monedaPredeterminada: moneda ?? _user.monedaPredeterminada,
      );
      if (mounted) setState(() => _user = updated);
      // Inicio y el menú lateral muestran el nombre nuevo
      ref.read(currentUserProvider.notifier).state = updated;
      return updated;
    } catch (e) {
      if (mounted) {
        showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
      return null;
    }
  }

  Future<void> _changeMoneda(String codigo) async {
    if (codigo == _user.monedaPredeterminada) return;
    setState(() => _savingMoneda = true);
    final ok = await _save(moneda: codigo);
    if (!mounted) return;
    setState(() => _savingMoneda = false);
    if (ok != null) showBrandSnack(context, 'Moneda actualizada', error: false);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Cerrar sesión?',
            style: Brand.text(size: 18, weight: FontWeight.w800)),
        content: Text(
          'Tendrás que iniciar sesión con tu contraseña la próxima vez.',
          style: Brand.text(size: 14, color: Brand.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: Brand.text(weight: FontWeight.w700, color: Brand.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Brand.expense),
            child: Text('Cerrar sesión',
                style: Brand.text(weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = ref.watch(accountsNotifierProvider).valueOrNull;
    final categorias = ref.watch(categoriesNotifierProvider).valueOrNull;
    final notifOn = ref.watch(notificationsEnabledProvider);
    final mes = DateFormat('MMM', 'es_ES').format(DateTime.now());

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text('Perfil', style: Brand.title(size: 26)),
            const SizedBox(height: 18),
            _UserCard(user: _user, onEdit: _openEdit),
            const SizedBox(height: 14),
            _Card(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Moneda predeterminada',
                      style: Brand.text(size: 13, weight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _MonedaPicker(
                    value: _user.monedaPredeterminada ?? 'COP',
                    saving: _savingMoneda,
                    onChanged: _changeMoneda,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Se usa para el saldo total y los reportes.',
                    style: Brand.text(size: 12, color: Brand.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: _withDividers([
                  _Row(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Mis cuentas',
                    hint: cuentas == null
                        ? null
                        : '${cuentas.where((c) => c.activa).length}',
                    onTap: () => _push(const AccountsScreen()),
                  ),
                  _Row(
                    icon: Icons.grid_view_rounded,
                    label: 'Categorías',
                    hint: categorias == null ? null : '${categorias.length}',
                    onTap: () => _push(const CategoriesScreen()),
                  ),
                  _Row(
                    icon: Icons.pie_chart_outline_rounded,
                    label: 'Presupuestos',
                    hint: mes[0].toUpperCase() + mes.substring(1).replaceAll('.', ''),
                    onTap: () => _push(const PresupuestosScreen()),
                  ),
                  _Row(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Préstamos',
                    onTap: () => _push(const PrestamosScreen()),
                  ),
                  _Row(
                    icon: Icons.autorenew_rounded,
                    label: 'Pagos recurrentes',
                    onTap: () => _push(const RecurringScreen()),
                  ),
                  _Row(
                    icon: Icons.file_download_outlined,
                    label: 'Exportar movimientos',
                    onTap: () => showExportSheet(context),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: _withDividers([
                  _Row(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notificaciones',
                    trailing: Switch.adaptive(
                      value: notifOn,
                      activeTrackColor: Brand.accent,
                      onChanged: (v) async {
                        final ok = await ref
                            .read(notificationsEnabledProvider.notifier)
                            .setEnabled(v);
                        if (!ok && context.mounted) {
                          showBrandSnack(
                            context,
                            'Activa el permiso de notificaciones en los '
                            'ajustes del teléfono',
                          );
                        }
                      },
                    ),
                  ),
                  if (NotificationService.instance.quickRecordSupported)
                    _Row(
                      icon: Icons.bolt_rounded,
                      label: 'Registro rápido en notificaciones',
                      trailing: Switch.adaptive(
                        value: ref.watch(quickRecordEnabledProvider),
                        activeTrackColor: Brand.accent,
                        onChanged: (v) async {
                          final ok = await ref
                              .read(quickRecordEnabledProvider.notifier)
                              .setEnabled(v);
                          if (!context.mounted) return;
                          if (!ok) {
                            showBrandSnack(
                              context,
                              'Activa el permiso de notificaciones en los '
                              'ajustes del teléfono',
                            );
                          } else if (v) {
                            showBrandSnack(
                              context,
                              'Listo: desliza la barra de notificaciones y '
                              'toca "Gasto"',
                              error: false,
                            );
                          }
                        },
                      ),
                    ),
                  if (CompraAutomatica.soportado)
                    _Row(
                      icon: Icons.contactless_outlined,
                      label: 'Compras automáticas',
                      onTap: () => _push(const ComprasAutomaticasScreen()),
                    ),
                  if (QuickTiles.esAndroid)
                    _Row(
                      icon: Icons.dashboard_customize_outlined,
                      label: 'Atajos en Ajustes rápidos',
                      onTap: _ofrecerMosaicos,
                    ),
                  _Row(
                    icon: Icons.shield_outlined,
                    label: 'Seguridad',
                    hint: ref.watch(appLockProvider) ? 'Huella activa' : null,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      backgroundColor: Brand.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      builder: (_) => const _SecuritySheet(),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Brand.expense,
                  side: const BorderSide(color: Brand.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Cerrar sesión',
                  style: Brand.text(
                    weight: FontWeight.w700,
                    color: Brand.expense,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> rows) => [
    for (final (i, r) in rows.indexed) ...[
      if (i > 0) const Divider(height: 1, color: Brand.border),
      r,
    ],
  ];

  /// Mosaicos "Nuevo gasto" / "Nuevo ingreso" del panel de Ajustes rápidos:
  /// en Android 13+ el sistema pregunta si se agregan; antes, a mano.
  Future<void> _ofrecerMosaicos() async {
    if (!await QuickTiles.puedePedir()) {
      if (mounted) showBrandSnack(context, QuickTiles.instruccionesManuales, error: false);
      return;
    }
    if (!mounted) return;
    final tipo = await showBrandPicker<String>(
      context,
      title: 'Agregar a Ajustes rápidos',
      options: const [
        BrandOption(
          'GASTO',
          'Nuevo gasto',
          subtitle: 'Abre la hoja para registrar un gasto',
          icon: Icons.remove_circle_outline_rounded,
          color: Brand.expense,
        ),
        BrandOption(
          'INGRESO',
          'Nuevo ingreso',
          subtitle: 'Abre la hoja para registrar un ingreso',
          icon: Icons.add_circle_outline_rounded,
          color: Brand.accent,
        ),
      ],
    );
    if (tipo == null) return;
    final mensaje = await QuickTiles.agregar(tipo);
    if (mounted) showBrandSnack(context, mensaje, error: false);
  }

  Future<void> _openEdit() async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _EditProfileSheet(
        user: _user,
        onSave: (nombre, telefono, fecha) =>
            _save(nombre: nombre, telefono: telefono, fechaNacimiento: fecha),
      ),
    );
  }
}

// ─── Componentes ──────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Brand.border),
      ),
      child: child,
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onEdit});

  final UserResponse user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = user.nombre
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return _Card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Brand.ink,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: Brand.text(
                size: 20,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.text(size: 17, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.text(size: 13, color: Brand.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              backgroundColor: Brand.bg,
              foregroundColor: Brand.ink,
              side: const BorderSide(color: Brand.border),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Editar',
                style: Brand.text(size: 13, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _MonedaPicker extends StatelessWidget {
  const _MonedaPicker({
    required this.value,
    required this.saving,
    required this.onChanged,
  });

  final String value;
  final bool saving;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: Brand.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Brand.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Brand.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: Brand.text(
                size: 11,
                weight: FontWeight.w800,
                color: Brand.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _monedas.any((m) => m.codigo == value) ? value : null,
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                dropdownColor: Brand.surface,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Brand.accent,
                        ),
                      )
                    : const Icon(Icons.expand_more_rounded, color: Brand.muted),
                style: Brand.text(weight: FontWeight.w700),
                items: [
                  for (final m in _monedas)
                    DropdownMenuItem(
                      value: m.codigo,
                      child: Text(
                        '${m.nombreMoneda} (${m.codigo})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: saving
                    ? null
                    : (v) {
                        if (v != null) onChanged(v);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.hint,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
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
              child: Text(label,
                  style: Brand.text(weight: FontWeight.w600)),
            ),
            if (hint != null) ...[
              Text(hint!, style: Brand.text(size: 13, color: Brand.muted)),
              const SizedBox(width: 6),
            ],
            trailing ??
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: Brand.muted),
          ],
        ),
      ),
    );
  }
}

// ─── Editar perfil ────────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.onSave});

  final UserResponse user;
  final Future<UserResponse?> Function(
    String nombre,
    String? telefono,
    DateTime? fecha,
  ) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController(text: widget.user.nombre);
  late final _telCtrl = TextEditingController(text: widget.user.telefono ?? '');
  late DateTime? _fecha = widget.user.fechaNacimiento;
  bool _saving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final tel = _telCtrl.text.trim();
    final ok = await widget.onSave(
      _nombreCtrl.text.trim(),
      tel.isEmpty ? null : tel,
      _fecha,
    );
    if (!mounted) return;
    if (ok != null) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Brand.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Editar perfil',
                    style: Brand.text(size: 20, weight: FontWeight.w800)),
                const SizedBox(height: 18),
                BrandField(
                  label: 'Nombre completo',
                  controller: _nombreCtrl,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Escribe tu nombre'
                      : null,
                ),
                const SizedBox(height: 14),
                BrandField(
                  label: 'Teléfono (opcional)',
                  hint: '+573001234567',
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return null;
                    // Mismo formato que valida la API (E.164)
                    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(s)
                        ? null
                        : 'Usa solo números, con el indicativo. Ej: +573001234567';
                  },
                ),
                const SizedBox(height: 14),
                Text('Fecha de nacimiento (opcional)',
                    style: Brand.text(size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Brand.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Brand.inputBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fecha == null
                                ? 'Elegir fecha'
                                : DateFormat("d 'de' MMMM 'de' yyyy", 'es_ES')
                                    .format(_fecha!),
                            style: Brand.text(
                              color: _fecha == null
                                  ? Brand.placeholder
                                  : Brand.ink,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: Brand.muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BrandButton(
                  label: 'Guardar cambios',
                  loading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Seguridad ────────────────────────────────────────────────────────────────
class _SecuritySheet extends ConsumerStatefulWidget {
  const _SecuritySheet();

  @override
  ConsumerState<_SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends ConsumerState<_SecuritySheet> {
  final _auth = AuthService(ApiClient());
  bool? _bioLogin;

  @override
  void initState() {
    super.initState();
    _auth.biometricLoginEnabled().then((v) {
      if (mounted) setState(() => _bioLogin = v);
    });
  }

  Future<void> _toggleBioLogin(bool v) async {
    if (v && !await _auth.biometricAvailable()) {
      if (mounted) {
        showBrandSnack(context, 'Tu teléfono no tiene huella o rostro configurado');
      }
      return;
    }
    await _auth.setBiometricLogin(v);
    final now = await _auth.biometricLoginEnabled();
    if (mounted) setState(() => _bioLogin = now);
  }

  Widget _switchRow(String title, String body, bool? value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Brand.text(weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body,
                    style: Brand.text(size: 12, color: Brand.muted, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          value == null
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch.adaptive(
                  value: value,
                  activeTrackColor: Brand.accent,
                  onChanged: onChanged,
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lockOn = ref.watch(appLockProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Brand.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Seguridad', style: Brand.text(size: 20, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            _switchRow(
              'Entrar con huella o rostro',
              'Inicia sesión sin escribir tu contraseña.',
              _bioLogin,
              _toggleBioLogin,
            ),
            const Divider(height: 1, color: Brand.border),
            _switchRow(
              'Bloquear al volver a la app',
              'Pide tu huella, rostro o PIN si sales más de un minuto.',
              lockOn,
              (v) async {
                final notifier = ref.read(appLockProvider.notifier);
                if (v && !await notifier.isSupported) {
                  if (context.mounted) {
                    showBrandSnack(context, 'Tu dispositivo no tiene bloqueo configurado');
                  }
                  return;
                }
                if (!await notifier.setEnabled(v) && context.mounted) {
                  showBrandSnack(context, 'No se pudo verificar tu identidad');
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Cambia tu contraseña desde "¿Olvidaste tu contraseña?" en la '
              'pantalla de inicio de sesión.',
              style: Brand.text(size: 12, color: Brand.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
