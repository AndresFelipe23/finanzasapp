// Prueba de humo del formulario de préstamos: calcula la cuota en vivo y
// abre la vista previa de la tabla de amortización.
import 'package:finanzasapp/core/api/api_client.dart';
import 'package:finanzasapp/core/models/cuenta_models.dart';
import 'package:finanzasapp/core/models/prestamo_models.dart';
import 'package:finanzasapp/core/theme/brand_keypad.dart';
import 'package:finanzasapp/features/accounts/accounts_provider.dart';
import 'package:finanzasapp/features/accounts/accounts_service.dart';
import 'package:finanzasapp/features/prestamos/create_edit_prestamo_screen.dart';
import 'package:finanzasapp/features/prestamos/prestamos_provider.dart';
import 'package:finanzasapp/features/prestamos/prestamos_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeAccountsService extends AccountsService {
  _FakeAccountsService() : super(ApiClient());

  @override
  Future<List<Cuenta>> getAllAccounts({String? tipo}) async => const <Cuenta>[];
}

class _FakePrestamosService extends PrestamosService {
  _FakePrestamosService() : super(ApiClient());

  @override
  Future<List<Prestamo>> getAll({bool? activos}) async => const <Prestamo>[];
}

void main() {
  setUpAll(() async {
    // Sin red en las pruebas: si falta la fuente se usa la del sistema.
    GoogleFonts.config.allowRuntimeFetching = false;
    // La app carga los símbolos con GlobalMaterialLocalizations; aquí se
    // inicializan directamente porque el MaterialApp de prueba es mínimo.
    await initializeDateFormatting('es_ES');
  });

  testWidgets('calcula la cuota y abre la tabla de amortización', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsNotifierProvider.overrideWith(
            (ref) => AccountsNotifier(_FakeAccountsService()),
          ),
          prestamosNotifierProvider.overrideWith(
            (ref) => PrestamosNotifier(_FakePrestamosService()),
          ),
        ],
        child: const MaterialApp(home: CreateEditPrestamoScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Debo'), findsOneWidget);
    expect(find.text('Pago único'), findsOneWidget);
    expect(find.text('En cuotas'), findsOneWidget);

    // El monto se escribe con el teclado propio: 2.400.000
    Finder tecla(String t) => find.descendant(
      of: find.byType(AmountKeypad),
      matching: find.text(t),
    );
    for (final t in ['2', '4', '0', '0', '000']) {
      await tester.tap(tecla(t));
    }
    await tester.enterText(find.byKey(const Key('prestamo-nombre')), 'Banco');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('2.400.000'), findsOneWidget);

    await tester.tap(find.text('En cuotas'));
    await tester.pumpAndSettle();
    expect(find.text('Capital del crédito, sin intereses'), findsOneWidget);

    // Los datos del crédito están en su hoja
    await tester.tap(find.text('Cuotas'));
    await tester.pumpAndSettle();
    expect(find.text('Datos del crédito'), findsOneWidget);

    await tester.ensureVisible(find.text('24'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('CUOTA MENSUAL'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('CUOTA MENSUAL'), findsOneWidget);
    expect(find.text('Total a pagar'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ver tabla de amortización'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver tabla de amortización'));
    await tester.pumpAndSettle();

    expect(find.text('Tabla de amortización'), findsWidgets);
  });
}
