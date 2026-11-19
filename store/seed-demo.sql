-- =====================================================
-- Datos demo para las capturas de Play Store
-- =====================================================
-- Carga datos de ejemplo en la cuenta test@gmail.com (usuarios.id = 10):
-- nombre "Laura Gómez", categorías, 4 cuentas, movimientos de octubre y del
-- 1 de noviembre de 2026, presupuestos de noviembre, 2 metas y 2 préstamos.
-- Solo toca filas del usuario 10. Fechas en hora de Colombia (como la app).
-- =====================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @U BIGINT = 10;
DECLARE @G BIGINT = (SELECT id FROM tipos_transaccion WHERE nombre = 'GASTO');
DECLARE @I BIGINT = (SELECT id FROM tipos_transaccion WHERE nombre = 'INGRESO');

IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = @U AND email = 'test@gmail.com')
  THROW 50000, 'El usuario 10 no es test@gmail.com', 1;
IF EXISTS (SELECT 1 FROM transacciones WHERE usuario_id = @U)
  THROW 50000, 'El usuario 10 ya tiene movimientos: no se carga dos veces', 1;

BEGIN TRAN;

UPDATE usuarios SET nombre = N'Laura Gómez', fecha_actualizacion = '2026-11-01T23:40:00' WHERE id = @U;
DELETE FROM cuentas WHERE usuario_id = @U AND nombre = 'test';

-- ── Categorías ──────────────────────────────────────────────────────────
INSERT INTO categorias (usuario_id, nombre, icono, color, tipo, activo, fecha_creacion) VALUES
 (@U, N'Mercado',       'shopping_cart',  '#0B6E4F', 'GASTO',   1, '2026-09-30T10:00:00'),
 (@U, N'Restaurantes',  'restaurant',     '#B4531A', 'GASTO',   1, '2026-09-30T10:00:00'),
 (@U, N'Transporte',    'directions_car', '#1F5FAD', 'GASTO',   1, '2026-09-30T10:00:00'),
 (@U, N'Servicios',     'bolt',           '#8A6A00', 'GASTO',   1, '2026-09-30T10:00:00'),
 (@U, N'Suscripciones', 'computer',       '#10201B', 'GASTO',   1, '2026-09-30T10:00:00'),
 (@U, N'Salud',         'local_hospital', '#B4531A', 'GASTO',   1, '2026-09-30T10:00:00'),
 (@U, N'Ocio',          'star',           '#6B3FA0', 'GASTO',   1, '2026-09-30T10:00:00'),
 (@U, N'Ropa',          'checkroom',      '#B4531A', 'GASTO',   1, '2026-09-30T10:00:00'),
 (@U, N'Café',          'local_cafe',     '#8A6A00', 'GASTO',   1, '2026-09-30T10:00:00'),
 (@U, N'Hogar',         'home',           '#10201B', 'GASTO',   1, '2026-09-30T10:00:00'),
 (@U, N'Salario',       'work',           '#0B6E4F', 'INGRESO', 1, '2026-09-30T10:00:00'),
 (@U, N'Freelance',     'sell',           '#1F5FAD', 'INGRESO', 1, '2026-09-30T10:00:00');

DECLARE @cMer BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Mercado');
DECLARE @cRes BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Restaurantes');
DECLARE @cTra BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Transporte');
DECLARE @cSer BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Servicios');
DECLARE @cSus BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Suscripciones');
DECLARE @cSal BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Salud');
DECLARE @cOci BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Ocio');
DECLARE @cRop BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Ropa');
DECLARE @cCaf BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Café');
DECLARE @cHog BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Hogar');
DECLARE @cSla BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Salario');
DECLARE @cFre BIGINT = (SELECT id FROM categorias WHERE usuario_id=@U AND nombre=N'Freelance');

-- ── Cuentas ─────────────────────────────────────────────────────────────
INSERT INTO cuentas (usuario_id, nombre, tipo, moneda, saldo_inicial, color, icono, descripcion, activa, fecha_creacion, saldo_reservado, cupo, dia_corte, dia_pago) VALUES
 (@U, N'Bancolombia', 'BANCARIA',        'COP', 1800000, '#0B6E4F', 'account_balance', N'Cuenta de nómina', 1, '2026-09-30T10:00:00', 0, NULL, NULL, NULL),
 (@U, N'Nequi',       'DIGITAL',         'COP',  150000, '#1F5FAD', 'wallet',          NULL,               1, '2026-09-30T10:00:00', 0, NULL, NULL, NULL),
 (@U, N'Efectivo',    'EFECTIVO',        'COP',  120000, '#0B6E4F', 'payments',        NULL,               1, '2026-09-30T10:00:00', 0, NULL, NULL, NULL),
 (@U, N'Tarjeta Visa','TARJETA_CREDITO', 'COP',       0, '#B4531A', 'credit_card',     NULL,               1, '2026-09-30T10:00:00', 0, 5000000, 25, 10);

DECLARE @aBan BIGINT = (SELECT id FROM cuentas WHERE usuario_id=@U AND nombre=N'Bancolombia');
DECLARE @aNeq BIGINT = (SELECT id FROM cuentas WHERE usuario_id=@U AND nombre=N'Nequi');
DECLARE @aEfe BIGINT = (SELECT id FROM cuentas WHERE usuario_id=@U AND nombre=N'Efectivo');
DECLARE @aTar BIGINT = (SELECT id FROM cuentas WHERE usuario_id=@U AND nombre=N'Tarjeta Visa');

-- ── Movimientos ─────────────────────────────────────────────────────────
DECLARE @m TABLE (cuenta BIGINT, tipo BIGINT, cat BIGINT, monto DECIMAL(18,2), titulo NVARCHAR(200), fecha DATETIME2(0), notas NVARCHAR(500));
INSERT INTO @m VALUES
 (@aBan, @G, @cHog, 1200000, N'Arriendo',               '2026-10-01T09:10:00', NULL),
 (@aBan, @G, @cMer,  185400, N'Éxito',                  '2026-10-02T18:25:00', N'Registrado automáticamente · Bancolombia · tarjeta *4771'),
 (@aBan, @G, @cSer,   96300, N'Factura de luz',         '2026-10-05T08:40:00', NULL),
 (@aTar, @G, @cSus,   26900, N'Netflix',                '2026-10-07T07:00:00', NULL),
 (@aTar, @G, @cRes,   58000, N'Cena con amigos',        '2026-10-09T20:15:00', NULL),
 (@aNeq, @G, @cTra,    9200, N'Bus',                    '2026-10-12T07:35:00', NULL),
 (@aNeq, @G, @cTra,   70000, N'Gasolina',               '2026-10-14T17:50:00', NULL),
 (@aBan, @I, @cSla, 1600000, N'Quincena',               '2026-10-15T06:00:00', NULL),
 (@aBan, @G, @cMer,  142800, N'D1',                     '2026-10-16T19:05:00', N'Registrado automáticamente · Bancolombia · tarjeta *4771'),
 (@aTar, @G, @cOci,   48000, N'Cine',                   '2026-10-18T21:10:00', NULL),
 (@aEfe, @G, @cCaf,   12500, N'Juan Valdez',            '2026-10-20T10:20:00', NULL),
 (@aBan, @G, @cSal,   34900, N'Farmacia',               '2026-10-22T12:30:00', NULL),
 (@aTar, @G, @cRop,  159900, N'Zara',                   '2026-10-24T16:45:00', NULL),
 (@aBan, @G, @cRes,   72000, N'Almuerzo familiar',      '2026-10-26T14:00:00', NULL),
 (@aNeq, @I, @cFre,  450000, N'Diseño de logo',         '2026-10-28T11:15:00', N'Registrado automáticamente · Nequi'),
 (@aBan, @I, @cSla, 1600000, N'Quincena',               '2026-10-30T06:00:00', NULL),
 (@aBan, @G, @cMer,   98600, N'Carulla',                '2026-10-31T18:40:00', NULL),
 (@aEfe, @G, @cCaf,    9800, N'Café',                   '2026-11-01T08:15:00', NULL),
 (@aNeq, @G, @cTra,    7500, N'Bus',                    '2026-11-01T08:40:00', NULL),
 (@aBan, @G, @cMer,  214300, N'Éxito',                  '2026-11-01T11:20:00', N'Registrado automáticamente · Bancolombia · tarjeta *4771'),
 (@aTar, @G, @cRes,   64000, N'Almuerzo',               '2026-11-01T13:30:00', NULL),
 (@aTar, @G, @cSus,   16900, N'Spotify',                '2026-11-01T15:00:00', NULL);

INSERT INTO transacciones (usuario_id, cuenta_id, tipo_transaccion_id, categoria_id, metodo_pago_id, monto, moneda, titulo, descripcion, fecha_transaccion, archivo_adjunto, notas, repetir, activa, fecha_creacion)
SELECT @U, cuenta, tipo, cat, NULL, monto, 'COP', titulo, NULL, fecha, NULL, notas, 0, 1, fecha FROM @m;

-- ── Metas y aportes ─────────────────────────────────────────────────────
INSERT INTO metas (usuario_id, nombre, descripcion, monto_objetivo, monto_actual, fecha_objetivo, icono, color, activa, fecha_creacion, fecha_actualizacion, aporte_auto_porcentaje, aporte_auto_minimo) VALUES
 (@U, N'Viaje a Cartagena',   N'Vacaciones de mitad de año', 3000000, 0, '2027-06-30T00:00:00', NULL, NULL, 1, '2026-07-01T10:00:00', '2026-10-30T06:00:00', 10, 500000),
 (@U, N'Fondo de emergencia', N'Tres meses de gastos',       5000000, 0, '2027-12-31T00:00:00', NULL, NULL, 1, '2026-06-01T10:00:00', '2026-09-30T10:00:00', NULL, NULL);
DECLARE @mViaje BIGINT = (SELECT id FROM metas WHERE usuario_id=@U AND nombre=N'Viaje a Cartagena');
DECLARE @mFondo BIGINT = (SELECT id FROM metas WHERE usuario_id=@U AND nombre=N'Fondo de emergencia');

-- Ahorro previo (sin cuenta: solo suma a la meta)
INSERT INTO aportes_metas (meta_id, cuenta_id, monto_aporte, fecha_aporte, notas, transaccion_id) VALUES
 (@mViaje, NULL,  880000, '2026-09-30T10:00:00', N'Lo que ya tenía ahorrado', NULL),
 (@mFondo, NULL, 2150000, '2026-09-30T10:00:00', N'Lo que ya tenía ahorrado', NULL);

-- Aportes automáticos del 10% de cada quincena (salen de Bancolombia)
DECLARE @t1 BIGINT, @t2 BIGINT;
INSERT INTO transacciones (usuario_id, cuenta_id, tipo_transaccion_id, categoria_id, monto, moneda, titulo, fecha_transaccion, notas, repetir, activa, fecha_creacion)
VALUES (@U, @aBan, @G, NULL, 160000, 'COP', N'Aporte automático a meta: Viaje a Cartagena', '2026-10-15T06:00:00', N'Registrado automáticamente · 10.00% de un ingreso', 0, 1, '2026-10-15T06:00:00');
SET @t1 = SCOPE_IDENTITY();
INSERT INTO transacciones (usuario_id, cuenta_id, tipo_transaccion_id, categoria_id, monto, moneda, titulo, fecha_transaccion, notas, repetir, activa, fecha_creacion)
VALUES (@U, @aBan, @G, NULL, 160000, 'COP', N'Aporte automático a meta: Viaje a Cartagena', '2026-10-30T06:00:00', N'Registrado automáticamente · 10.00% de un ingreso', 0, 1, '2026-10-30T06:00:00');
SET @t2 = SCOPE_IDENTITY();
INSERT INTO aportes_metas (meta_id, cuenta_id, monto_aporte, fecha_aporte, notas, transaccion_id) VALUES
 (@mViaje, @aBan, 160000, '2026-10-15T06:00:00', N'Aporte automático', @t1),
 (@mViaje, @aBan, 160000, '2026-10-30T06:00:00', N'Aporte automático', @t2);

UPDATE metas SET monto_actual = (SELECT SUM(monto_aporte) FROM aportes_metas a WHERE a.meta_id = metas.id)
WHERE usuario_id = @U;

-- ── Presupuestos de noviembre ───────────────────────────────────────────
INSERT INTO presupuestos (usuario_id, nombre, categoria_id, cuenta_id, periodo, fecha_inicio, fecha_fin, monto_limite, monto_gastado, activo, notas, fecha_creacion, fecha_actualizacion) VALUES
 (@U, N'Mercado',          @cMer, NULL, 'MENSUAL', '2026-11-01', '2026-11-30',  300000, 0, 1, NULL, '2026-11-01T07:00:00', '2026-11-01T07:00:00'),
 (@U, N'Restaurantes',     @cRes, NULL, 'MENSUAL', '2026-11-01', '2026-11-30',  100000, 0, 1, NULL, '2026-11-01T07:00:00', '2026-11-01T07:00:00'),
 (@U, N'Todos los gastos', NULL,  NULL, 'MENSUAL', '2026-11-01', '2026-11-30', 2500000, 0, 1, NULL, '2026-11-01T07:00:00', '2026-11-01T07:00:00');

COMMIT TRAN;

-- Gastado de cada presupuesto, con la misma regla de la app
EXEC sp_meta_recalcular_presupuestos @UsuarioId = @U, @Fecha = '2026-11-01T23:00:00';

-- ── Préstamos (por el mismo camino que el API) ──────────────────────────
-- Crédito en cuotas: 10.000.000 al 24% E.A., 24 cuotas de 517.326, 6 pagadas.
-- montoTotal = cuota × cuotas restantes (18); próxima: la 7, el 10 de noviembre.
EXEC sp_prestamo_create @UsuarioId = @U, @Nombre = N'Crédito Bancolombia', @Tipo = 'DEUDA',
  @MontoTotal = 9311868, @TasaInteres = 24, @FechaInicio = '2026-04-10', @FechaFin = '2028-04-10',
  @CuentaId = @aBan, @Notas = N'Crédito de libre inversión', @NombreDeudorPrestador = N'Crédito Bancolombia',
  @RegistrarMovimiento = 0, @MontoMovimiento = NULL;
UPDATE prestamos SET monto_prestado = 10000000, tipo_tasa = 'EA', numero_cuotas = 24, valor_cuota = 517326,
  dia_pago = 10, fecha_primera_cuota = '2026-05-10', cuotas_previas = 6
WHERE usuario_id = @U AND nombre = N'Crédito Bancolombia';

EXEC sp_prestamo_create @UsuarioId = @U, @Nombre = N'Carlos', @Tipo = 'PRESTAMO',
  @MontoTotal = 300000, @TasaInteres = NULL, @FechaInicio = '2026-10-20', @FechaFin = '2026-11-20',
  @CuentaId = NULL, @Notas = N'Para el arreglo de la moto', @NombreDeudorPrestador = N'Carlos',
  @RegistrarMovimiento = 0, @MontoMovimiento = NULL;
