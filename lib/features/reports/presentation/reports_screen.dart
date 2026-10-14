import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/core/utils/date_formatter.dart';
import 'package:pos_kuliner/features/pos/models/order_model.dart';
import 'package:pos_kuliner/features/pos/providers/orders_provider.dart';
import 'package:pos_kuliner/features/printing/presentation/receipt_dialog.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final completedOrders = ordersState.completedOrders.where((o) => o.status == OrderStatus.completed).toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Metrics calculations
    final int totalOmzet = completedOrders.fold<int>(0, (sum, o) => sum + o.total);
    final int totalCount = completedOrders.length;
    final int averageOrderValue = totalCount > 0 ? (totalOmzet / totalCount).round() : 0;

    // Payment methods breakdown
    int cashTotal = 0;
    int qrisTotal = 0;
    int debitTotal = 0;
    for (final o in completedOrders) {
      if (o.paymentMethod == PaymentMethod.cash) {
        cashTotal += o.total;
      } else if (o.paymentMethod == PaymentMethod.qris) {
        qrisTotal += o.total;
      } else {
        debitTotal += o.total;
      }
    }

    // Top products calculation
    final Map<String, int> productSalesCount = {};
    for (final o in completedOrders) {
      for (final item in o.items) {
        productSalesCount[item.productName] = (productSalesCount[item.productName] ?? 0) + item.quantity;
      }
    }
    final sortedProducts = productSalesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Riwayat Penjualan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Ringkasan & Analitik'),
            Tab(text: 'Riwayat Transaksi (Struk)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Ringkasan & Analitik
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // KPI Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Omzet Hari Ini',
                      CurrencyFormatter.format(totalOmzet),
                      Icons.monetization_on_outlined,
                      AppColors.primary,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Total Transaksi Selesai',
                      '$totalCount Pesanan',
                      Icons.receipt_outlined,
                      AppColors.info,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Rata-rata Nilai (AOV)',
                      CurrencyFormatter.format(averageOrderValue),
                      Icons.auto_graph,
                      AppColors.success,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Breakdown by Payment Method
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rekap Metode Pembayaran',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentBar('Tunai (Cash)', cashTotal, totalOmzet, AppColors.success),
                    const SizedBox(height: 10),
                    _buildPaymentBar('QRIS (Online)', qrisTotal, totalOmzet, AppColors.primary),
                    const SizedBox(height: 10),
                    _buildPaymentBar('Kartu Debit / EDC', debitTotal, totalOmzet, AppColors.info),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Best Selling Products
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top 5 Menu Paling Laris',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    if (sortedProducts.isEmpty)
                      const Text('Belum ada data penjualan menu.')
                    else
                      ...sortedProducts.take(5).map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '#${sortedProducts.indexOf(entry) + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.bgDark : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${entry.value} Terjual',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),

          // Tab 2: Riwayat Transaksi (Struk & Batal)
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordersState.completedOrders.length,
            itemBuilder: (context, index) {
              final order = ordersState.completedOrders[index];
              final isCancelled = order.status == OrderStatus.cancelled;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCancelled
                        ? AppColors.danger.withValues(alpha: 0.5)
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCancelled ? AppColors.dangerLight : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${order.queueNumber}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isCancelled ? AppColors.danger : AppColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              order.shortId,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCancelled ? AppColors.dangerLight : AppColors.successLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                order.status.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCancelled ? AppColors.danger : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormatter.formatDateTime(order.createdAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Order Type & Customer/Table
                    Text(
                      '${order.orderType.displayName} ${order.tableNumber.isNotEmpty ? '(${order.tableNumber})' : ''} ${order.customerName.isNotEmpty ? '• ${order.customerName}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Items snippet
                    Text(
                      order.items.map((i) => '${i.quantity}x ${i.productName}').join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),

                    if (isCancelled && order.cancellationReason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Alasan Batal: "${order.cancellationReason}"',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.paymentMethod.displayName,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                            ),
                            Text(
                              CurrencyFormatter.format(order.total),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                decoration: isCancelled ? TextDecoration.lineThrough : null,
                                color: isCancelled ? Colors.grey : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (!isCancelled)
                              OutlinedButton.icon(
                                onPressed: () => _showVoidOrderDialog(context, ref, order),
                                icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.danger),
                                label: const Text('Batalkan', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: const BorderSide(color: AppColors.dangerLight),
                                ),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => ReceiptDialog(order: order),
                                );
                              },
                              icon: const Icon(Icons.print, size: 16),
                              label: const Text('Cetak Ulang', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBar(String label, int amount, int total, Color color) {
    final percent = total > 0 ? (amount / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              '${CurrencyFormatter.format(amount)} (${(percent * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent.clamp(0.0, 1.0),
          color: color,
          backgroundColor: color.withValues(alpha: 0.15),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  void _showVoidOrderDialog(BuildContext context, WidgetRef ref, Order order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Batalkan Transaksi?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nomor Nota: ${order.shortId} (Antrean #${order.queueNumber})'),
            Text('Total Nilai: ${CurrencyFormatter.format(order.total)}'),
            const SizedBox(height: 12),
            const Text('Alasan Pembatalan (Wajib Diisi):', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Misal: Salah input pesanan, pelanggan membatalkan',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                ref.read(ordersProvider.notifier).cancelCompletedOrder(order.id, reason);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaksi telah dibatalkan dan tercatat dalam log audit.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Konfirmasi Pembatalan'),
          ),
        ],
      ),
    );
  }
}
