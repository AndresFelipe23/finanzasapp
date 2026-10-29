import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_client.dart';
import '../../core/models/auth_models.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/navigation/main_navigation.dart';
import '../../core/theme/brand.dart';
import '../accounts/accounts_service.dart';
import '../transactions/transactions_service.dart';

/// Registro · paso 2: la primera cuenta. El usuario ya existe en este punto,
/// por eso no hay botón de volver (repetir el paso 1 daría "correo en uso").
class RegisterAccountScreen extends StatefulWidget {
  const RegisterAccountScreen({super.key, required this.user});

  final UserResponse user;

  @override
  State<RegisterAccountScreen> createState() => _RegisterAccountScreenState();
}

class _AccountType {
  const _AccountType(this.tipo, this.label, this.name, this.icon, this.icono,
      this.fg, this.bg);

  final String tipo; // valor de la columna cuentas.tipo
  final String label;
  final String name; // nombre sugerido
  final IconData icon;
  final String icono; // nombre guardado en cuentas.icono
  final Color fg;
  final Color bg;
}

const _types = [
  _AccountType('BANCARIA', 'Cuenta bancaria', 'Mi cuenta bancaria',
      Icons.account_balance_outlined, 'account_balance', Brand.accent, Brand.accentSoft),
  _AccountType('EFECTIVO', 'Efectivo', 'Efectivo', Icons.payments_outlined,
      'payments', Brand.accent, Brand.accentSoft),
  _AccountType('TARJETA_DEBITO', 'Tarjeta de débito', 'Tarjeta de débito',
      Icons.credit_card_outlined, 'credit_card', Brand.blue, Brand.blueSoft),
  _AccountType('TARJETA_CREDITO', 'Tarjeta de crédito', 'Tarjeta de crédito',
      Icons.credit_card_outlined, 'credit_card', Brand.expense, Brand.expenseSoft),
];

class _RegisterAccountScreenState extends State<RegisterAccountScreen> {
  final _nameCtrl = TextEditingController(text: _types.first.name);
  final _amountCtrl = TextEditingController();
  final _api = ApiClient();
  _AccountType _type = _types.first;
  bool _nameEdited = false;
  bool _loading = false;

  String get _moneda => widget.user.monedaPredeterminada ?? 'COP';
  bool get _isCredit => _type.tipo == 'TARJETA_CREDITO';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _pick(_AccountType t) {
    setState(() {
      _type = t;
      // Solo se reemplaza el nombre si el usuario no lo escribió a mano
      if (!_nameEdited) _nameCtrl.text = t.name;
    });
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainNavigation(user: widget.user)),
      (_) => false,
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showBrandSnack(context, 'Ponle un nombre a la cuenta');
      return;
    }
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;

    setState(() => _loading = true);
    try {
      final cuenta = await AccountsService(_api).createAccount(
        CreateCuentaRequest(
          nombre: name,
          tipo: _type.tipo,
          moneda: _moneda,
          // La API no acepta saldo inicial negativo: la deuda de la tarjeta
          // se registra abajo como un gasto de apertura
          saldoInicial: _isCredit ? 0 : amount,
          color: _hex(_type.fg),
          icono: _type.icono,
        ),
      );
      if (_isCredit && amount > 0) {
        await TransactionsService(_api).createTransaction(
          CreateTransaccionRequest(
            cuentaId: cuenta.id,
            tipoTransaccionId: 2, // GASTO
            monto: amount,
            moneda: _moneda,
            titulo: 'Deuda inicial de la tarjeta',
            fechaTransaccion: DateTime.now(),
          ),
        );
      }
      if (mounted) _goHome();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Paso 2 de 2',
                  style: Brand.text(
                    size: 13,
                    weight: FontWeight.w700,
                    color: Brand.muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Brand.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Agrega tu primera cuenta', style: Brand.title()),
            const SizedBox(height: 8),
            Text(
              'Elige dónde tienes tu dinero y cuánto hay hoy. Podrás agregar '
              'más cuentas después.',
              style: Brand.text(color: Brand.muted, height: 1.45),
            ),
            const SizedBox(height: 22),
            Text(
              'Tipo de cuenta',
              style: Brand.text(size: 13, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                for (final t in _types) _TypeTile(
                  type: t,
                  selected: t == _type,
                  onTap: () => _pick(t),
                ),
              ],
            ),
            const SizedBox(height: 22),
            BrandField(
              label: 'Nombre de la cuenta',
              controller: _nameCtrl,
              onChanged: (_) => _nameEdited = true,
            ),
            const SizedBox(height: 22),
            Text(
              _isCredit ? 'Deuda actual' : 'Saldo inicial',
              style: Brand.text(size: 13, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Brand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Brand.accent, width: 1.5),
              ),
              child: Row(
                children: [
                  Text(
                    '\$',
                    style: Brand.text(
                      size: 24,
                      weight: FontWeight.w800,
                      color: Brand.muted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: Brand.text(size: 26, weight: FontWeight.w800),
                      cursorColor: Brand.accent,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: Brand.text(
                          size: 26,
                          weight: FontWeight.w800,
                          color: Brand.inputBorder,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Brand.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _moneda,
                      style: Brand.text(
                        size: 12,
                        weight: FontWeight.w800,
                        color: Brand.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isCredit
                  ? 'Lo que debes hoy en la tarjeta. Usa 0 si está al corriente.'
                  : 'El dinero que tienes hoy en esta cuenta.',
              style: Brand.text(size: 12, color: Brand.muted),
            ),
            const SizedBox(height: 32),
            BrandButton(
              label: 'Ir a mi inicio',
              loading: _loading,
              onPressed: _save,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loading ? null : _goHome,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: Text(
                'Lo haré después',
                style: Brand.text(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Brand.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final _AccountType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Brand.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? Brand.accent : Brand.border,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: type.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(type.icon, size: 20, color: type.fg),
                ),
                Text(
                  type.label,
                  style: Brand.text(size: 14, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
