import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/core/utils/date_formatter.dart';
import 'package:pos_kuliner/features/auth/providers/auth_provider.dart';
import 'package:pos_kuliner/features/pos/providers/orders_provider.dart';
import 'package:pos_kuliner/features/shift/models/cash_movement_model.dart';
import 'package:pos_kuliner/features/shift/models/shift_model.dart';
import 'package:pos_kuliner/features/shift/providers/shift_provider.dart';

class ShiftScreen extends ConsumerWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftProvider);
    final activeShift = shiftState.activeShift;
    final currentUser = ref.watch(currentUserProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manajemen Shift & Kas'),
            actions: [
              if (activeShift != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: AppColors.success, size: 8),
                          SizedBox(width: 6),
                          Text(
                            'Shift Buka',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: activeShift == null
              ? _buildNoActiveShiftView(context, ref, isDark)
              : ListView(
                  padding: EdgeInsets.all(isCompact ? 14 : 20),
                  children: [
                    // 1. Active Shift Info Card
                    Container(
                      padding: EdgeInsets.all(isCompact ? 14 : 18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Shift #${activeShift.id.substring(activeShift.id.length - 6)}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Kasir: ${activeShift.userName} (${currentUser.role.displayName})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Waktu Buka',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormatter.formatDateTime(activeShift.openedAt),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 14),

                          // Expected Cash Highlight
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                            ),
                            child: isCompact
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ESTIMASI KAS DI LACI (EXPECTED)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Kas Awal + Tunai + Kas Masuk - Kas Keluar',
                                        style: TextStyle(fontSize: 10, color: Colors.black54),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        CurrencyFormatter.format(activeShift.expectedClosingCash),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ESTIMASI KAS DI LACI (EXPECTED)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                color: AppColors.primaryDark,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Kas Awal + Tunai + Kas Masuk - Kas Keluar',
                                              style: TextStyle(fontSize: 11, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(activeShift.expectedClosingCash),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Shift KPI Grid
                    GridView.count(
                      crossAxisCount: isCompact ? 2 : 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isCompact ? 1.35 : 1.6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildKpiCard(
                          title: 'Kas Awal (Modal)',
                          value: CurrencyFormatter.format(activeShift.openingCash),
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppColors.info,
                          isDark: isDark,
                        ),
                        _buildKpiCard(
                          title: 'Penjualan Tunai',
                          value: CurrencyFormatter.format(activeShift.totalCashSales),
                          icon: Icons.payments_outlined,
                          color: AppColors.success,
                          isDark: isDark,
                        ),
                        _buildKpiCard(
                          title: 'Penjualan Non-Tunai',
                          value: CurrencyFormatter.format(activeShift.totalNonCashSales),
                          icon: Icons.qr_code,
                          color: Colors.purple,
                          isDark: isDark,
                        ),
                        _buildKpiCard(
                          title: 'Kas Masuk / Keluar',
                          value: isCompact
                              ? '+${CurrencyFormatter.formatCompact(activeShift.totalCashIn)} / -${CurrencyFormatter.formatCompact(activeShift.totalCashOut)}'
                              : '${CurrencyFormatter.format(activeShift.totalCashIn)} / -${CurrencyFormatter.format(activeShift.totalCashOut)}',
                          icon: Icons.swap_vert,
                          color: AppColors.warning,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Action Buttons: Kas Masuk, Kas Keluar, Tutup Shift
                    if (isCompact) ...[
                      // Mobile 2-tier layout: Masuk & Keluar on top row, Tutup Shift prominent on bottom
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showCashMovementDialog(context, ref, CashMovementType.cashIn),
                              icon: const Icon(Icons.arrow_downward, size: 16),
                              label: const Text('Kas Masuk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.info,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showCashMovementDialog(context, ref, CashMovementType.cashOut),
                              icon: const Icon(Icons.arrow_upward, size: 16),
                              label: const Text('Kas Keluar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCloseShiftDialog(context, ref, activeShift),
                          icon: const Icon(Icons.lock_clock, size: 18),
                          label: const Text('Tutup Shift Kasir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Desktop single-row layout
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showCashMovementDialog(context, ref, CashMovementType.cashIn),
                              icon: const Icon(Icons.arrow_downward, size: 18),
                              label: const Text('Kas Masuk'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.info,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showCashMovementDialog(context, ref, CashMovementType.cashOut),
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              label: const Text('Kas Keluar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showCloseShiftDialog(context, ref, activeShift),
                              icon: const Icon(Icons.lock_clock, size: 18),
                              label: const Text('Tutup Shift'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // 4. Cash Movements History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Riwayat Arus Kas Shift Ini',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${shiftState.movements.length} catatan',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (shiftState.movements.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Belum ada catatan kas masuk/keluar pada shift ini.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      )
                    else
                      ...shiftState.movements.map((m) {
                        final isCashIn = m.type == CashMovementType.cashIn;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCashIn ? AppColors.successLight : AppColors.warningLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isCashIn ? AppColors.success : AppColors.warning,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.note,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${DateFormatter.formatTime(m.timestamp)} • ${m.createdByName}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${isCashIn ? '+' : '-'}${CurrencyFormatter.format(m.amount)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isCashIn ? AppColors.success : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveShiftView(BuildContext context, WidgetRef ref, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Kasir Sedang Tutup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Silakan buka shift kasir baru dengan memasukkan modal awal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showOpenShiftDialog(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Buka Shift Kasir Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpenShiftDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: '200000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.point_of_sale, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text('Buka Shift Kasir', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nominal Kas Awal / Modal fisik yang ada di laci kasir saat ini:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '200000',
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              ref.read(shiftProvider.notifier).openShift(openingCash: val);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Shift kasir berhasil dibuka dengan modal ${CurrencyFormatter.format(val)}!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Buka Shift'),
          ),
        ],
      ),
    );
  }

  void _showCashMovementDialog(BuildContext context, WidgetRef ref, CashMovementType type) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              type == CashMovementType.cashIn ? Icons.arrow_downward : Icons.arrow_upward,
              color: type == CashMovementType.cashIn ? AppColors.success : AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              type == CashMovementType.cashIn ? 'Catat Kas Masuk' : 'Catat Kas Keluar',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                prefixText: 'Rp ',
                hintText: '50000',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Keterangan (Wajib)',
                hintText: type == CashMovementType.cashIn
                    ? 'Misal: Tambahan uang kembalian'
                    : 'Misal: Beli es batu, beli gas elpiji',
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final amt = int.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final note = noteController.text.trim();
              if (amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nominal harus lebih dari Rp 0!')),
                );
                return;
              }
              if (note.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Keterangan kas wajib diisi!')),
                );
                return;
              }
              ref.read(shiftProvider.notifier).recordCashMovement(
                    type: type,
                    amount: amt,
                    note: note,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context, WidgetRef ref, Shift shift) {
    final ordersState = ref.read(ordersProvider);
    if (ordersState.heldOrders.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Peringatan Tutup Shift',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            'Terdapat ${ordersState.heldOrders.length} pesanan tertahan (hold) yang belum diselesaikan atau dibatalkan. Harap selesaikan terlebih dahulu sebelum menutup shift.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kembali ke Kasir'),
            ),
          ],
        ),
      );
      return;
    }

    final actualCashController = TextEditingController(text: shift.expectedClosingCash.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final actual = int.tryParse(actualCashController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final diff = actual - shift.expectedClosingCash;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_clock, color: AppColors.danger, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tutup Shift & Rekap Kas',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryItem('Estimasi Kas di Laci:', CurrencyFormatter.format(shift.expectedClosingCash)),
                    const SizedBox(height: 12),
                    const Text('Hitung Fisik Uang di Laci Kasir (Aktual):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: actualCashController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: diff == 0 ? AppColors.successLight : (diff > 0 ? AppColors.infoLight : AppColors.dangerLight),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              diff == 0 ? 'Selisih Kas: Pas' : (diff > 0 ? 'Selisih Lebih:' : 'Selisih Kurang:'),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(diff.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: diff == 0 ? AppColors.success : (diff > 0 ? AppColors.info : AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                onPressed: () {
                  ref.read(shiftProvider.notifier).closeShift(actualCash: actual);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shift kasir berhasil ditutup! Laporan rekonsiliasi kas telah tercatat.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Tutup Shift Sekarang'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
