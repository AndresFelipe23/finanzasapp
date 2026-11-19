import 'package:flutter_test/flutter_test.dart';
import 'package:finanzasapp/core/models/prestamo_models.dart';
import 'package:finanzasapp/core/theme/brand_form.dart';

void main() {
  test('parsea importes con coma o punto decimal y miles', () {
    expect(parseAmount('1.338.194,87'), 1338194.87);
    expect(parseAmount('1,338,194.87'), 1338194.87);
    expect(parseAmount('919.600'), 919600);
    expect(parseAmount('3,99'), 3.99);
    expect(parseAmount('97.928,53'), 97928.53);
    expect(parseAmount('12.34.567'), isNull);
  });

  test('envía el tipo de tasa seleccionado aunque la tasa esté vacía', () {
    final request = CreatePrestamoRequest(
      nombre: 'Crédito',
      tipo: 'DEUDA',
      montoTotal: 1200,
      cuotas: true,
      tipoTasa: 'MV',
    );

    expect(request.toJson()['tipoTasa'], 'MV');
  });

  test('separa cargos adicionales de los intereses del crédito', () {
    final tasaMensual = Prestamo.tasaMensualDe(60, 'EA')!;
    final cuotaBase = Prestamo.cuotaFija(919600, tasaMensual, 12);
    final prestamo = Prestamo(
      id: 1,
      usuarioId: 1,
      cuentaId: null,
      nombre: 'Compra',
      tipo: 'DEUDA',
      montoTotal: (cuotaBase + 162751.62 / 12) * 12,
      saldoPendiente: (cuotaBase + 162751.62 / 12) * 12,
      tasaInteres: 60,
      fechaInicio: DateTime(2026, 10, 4),
      fechaFin: DateTime(2027, 10, 4),
      notas: null,
      activa: true,
      fechaCreacion: DateTime(2026, 10, 4),
      fechaActualizacion: DateTime(2026, 10, 4),
      montoPrestado: 919600,
      cargoAdicionalNombre: 'Servicio de fianza',
      cargoAdicionalTotal: 162751.62,
      tipoTasa: 'EA',
      numeroCuotas: 12,
      valorCuota: cuotaBase,
    );

    expect(tasaMensual, closeTo(0.0399441, 0.0000001));
    expect(prestamo.cuotaTotal, closeTo(111516.24, 0.01));
    expect(prestamo.totalIntereses, closeTo(255843.25, 0.01));
    expect(prestamo.totalAPagar, closeTo(1338194.87, 0.01));
    expect(prestamo.tabla().first.cargoAdicional, closeTo(13562.635, 0.001));
  });

  test('muestra el capital vigente y proyecta solo cuotas posteriores', () {
    const capitalVigente = 143219.54;
    const cuota = 10806.96;
    const cuotasOriginales = 29;
    const cuotasPrevias = 3;
    final totalFuturo = cuota * (cuotasOriginales - cuotasPrevias);
    final prestamo = Prestamo(
      id: 2,
      usuarioId: 9,
      cuentaId: null,
      nombre: 'Crédito agua',
      tipo: 'DEUDA',
      montoTotal: totalFuturo,
      saldoPendiente: totalFuturo,
      tasaInteres: 3.85,
      fechaInicio: DateTime(2026, 7, 27),
      fechaFin: DateTime(2028, 8, 27),
      notas: null,
      activa: true,
      fechaCreacion: DateTime(2026, 10, 30),
      fechaActualizacion: DateTime(2026, 10, 30),
      montoPrestado: capitalVigente,
      tipoTasa: 'MV',
      numeroCuotas: cuotasOriginales,
      valorCuota: cuota,
      cuotasPrevias: cuotasPrevias,
    );

    expect(prestamo.cuotasPagadas, cuotasPrevias);
    expect(prestamo.capitalPendiente, capitalVigente);
    expect(prestamo.saldoPendiente, closeTo(280980.96, 0.01));
    expect(prestamo.totalAPagar, closeTo(280980.96, 0.01));
    expect(
      prestamo.tabla().take(cuotasPrevias).every((c) => c.interes == null),
      isTrue,
    );
    expect(
      prestamo.tabla()[cuotasPrevias].interes,
      closeTo(capitalVigente * 0.0385, 0.01),
    );

    final despuesDePago = Prestamo(
      id: 2,
      usuarioId: 9,
      cuentaId: null,
      nombre: 'Crédito agua',
      tipo: 'DEUDA',
      montoTotal: totalFuturo,
      saldoPendiente: totalFuturo - cuota,
      tasaInteres: 3.85,
      fechaInicio: DateTime(2026, 7, 27),
      fechaFin: DateTime(2028, 8, 27),
      notas: null,
      activa: true,
      fechaCreacion: DateTime(2026, 10, 30),
      fechaActualizacion: DateTime(2026, 10, 30),
      montoPrestado: capitalVigente,
      tipoTasa: 'MV',
      numeroCuotas: cuotasOriginales,
      valorCuota: cuota,
      cuotasPrevias: cuotasPrevias,
    );
    expect(despuesDePago.cuotasPagadas, cuotasPrevias + 1);
    expect(
      despuesDePago.capitalPendiente,
      closeTo(despuesDePago.tabla()[cuotasPrevias].saldoCapital!, 0.01),
    );
  });
}
