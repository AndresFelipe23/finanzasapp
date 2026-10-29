import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/brand.dart';

final appLockProvider = StateNotifierProvider<AppLockNotifier, bool>(
  (ref) => AppLockNotifier(),
);

/// Preferencia de bloqueo con huella / rostro / PIN del dispositivo.
class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier() : super(false) {
    _load();
  }

  static const _key = 'appLockEnabled';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Lee la preferencia guardada sin esperar a [_load] (hoja de registro
  /// rápido, que debe decidir antes de mostrar nada).
  static Future<bool> storedEnabled() async {
    try {
      return await const FlutterSecureStorage().read(key: _key) == 'true';
    } catch (_) {
      return false;
    }
  }
  final LocalAuthentication _auth = LocalAuthentication();

  Future<void> _load() async {
    try {
      state = await _storage.read(key: _key) == 'true';
    } catch (_) {
      // Sin preferencia guardada el bloqueo queda desactivado
    }
  }

  Future<bool> get isSupported async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Error de autenticación local: $e');
      return false;
    }
  }

  /// Activar exige autenticarse primero para no dejar al usuario por fuera.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled &&
        !await authenticate('Confirma tu identidad para activar el bloqueo')) {
      return false;
    }
    state = enabled;
    try {
      await _storage.write(key: _key, value: '$enabled');
    } catch (_) {
      // El cambio ya se aplicó en memoria aunque no persista
    }
    return true;
  }
}

/// Cubre a [child] con una pantalla de bloqueo cuando la app vuelve del
/// segundo plano tras [timeout].
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
    this.timeout = const Duration(seconds: 60),
  });

  final Widget child;
  final Duration timeout;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  // Arranca desbloqueado: el usuario acaba de iniciar sesión con contraseña
  bool _locked = false;
  bool _authenticating = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // El propio diálogo biométrico pausa la app; no contarlo como salida
    if (_authenticating) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final away = DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (ref.read(appLockProvider) && away >= widget.timeout) {
        setState(() => _locked = true);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    if (!ref.read(appLockProvider)) {
      setState(() => _locked = false);
      return;
    }
    _authenticating = true;
    final ok = await ref
        .read(appLockProvider.notifier)
        .authenticate('Desbloquea Financially para ver tus finanzas');
    _authenticating = false;
    if (mounted && ok) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(appLockProvider);
    return Stack(
      children: [
        widget.child,
        if (enabled && _locked) _LockScreen(onUnlock: _unlock),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    // Mismo verde profundo que el splash: se reconoce como parte de la app
    return Positioned.fill(
      child: Material(
        color: Brand.deep,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Brand.deepCard,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 40,
                      color: Brand.mint,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Financially está bloqueada',
                  textAlign: TextAlign.center,
                  style: Brand.title(size: 24, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Usa tu huella, rostro o PIN para continuar.',
                  textAlign: TextAlign.center,
                  style: Brand.text(size: 15, color: Brand.deepText),
                ),
                const Spacer(),
                BrandButton(
                  label: 'Desbloquear',
                  background: Brand.mint,
                  foreground: Brand.deep,
                  icon: const Icon(Icons.fingerprint_rounded, size: 22),
                  onPressed: onUnlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
