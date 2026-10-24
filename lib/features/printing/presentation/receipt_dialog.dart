import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/features/pos/models/order_model.dart';
import 'package:pos_kuliner/features/printing/services/esc_pos_service.dart';
import 'package:pos_kuliner/features/settings/providers/settings_provider.dart';

class ReceiptDialog extends ConsumerStatefulWidget {
  final Order order;
  final VoidCallback? onDone;

  const ReceiptDialog({
    super.key,
    required this.order,
    this.onDone,
  });

  @override
  ConsumerState<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<ReceiptDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPrinting = false;
  String? _printStatus;

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

  Future<void> _simulatePrint(String title) async {
    setState(() {
      _isPrinting = true;
      _printStatus = 'Mengirim data ke printer thermal Bluetooth...';
    });

    await Future.delayed(const Duration(milliseconds: 1400));

    if (mounted) {
      setState(() {
        _isPrinting = false;
        _printStatus = 'Berhasil dicetak! (Status: OK)';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title berhasil dicetak ke Printer ESC/POS!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final customerReceipt = EscPosService.generateReceiptText(
      order: widget.order,
      settings: settings,
    );

    final kitchenTicket = EscPosService.generateKitchenTicketText(
      order: widget.order,
      settings: settings,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Struk Transaksi #${widget.order.queueNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Format ESC/POS (${settings.paperWidthMm}mm Thermal)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDone?.call();
                  },
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                tabs: const [
                  Tab(text: 'Struk Pembayaran'),
                  Tab(text: 'Tiket Dapur (Kitchen)'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.thermalBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      child: SelectableText(
                        customerReceipt,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          color: AppColors.thermalText,
                          height: 1.25,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      child: SelectableText(
                        kitchenTicket,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.thermalText,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_printStatus != null) ...[
              const SizedBox(height: 8),
              Text(
                _printStatus!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPrinting
                        ? null
                        : () => _simulatePrint(
                              _tabController.index == 0 ? 'Struk Pelanggan' : 'Tiket Dapur',
                            ),
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_outlined, size: 18),
                    label: Text(_isPrinting ? 'Mencetak...' : 'Cetak Struk'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDone?.call();
                    },
                    child: const Text('Transaksi Baru'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
