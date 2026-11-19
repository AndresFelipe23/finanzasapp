// Prueba del listado de préstamos: resumen, alertas de vencimiento,
// contadores por pestaña y tarjetas compactas de pagados.
import 'package:finanzasapp/core/api/api_client.dart';
import 'package:finanzasapp/core/models/prestamo_models.dart';
import 'package:finanzasapp/features/prestamos/prestamos_provider.dart';
import 'package:finanzasapp/features/prestamos/prestamos_screen.dart';
import 'package:finanzasapp/features/prestamos/prestamos_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakePrestamosService extends PrestamosService {
  _FakePrestamosService(this.items) : super(ApiClient());

  final List<Prestamo> items;

  @override
  Future<List<Prestamo>> getAll({bool? activos}) async => items;
}

Prestamo _prestamo({
  required int id,
  required String nombre,
  String tipo = 'DEUDA',
  double montoTotal = 12000000,
  double saldoPendiente = 12000000,
  double? tasaInteres = 1.2,
  int? numeroCuotas = 24,
  double? valorCuota = 500000,
  double? montoPrestado = 9000000,
  DateTime? primeraCuota,
  DateTime? fechaFin,
  bool activa = true,
  String? estado,
  DateTime? actualizado,
}) {
  final ahora = DateTime.now();
  return Prestamo(
    id: id,
    usuarioId: 1,
    cuentaId: null,
    nombre: nombre,
    tipo: tipo,
    montoTotal: montoTotal,
    saldoPendiente: saldoPendiente,
    tasaInteres: tasaInteres,
    fechaInicio: DateTime(ahora.year - 1),
    fechaFin: fechaFin,
    notas: null,
    activa: activa,
    estado: estado,
    fechaCreacion: DateTime(ahora.year - 1),
    fechaActualizacion: actualizado ?? ahora,
    montoPrestado: montoPrestado,
    cargoAdicionalNombre: null,
    cargoAdicionalTotal: null,
    tipoTasa: numeroCuotas == null ? null : 'MV',
    numeroCuotas: numeroCuotas,
    valorCuota: valorCuota,
    diaPago: primeraCuota?.day,
    fechaPrimeraCuota: primeraCuota,
    cuotasPrevias: null,
  );
}

List<Prestamo> _cartera() {
  final ahora = DateTime.now();
  return [
    _prestamo(
      id: 1,
      nombre: 'Banco Nacional',
      primeraCuota: ahora.subtract(const Duration(days: 40)),
    ),
    _prestamo(
      id: 2,
      nombre: 'Crédito del carro',
      montoTotal: 6000000,
      saldoPendiente: 6000000,
      valorCuota: 250000,
      montoPrestado: 5000000,
      primeraCuota: DateUtils.dateOnly(ahora).add(const Duration(days: 3)),
    ),
    _prestamo(
      id: 3,
      nombre: 'Préstamo viejo',
      montoTotal: 2000000,
      saldoPendiente: 0,
      tasaInteres: null,
      numeroCuotas: null,
      valorCuota: null,
      montoPrestado: null,
      estado: 'PAGADO',
      fechaFin: ahora.subtract(const Duration(days: 30)),
      actualizado: ahora.subtract(const Duration(days: 20)),
    ),
    _prestamo(
      id: 4,
      nombre: 'Carlos',
      tipo: 'PRESTAMO',
      montoTotal: 1500000,
      saldoPendiente: 750000,
      tasaInteres: null,
      numeroCuotas: null,
      valorCuota: null,
      montoPrestado: null,
      fechaFin: ahora.add(const Duration(days: 30)),
    ),
  ];
}

Future<void> _montar(WidgetTester tester, List<Prestamo> items) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prestamosNotifierProvider.overrideWith(
          (ref) => PrestamosNotifier(_FakePrestamosService(items)),
        ),
      ],
      child: const MaterialApp(home: PrestamosScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Text _contador(WidgetTester tester, String tab) => tester.widget<Text>(
  find.descendant(
    of: find.byKey(ValueKey('count-$tab')),
    matching: find.byType(Text),
  ),
);

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es_ES');
  });

  testWidgets('resume el capital, marca vencidos y compacta los pagados', (
    tester,
  ) async {
    await _montar(tester, _cartera());

    expect(find.text('Préstamos'), findsOneWidget);
    expect(find.text('Capital vigente total'), findsOneWidget);
    expect(find.textContaining('14.000.000'), findsWidgets);
    expect(find.textContaining('Intereses por pagar'), findsOneWidget);
    expect(find.text('2 activos'), findsOneWidget);
    expect(find.text('1 vencido'), findsOneWidget);
    expect(find.text('1 esta semana'), findsOneWidget);

    // La primera tarjeta está vencida y la segunda vence pronto.
    expect(find.textContaining('Venció hace'), findsOneWidget);
    expect(find.textContaining('Vence en 3 días'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('PAGADOS · 1'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('PAGADOS · 1'), findsOneWidget);

    // Los pagados muestran el total del préstamo, no un saldo de cero.
    expect(find.textContaining('2.000.000'), findsOneWidget);
  });

  testWidgets('cambia de pestaña y cuenta solo los préstamos activos', (
    tester,
  ) async {
    await _montar(tester, _cartera());

    expect(_contador(tester, 'debo').data, '2');
    expect(_contador(tester, 'meDeben').data, '1');

    await tester.tap(find.text('Me deben'));
    await tester.pumpAndSettle();

    expect(find.text('Por cobrar'), findsOneWidget);
    expect(find.text('1 por cobrar'), findsOneWidget);
    expect(find.text('Todo al día'), findsOneWidget);
    expect(find.textContaining('Te falta cobrar'), findsOneWidget);
    expect(find.textContaining('750.000'), findsWidgets);
    expect(find.text('Carlos'), findsOneWidget);
  });

  testWidgets('abre las opciones desde el botón de la tarjeta', (tester) async {
    await _montar(tester, _cartera());

    await tester.tap(find.byTooltip('Opciones').first);
    await tester.pumpAndSettle();

    expect(find.text('Ver cuotas'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });
}
