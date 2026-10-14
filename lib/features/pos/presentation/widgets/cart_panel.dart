import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/features/pos/models/order_model.dart';
import 'package:pos_kuliner/features/pos/presentation/widgets/discount_dialog.dart';
import 'package:pos_kuliner/features/pos/presentation/widgets/held_orders_sheet.dart';
import 'package:pos_kuliner/features/pos/presentation/widgets/payment_modal.dart';
import 'package:pos_kuliner/features/pos/providers/cart_provider.dart';
import 'package:pos_kuliner/features/pos/providers/orders_provider.dart';
import 'package:pos_kuliner/features/settings/providers/settings_provider.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final summary = ref.watch(cartSummaryProvider);
    final settings = ref.watch(settingsProvider);
    final ordersState = ref.watch(ordersProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        children: [
          // Order Type Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDark : Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<OrderType>(
                        segments: const [
                          ButtonSegment(
                            value: OrderType.dineIn,
                            label: Text('Dine-In', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.table_restaurant, size: 16),
                          ),
                          ButtonSegment(
                            value: OrderType.takeaway,
                            label: Text('Bungkus', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.takeout_dining, size: 16),
                          ),
                          ButtonSegment(
                            value: OrderType.delivery,
                            label: Text('Antar', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.delivery_dining, size: 16),
                          ),
                        ],
                        selected: {cart.orderType},
                        onSelectionChanged: (set) {
                          ref.read(cartProvider.notifier).setOrderType(set.first);
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Table / Customer Name Field
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEditTableOrCustomerDialog(context, ref, cart),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                cart.orderType == OrderType.dineIn
                                    ? Icons.room_service_outlined
                                    : Icons.person_outline,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cart.orderType == OrderType.dineIn
                                      ? (cart.tableNumber.isEmpty ? 'Tentukan Meja' : cart.tableNumber)
                                      : (cart.customerName.isEmpty ? 'Nama Pelanggan' : cart.customerName),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.edit, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Held Orders Button (with count badge)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => const HeldOrdersSheet(),
                            );
                          },
                          icon: const Icon(Icons.pause, size: 16),
                          label: const Text('Tertahan', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        if (ordersState.heldOrders.isNotEmpty)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${ordersState.heldOrders.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List in Cart
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 56,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Keranjang Masih Kosong',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pilih menu di sebelah kiri\nuntuk menambahkan pesanan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.displayName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (item.selectedModifiers.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.selectedModifiers.map((m) => '+ ${m.nameSnapshot}').join(', '),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                                if (item.note.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Catatan: "${item.note}"',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(item.unitPrice),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.bgDark : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 14),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).updateQuantity(
                                              item.id,
                                              item.quantity - 1,
                                            );
                                      },
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 14),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).updateQuantity(
                                              item.id,
                                              item.quantity + 1,
                                            );
                                      },
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 75,
                                child: Text(
                                  CurrencyFormatter.format(item.totalPrice),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Cart Summary & Calculation Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDark : Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal (${cart.totalItemCount} item)', CurrencyFormatter.format(summary.subtotal)),
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => DiscountDialog(
                            subtotal: summary.subtotal,
                            currentPercent: cart.discountPercent,
                            currentNominal: cart.discountNominal,
                            currentReason: cart.discountReason,
                            onApply: ({percent = 0, nominal = 0, reason = ''}) {
                              ref.read(cartProvider.notifier).applyDiscount(
                                    percent: percent,
                                    nominal: nominal,
                                    reason: reason,
                                  );
                            },
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.discount_outlined,
                            size: 14,
                            color: summary.discount > 0 ? AppColors.success : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            summary.discount > 0
                                ? 'Diskon (${cart.discountReason.isEmpty ? 'Aktif' : cart.discountReason}):'
                                : '+ Tambah Diskon',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: summary.discount > 0 ? AppColors.success : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      summary.discount > 0 ? '-${CurrencyFormatter.format(summary.discount)}' : 'Rp 0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: summary.discount > 0 ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (settings.enableServiceCharge) ...[
                  _buildSummaryRow(
                    'Service Charge (${settings.serviceChargePercent.toStringAsFixed(0)}%)',
                    CurrencyFormatter.format(summary.serviceCharge),
                  ),
                  const SizedBox(height: 6),
                ],

                if (settings.enableTax) ...[
                  _buildSummaryRow(
                    'Pajak PB1 (${settings.taxPercent.toStringAsFixed(0)}%)',
                    CurrencyFormatter.format(summary.tax),
                  ),
                  const SizedBox(height: 6),
                ],

                const Divider(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      CurrencyFormatter.format(summary.grandTotal),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    IconButton.outlined(
                      onPressed: cart.items.isNotEmpty
                          ? () {
                              final held = ref.read(ordersProvider.notifier).holdCurrentCart();
                              if (held != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Pesanan #${held.queueNumber} berhasil disimpan sementara.'),
                                    backgroundColor: AppColors.warning,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.pause, size: 20, color: AppColors.warning),
                      tooltip: 'Tahan Pesanan (Park/Hold)',
                    ),
                    const SizedBox(width: 8),

                    IconButton.outlined(
                      onPressed: cart.items.isNotEmpty
                          ? () {
                              _confirmClearCart(context, ref);
                            }
                          : null,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 20, color: AppColors.danger),
                      tooltip: 'Kosongkan Keranjang',
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: cart.items.isNotEmpty
                            ? () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => const PaymentModal(),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Bayar (${CurrencyFormatter.format(summary.grandTotal)})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showEditTableOrCustomerDialog(BuildContext context, WidgetRef ref, CartState cart) {
    final textController = TextEditingController(
      text: cart.orderType == OrderType.dineIn ? cart.tableNumber : cart.customerName,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          cart.orderType == OrderType.dineIn ? 'Nomor / Nama Meja' : 'Nama Pelanggan',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: cart.orderType == OrderType.dineIn ? 'Misal: Meja 05, Meja VIP' : 'Misal: Mas Budi',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textController.text.trim();
              if (cart.orderType == OrderType.dineIn) {
                ref.read(cartProvider.notifier).setTableNumber(val);
              } else {
                ref.read(cartProvider.notifier).setCustomerName(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content: const Text('Seluruh item dalam keranjang saat ini akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }
}
