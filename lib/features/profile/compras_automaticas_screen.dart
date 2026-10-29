import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/compras/compra_automatica.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';

/// Perfil → Registrar compras automáticamente: activar, dar el permiso de
/// leer notificaciones y revisar qué se detectó.
class ComprasAutomaticasScreen extends StatefulWidget {
  const ComprasAutomaticasScreen({super.key});

  @override
  State<ComprasAutomaticasScreen> createState() => _ComprasAutomaticasScreenState();
}

class _ComprasAutomaticasScreenState extends State<ComprasAutomaticasScreen>
    with WidgetsBindingObserver {
  bool _activo = false;
  bool _acceso = false;
  List<Map<String, dynamic>> _registro = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver de los ajustes del sistema se revisa si dio el permiso
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  Future<void> _cargar() async {
    final (activo, acceso, registro) = await (
      CompraAutomatica.activo(),
      CompraAutomatica.tieneAcceso(),
      CompraAutomatica.registro(),
    ).wait;
    if (!mounted) return;
    setState(() {
      _activo = activo;
      _acceso = acceso;
      _registro = registro;
    });
  }

  Future<void> _cambiar(bool v) async {
    await CompraAutomatica.setActivo(v);
    setState(() => _activo = v);
    if (v && !_acceso) await _pedirPermiso();
  }

  Future<void> _pedirPermiso() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Permitir leer notificaciones',
            style: Brand.text(size: 18, weight: FontWeight.w800)),
        content: Text(
          'En la siguiente pantalla busca Financially y actívalo. Solo se '
          'leen los avisos de pago (Google Wallet y bancos); los demás se '
          'ignoran y nada sale de tu teléfono salvo el gasto registrado.',
          style: Brand.text(size: 14, color: Brand.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ahora no',
                style: Brand.text(weight: FontWeight.w700, color: Brand.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Brand.ink),
            child: Text('Ir a ajustes',
                style: Brand.text(weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await CompraAutomatica.abrirAjuste();
  }

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat("d MMM · HH:mm", 'es_ES');
    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: Brand.accent,
          onRefresh: _cargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const BrandBackButton(),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Compras automáticas', style: Brand.title(size: 22))),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Cuando pagas con el teléfono (NFC) o con tarjeta, Google Wallet '
                'o tu banco te avisa. Financially lee ese aviso y registra el '
                'gasto solo: comercio, monto, tarjeta y la categoría que usaste '
                'antes en ese comercio.',
                style: Brand.text(size: 14, color: Brand.muted, height: 1.45),
              ),
              const SizedBox(height: 18),
              BrandGroup(
                children: [
                  BrandSwitchRow(
                    title: 'Registrar compras automáticamente',
                    subtitle: 'Te avisamos cada compra que se registre',
                    value: _activo,
                    onChanged: _cambiar,
                  ),
                  BrandGroupRow(
                    label: 'Permiso de notificaciones',
                    value: _acceso ? 'Concedido' : 'Falta darlo',
                    placeholder: !_acceso,
                    onTap: _pedirPermiso,
                  ),
                ],
              ),
              if (_activo && !_acceso) ...[
                const SizedBox(height: 8),
                Text(
                  'Sin el permiso no se puede registrar nada. Toca "Permiso de '
                  'notificaciones" para darlo.',
                  style: Brand.text(size: 12, color: Brand.expense),
                ),
              ],
              const SizedBox(height: 22),
              const BrandLabel('Cómo se decide'),
              Text(
                '• Cuenta: la que asociaste a esa tarjeta (si corriges la cuenta de '
                'una compra automática, se recuerda para la siguiente); si no, tu '
                'primera tarjeta.\n'
                '• Categoría: la que usaste antes en ese comercio; si no la sabe, '
                'el aviso te pide elegirla.\n'
                '• Si Wallet y el banco avisan la misma compra, o ya la registraste '
                'a mano, no se duplica.\n'
                '• No se registra dinero que entra, retiros ni promociones.',
                style: Brand.text(size: 13, color: Brand.muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              const BrandLabel('Últimos avisos detectados'),
              if (_registro.isEmpty)
                Text(
                  'Aún no hay ninguno. Haz una compra con el teléfono o tu tarjeta.',
                  style: Brand.text(size: 13, color: Brand.muted),
                )
              else
                BrandGroup(
                  children: [
                    for (final r in _registro)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${r['resultado']}',
                                    style: Brand.text(size: 14, weight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  fecha.format(
                                    DateTime.tryParse('${r['fecha']}') ?? DateTime.now(),
                                  ),
                                  style: Brand.text(size: 12, color: Brand.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${r['fuente']}: ${r['texto']}',
                              style: Brand.text(size: 12, color: Brand.muted, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              Text(
                'Si un aviso de tu banco no se entiende ("No parece una compra"), '
                'compárteme ese texto para agregar el formato.',
                style: Brand.text(size: 12, color: Brand.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
