import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../tarjetas_nfc/tarjetas_nfc_provider.dart' as tprov;
import 'pagos_nfc_provider.dart';
import '../../core/models/pago_nfc_models.dart';
import '../../core/device/device_registry.dart';

class PagosNfcHistoryScreen extends ConsumerStatefulWidget {
  const PagosNfcHistoryScreen({super.key});

  @override
  ConsumerState<PagosNfcHistoryScreen> createState() =>
      _PagosNfcHistoryScreenState();
}

class _PagosNfcHistoryScreenState extends ConsumerState<PagosNfcHistoryScreen> {
  int? _tarjetaFiltroId;
  DateTimeRange? _rango;

  @override
  Widget build(BuildContext context) {
    final pagosAsync = ref.watch(pagosNfcProvider);
    final tarjetasAsync = ref.watch(tprov.tarjetasNfcProvider);

    List<PagoNfc> filtrar(List<PagoNfc> items) {
      var list = items;
      if (_tarjetaFiltroId != null) {
        list = list.where((p) => p.tarjetaNfcId == _tarjetaFiltroId).toList();
      }
      if (_rango != null) {
        list = list
            .where(
              (p) =>
                  p.fechaPago.isAfter(
                    _rango!.start.subtract(const Duration(seconds: 1)),
                  ) &&
                  p.fechaPago.isBefore(
                    _rango!.end.add(const Duration(seconds: 1)),
                  ),
            )
            .toList();
      }
      list.sort((a, b) => b.fechaPago.compareTo(a.fechaPago));
      return list;
    }

    // Calcular resumen para UI
    double totalFiltrado(List<PagoNfc> items) =>
        filtrar(items).fold(0.0, (s, p) => s + p.monto);
    int cantidadFiltrada(List<PagoNfc> items) => filtrar(items).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Pagos NFC',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              'Filtra y consulta tus pagos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
            onPressed: () => ref
                .read(pagosNfcProvider.notifier)
                .refresh(tarjetaId: _tarjetaFiltroId),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filtro por tarjeta
                tarjetasAsync.when(
                  data: (tarjetas) {
                    final items = [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            SizedBox(width: 8),
                            Text('Todas las tarjetas'),
                          ],
                        ),
                      ),
                      ...tarjetas.map((t) {
                        final color =
                            _parseColor(t.color) ?? const Color(0xFF3B82F6);
                        return DropdownMenuItem<int?>(
                          value: t.id,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${t.nombrePortador} • ${t.banco ?? 'N/A'}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ];
                    return DropdownButtonFormField<int?>(
                      initialValue: _tarjetaFiltroId,
                      items: items,
                      onChanged: (v) {
                        setState(() => _tarjetaFiltroId = v);
                        ref
                            .read(pagosNfcProvider.notifier)
                            .refresh(tarjetaId: v);
                      },
                      decoration: InputDecoration(
                        labelText: 'Filtrar por tarjeta',
                        prefixIcon: const Icon(
                          Icons.credit_card,
                          color: Color(0xFF3B82F6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Error al cargar tarjetas: $e'),
                ),
                const SizedBox(height: 12),
                // Filtro por rango de fechas
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 2),
                      initialDateRange: _rango,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF3B82F6),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => _rango = picked);
                  },
                  icon: const Icon(Icons.date_range, color: Color(0xFF3B82F6)),
                  label: Text(
                    _rango == null
                        ? 'Seleccionar rango de fechas'
                        : '${DateFormat('dd/MM/yy').format(_rango!.start)} - ${DateFormat('dd/MM/yy').format(_rango!.end)}',
                    style: const TextStyle(color: Color(0xFF1F2937)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.grey[50],
                  ),
                ),
                if (_rango != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _rango = null),
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Limpiar filtro de fecha'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista de pagos
          // Resumen
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: pagosAsync.when(
              data: (items) {
                final total = totalFiltrado(items);
                final count = cantidadFiltrada(items);
                final fmt = NumberFormat.currency(
                  locale: 'es_CO',
                  symbol: '\$',
                  decimalDigits: 0,
                );
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _miniStat(
                          label: 'Pagos',
                          value: '$count',
                          color: const Color(0xFF1F2937),
                          icon: Icons.receipt_long,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _miniStat(
                          label: 'Total',
                          value: fmt.format(total),
                          color: const Color(0xFF10B981),
                          icon: Icons.payments,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),

          Expanded(
            child: pagosAsync.when(
              data: (items) {
                final data = filtrar(items);
                if (data.isEmpty) {
                  return _buildEmptyState();
                }

                // Agrupar por fecha
                final groupedByDate = <String, List<PagoNfc>>{};
                for (final pago in data) {
                  final dateKey = DateFormat(
                    'yyyy-MM-dd',
                  ).format(pago.fechaPago);
                  groupedByDate.putIfAbsent(dateKey, () => []).add(pago);
                }

                // Ordenar fechas de más reciente a más antigua
                final sortedDates = groupedByDate.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(pagosNfcProvider.notifier)
                      .refresh(tarjetaId: _tarjetaFiltroId),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: sortedDates.length,
                    itemBuilder: (_, i) {
                      final dateKey = sortedDates[i];
                      final pagos = groupedByDate[dateKey]!;
                      return _buildDateSection(dateKey, pagos);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 64,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay pagos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajusta los filtros para ver más resultados',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar historial',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(String dateKey, List<PagoNfc> pagos) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String dateLabel;
    if (dateOnly == today) {
      dateLabel = 'Hoy';
    } else if (dateOnly == yesterday) {
      dateLabel = 'Ayer';
    } else {
      dateLabel = DateFormat('EEEE, d MMMM', 'es_ES').format(date);
    }

    // Calcular total del día
    final totalDia = pagos.fold<double>(0, (sum, p) => sum + p.monto);
    final fmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  fmt.format(totalDia),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...pagos.map((pago) => _buildPaymentCard(pago)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPaymentCard(PagoNfc pago) {
    final fmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final timeFmt = DateFormat('HH:mm');
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => _DetallePagoSheet(p: pago, df: df, formato: fmt),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono NFC
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.contactless,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Información del pago
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Pago NFC',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pago.moneda,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeFmt.format(pago.fechaPago),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (pago.ubicacion != null &&
                              pago.ubicacion!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pago.ubicacion!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Monto y flecha
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fmt.format(pago.monto),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    if (h.length == 8) {
      return Color(int.parse(h, radix: 16));
    }
    return null;
  }
}

class _DetallePagoSheet extends ConsumerWidget {
  final PagoNfc p;
  final DateFormat df;
  final NumberFormat formato;
  const _DetallePagoSheet({
    required this.p,
    required this.df,
    required this.formato,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarjetas = ref
        .watch(tprov.tarjetasNfcProvider)
        .maybeWhen(data: (list) => list, orElse: () => null);
    String tarjetaLabel = '#${p.tarjetaNfcId}';
    if (tarjetas != null) {
      final match = tarjetas.where((x) => x.id == p.tarjetaNfcId);
      if (match.isNotEmpty) {
        final t = match.first;
        tarjetaLabel = '${t.nombrePortador} • ${t.banco ?? 'N/A'}';
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFF3B82F6),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalle del Pago',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'ID: ${p.id}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Monto destacado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Monto Total',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formato.format(p.monto)} ${p.moneda}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Información detallada
            _infoRow(
              Icons.calendar_today,
              'Fecha y Hora',
              df.format(p.fechaPago),
            ),
            _infoRow(Icons.credit_card, 'Tarjeta', tarjetaLabel),
            _infoRow(Icons.receipt, 'Transacción ID', '#${p.transaccionId}'),
            FutureBuilder<int?>(
              future: DeviceRegistry.getCachedDeviceId(),
              builder: (context, snap) {
                String disp = '#${p.dispositivoNfcId}';
                if (snap.hasData &&
                    snap.data != null &&
                    snap.data == p.dispositivoNfcId) {
                  disp = 'Este dispositivo (#${p.dispositivoNfcId})';
                }
                return _infoRow(Icons.phone_android, 'Dispositivo', disp);
              },
            ),
            if (p.ubicacion != null && p.ubicacion!.isNotEmpty)
              _infoRow(Icons.location_on, 'Ubicación', p.ubicacion!),
            if (p.latitud != null && p.longitud != null)
              _infoRow(
                Icons.my_location,
                'Coordenadas',
                '${p.latitud}, ${p.longitud}',
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
