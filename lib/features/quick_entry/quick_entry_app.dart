import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/home_widget/home_widget_sync.dart';
import '../../core/security/app_lock.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/neo_bank_theme.dart';
import '../transactions/create_transaction_screen.dart';
import '../transactions/transactions_provider.dart';

const _channel = MethodChannel('financially/quick_entry');

/// App mínima de la hoja de registro rápido que abren los mosaicos de
/// Ajustes rápidos (`QuickEntryActivity.kt`). Corre en una actividad
/// transparente: solo se ve la hoja, encima de lo que hubiera en pantalla.
class QuickEntryApp extends StatelessWidget {
  const QuickEntryApp({super.key, required this.tipo});

  final String tipo; // 'GASTO' o 'INGRESO'

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financially',
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: NeoBankTheme.lightTheme(),
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      locale: const Locale('es', 'ES'),
      home: _QuickEntryHost(tipo: tipo),
    );
  }
}

class _QuickEntryHost extends ConsumerStatefulWidget {
  const _QuickEntryHost({required this.tipo});

  final String tipo;

  @override
  ConsumerState<_QuickEntryHost> createState() => _QuickEntryHostState();
}

class _QuickEntryHostState extends ConsumerState<_QuickEntryHost> {
  // Indicador mientras se revisa la sesión y la huella, antes de la hoja
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final api = ApiClient();
    final sesion = await api.readRefreshToken() != null || await api.hasToken();
    if (!mounted) return;
    if (!sesion) {
      setState(() => _cargando = false);
      await _sinSesion();
      return _cerrar();
    }

    // Con el bloqueo activo se pide la huella antes de mostrar cuentas y
    // saldos (el mosaico funciona incluso desde la pantalla de bloqueo)
    if (await AppLockNotifier.storedEnabled()) {
      final ok = await ref
          .read(appLockProvider.notifier)
          .authenticate('Confirma tu identidad para registrar');
      if (!ok) return _cerrar();
    }
    if (!mounted) return;
    setState(() => _cargando = false);

    final guardado = await showModalBottomSheet<bool>(
      context: context,
      // La ventana nativa ya está oscurecida (QuickEntryActivity)
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Brand.bg,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.94,
        child: CreateTransactionScreen(tipoTransaccion: widget.tipo),
      ),
    );
    // El formulario muestra "Gasto de $X en Y" al guardar: dejarlo ver
    if (guardado == true) {
      await Future.delayed(const Duration(milliseconds: 1600));
    }
    _cerrar();
  }

  Future<void> _sinSesion() {
    return showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Inicia sesión en Financially',
                style: Brand.text(size: 20, weight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Para registrar desde aquí necesitas una sesión abierta en la app.',
                style: Brand.text(size: 14, color: Brand.muted),
              ),
              const SizedBox(height: 20),
              BrandButton(
                label: 'Abrir Financially',
                onPressed: () => _channel.invokeMethod('abrirApp'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cerrar() => SystemNavigator.pop();

  @override
  Widget build(BuildContext context) {
    // Lo registrado aquí también se refleja en el widget de inicio
    ref.listen(transactionsNotifierProvider, (_, next) {
      final trans = next.valueOrNull;
      if (trans != null) HomeWidgetSync.update(trans);
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _cargando
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
              ),
            )
          : null,
    );
  }
}
