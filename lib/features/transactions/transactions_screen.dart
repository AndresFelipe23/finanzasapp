import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaccion_models.dart';
import 'transactions_provider.dart';
import 'create_transaction_screen.dart';
import 'create_transfer_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context, ref),
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.add, color: Colors.white, size: 24),
        label: const Text(
          'Nueva Transacción',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header moderno
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transacciones',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Historial de movimientos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactionsAsync.when(
                data: (transacciones) {
                  if (transacciones.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Agrupar por fecha
                  final grouped = _groupByDate(transacciones);

                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(transactionsNotifierProvider.notifier)
                          .refresh();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, index) {
                        final date = grouped.keys.elementAt(index);
                        final dateTransactions = grouped[date]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fecha
                            Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : 16,
                                bottom: 12,
                                left: 4,
                              ),
                              child: Text(
                                _formatDateHeader(date),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            // Transacciones del día ordenadas por hora desc
                            ...(() {
                              final sorted = [...dateTransactions]
                                ..sort((a, b) => b.fechaTransaccion.compareTo(a.fechaTransaccion));
                              return sorted.map((trans) => _buildTransactionCard(context, trans)).toList();
                            }()),
                          ],
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF10B981),
                    strokeWidth: 3,
                  ),
                ),
                error: (error, stackTrace) =>
                    _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Transaccion trans) {
    final isIngreso = trans.tipoNombre == 'INGRESO';
    // Detectar si es transferencia
    final isTransferencia = trans.titulo != null && 
                            trans.titulo!.toLowerCase().contains('transferencia');
    
    final iconColor = isTransferencia
        ? const Color(0xFF8B5CF6)
        : (isIngreso ? const Color(0xFF10B981) : const Color(0xFFEF4444));
    final categoryColor = isTransferencia ? const Color(0xFF8B5CF6) : _parseColor(trans.categoriaColor);

    return InkWell(
      onTap: () => _showTransactionDetail(
        context, 
        trans, 
        isTransferencia ? const Color(0xFF8B5CF6) : (trans.tipoNombre == 'INGRESO' ? const Color(0xFF10B981) : const Color(0xFFEF4444))
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: categoryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                isTransferencia 
                  ? Icons.swap_horiz
                  : _getCategoryIcon(trans.categoriaIcono),
                color: categoryColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (trans.titulo != null && trans.titulo!.isNotEmpty)
                        ? trans.titulo!
                        : (trans.categoriaNombre ?? 'Sin categoría'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTransferencia 
                                ? Icons.swap_horiz
                                : (isIngreso ? Icons.arrow_upward : Icons.arrow_downward),
                              size: 12,
                              color: iconColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isTransferencia ? 'Transferencia' : trans.tipoNombre,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(trans.fechaTransaccion),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    ],
                  ),
                  if ((trans.descripcion != null && trans.descripcion!.isNotEmpty) ||
                      (trans.categoriaNombre != null && trans.categoriaNombre!.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        (trans.descripcion != null && trans.descripcion!.isNotEmpty)
                            ? trans.descripcion!
                            : (trans.categoriaNombre ?? ''),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: trans.monto),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, child) {
                    return Text(
                      '${isIngreso ? '+' : '-'}${_formatCurrency(animatedValue)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  trans.moneda,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(BuildContext context, Transaccion t, Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final df = DateFormat('dd/MM/yyyy HH:mm');
        // Determinar si es una transferencia basándose en el título
        final isTransferencia = t.titulo != null && 
                                t.titulo!.toLowerCase().contains('transferencia');
        
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isTransferencia 
                          ? Icons.swap_horiz 
                          : (t.tipoNombre == 'INGRESO' ? Icons.trending_up : Icons.trending_down),
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (t.titulo != null && t.titulo!.isNotEmpty) ? t.titulo! : (t.categoriaNombre ?? 'Transacción'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                          ),
                          Text(df.format(t.fechaTransaccion), style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: ()=> Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Mostrar cuenta con indicador si es transferencia
                if (isTransferencia)
                  _detailRowTransfer(
                    t.tipoNombre == 'GASTO' 
                      ? Icons.arrow_forward 
                      : Icons.arrow_back,
                    t.tipoNombre == 'GASTO' ? 'Desde' : 'Hacia',
                    t.cuentaNombre ?? (t.cuentaId?.toString() ?? '-'),
                    accent,
                  )
                else
                  _detailRow(Icons.account_balance, 'Cuenta', t.cuentaNombre ?? (t.cuentaId?.toString() ?? '-')),
                
                // Solo mostrar categoría y método de pago si NO es transferencia
                if (!isTransferencia) ...[
                  _detailRow(Icons.category, 'Categoría', t.categoriaNombre ?? '-'),
                  _detailRow(Icons.payment, 'Método de pago', t.metodoPagoNombre ?? '-'),
                ],
                
                _detailRow(Icons.monetization_on, 'Monto', '${_formatCurrency(t.monto)} ${t.moneda}'),
                _detailRow(Icons.type_specimen, 'Tipo', t.tipoNombre),
                
                if (t.descripcion != null && t.descripcion!.isNotEmpty)
                  _detailRow(Icons.description_outlined, 'Descripción', t.descripcion!),
                if (t.notas != null && t.notas!.isNotEmpty)
                  _detailRow(Icons.note_outlined, 'Notas', t.notas!),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _detailRowTransfer(IconData icon, String label, String value, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay transacciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Comienza agregando tus\nprimeros gastos e ingresos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error al cargar transacciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, List<Transaccion>> _groupByDate(
    List<Transaccion> transacciones,
  ) {
    final grouped = <DateTime, List<Transaccion>>{};

    for (final trans in transacciones) {
      // Normalizar a solo fecha local (sin hora)
      // fechaTransaccion ya es hora local, no necesita conversión
      final ft = trans.fechaTransaccion;
      final date = DateTime(ft.year, ft.month, ft.day);

      if (grouped.containsKey(date)) {
        grouped[date]!.add(trans);
      } else {
        grouped[date] = [trans];
      }
    }

    // Ordenar por fecha descendente
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hoy';
    } else if (dateOnly == yesterday) {
      return 'Ayer';
    } else {
      return DateFormat('EEEE, d MMMM yyyy', 'es').format(date);
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es',
    );
    return formatter.format(amount);
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return const Color(0xFF059669);
    }
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF059669);
    }
  }

  IconData _getCategoryIcon(String? icono) {
    if (icono == null) return Icons.category;
    // Mapear iconos comunes
    switch (icono.toLowerCase()) {
      case 'restaurant':
      case 'restaurant_menu':
        return Icons.restaurant;
      case 'local_gas_station':
      case 'car':
        return Icons.local_gas_station;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'home':
        return Icons.home;
      case 'flight':
        return Icons.flight;
      case 'health':
      case 'medical':
        return Icons.medical_services;
      default:
        return Icons.category;
    }
  }

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de arrastre
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Título
            const Text(
              'Nueva Transacción',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona el tipo de transacción',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            // Botones de opciones
            _buildTransactionOption(
              context,
              icon: Icons.trending_up,
              title: 'Ingreso',
              subtitle: 'Agregar dinero recibido',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateTransactionScreen(
                      tipoTransaccion: 'INGRESO',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildTransactionOption(
              context,
              icon: Icons.trending_down,
              title: 'Gasto',
              subtitle: 'Registrar dinero gastado',
              color: const Color(0xFFEF4444),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const CreateTransactionScreen(tipoTransaccion: 'GASTO'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildTransactionOption(
              context,
              icon: Icons.swap_horiz,
              title: 'Transferencia',
              subtitle: 'Mover dinero entre cuentas',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateTransferScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Botón cancelar
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
