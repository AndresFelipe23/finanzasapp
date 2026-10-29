import 'package:flutter/material.dart';
import '../../core/theme/brand.dart';
import '../transactions/create_transaction_screen.dart';
import '../transactions/create_transfer_screen.dart';

/// Hoja para elegir el tipo de movimiento (botón + de la barra inferior).
void showNewTransactionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Brand.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => SafeArea(
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
            Text(
              'Nuevo movimiento',
              style: Brand.text(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _Option(
              icon: Icons.add_rounded,
              fg: Brand.accent,
              bg: Brand.accentSoft,
              title: 'Ingreso',
              subtitle: 'Dinero que recibes',
              onTap: () => _open(
                sheetCtx,
                const CreateTransactionScreen(tipoTransaccion: 'INGRESO'),
              ),
            ),
            _Option(
              icon: Icons.remove_rounded,
              fg: Brand.expense,
              bg: Brand.expenseSoft,
              title: 'Gasto',
              subtitle: 'Dinero que sale',
              onTap: () => _open(
                sheetCtx,
                const CreateTransactionScreen(tipoTransaccion: 'GASTO'),
              ),
            ),
            _Option(
              icon: Icons.swap_horiz_rounded,
              fg: Brand.blue,
              bg: Brand.blueSoft,
              title: 'Transferencia',
              subtitle: 'Mover dinero entre tus cuentas',
              onTap: () => _open(sheetCtx, const CreateTransferScreen()),
            ),
          ],
        ),
      ),
    ),
  );
}

void _open(BuildContext sheetCtx, Widget screen) {
  final nav = Navigator.of(sheetCtx, rootNavigator: true);
  nav.pop();
  nav.push(MaterialPageRoute(builder: (_) => screen));
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.fg,
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color fg;
  final Color bg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Brand.text(weight: FontWeight.w700)),
                  Text(
                    subtitle,
                    style: Brand.text(size: 13, color: Brand.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Brand.muted),
          ],
        ),
      ),
    );
  }
}
