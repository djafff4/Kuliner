import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/features/pos/models/order_model.dart';
import 'package:pos_kuliner/features/pos/providers/cart_provider.dart';
import 'package:pos_kuliner/features/pos/providers/orders_provider.dart';
import 'package:pos_kuliner/features/printing/presentation/receipt_dialog.dart';
import 'package:pos_kuliner/features/settings/models/store_settings_model.dart';
import 'package:pos_kuliner/features/settings/providers/settings_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentModal extends ConsumerStatefulWidget {
  const PaymentModal({super.key});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;

  final TextEditingController _cashController = TextEditingController();
  int _cashTendered = 0;

  bool _qrisConfirmed = false;

  String _selectedBank = 'BCA';
  final TextEditingController _cardRefController = TextEditingController();

  final TextEditingController _splitCashController = TextEditingController();
  PaymentMethod _splitSecondMethod = PaymentMethod.qris;

  @override
  void initState() {
    super.initState();
    final summary = ref.read(cartSummaryProvider);
    _cashTendered = summary.grandTotal;
    _cashController.text = _cashTendered.toString();

    final half = (summary.grandTotal / 2).round();
    _splitCashController.text = half.toString();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _cardRefController.dispose();
    _splitCashController.dispose();
    super.dispose();
  }

  int get _calculatedChange {
    final summary = ref.read(cartSummaryProvider);
    return _cashTendered - summary.grandTotal;
  }

  bool get _canSubmit {
    final summary = ref.read(cartSummaryProvider);
    switch (_selectedMethod) {
      case PaymentMethod.cash:
        return _cashTendered >= summary.grandTotal;
      case PaymentMethod.qris:
        return _qrisConfirmed;
      case PaymentMethod.debit:
        return _cardRefController.text.trim().isNotEmpty;
      case PaymentMethod.split:
        final splitCash = int.tryParse(_splitCashController.text.trim()) ?? 0;
        return splitCash > 0 && splitCash < summary.grandTotal;
    }
  }

  void _onCompletePayment() {
    final summary = ref.read(cartSummaryProvider);
    int tendered = summary.grandTotal;
    int change = 0;
    String refNumber = '';

    if (_selectedMethod == PaymentMethod.cash) {
      tendered = _cashTendered;
      change = _calculatedChange;
    } else if (_selectedMethod == PaymentMethod.qris) {
      refNumber = 'QRIS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    } else if (_selectedMethod == PaymentMethod.debit) {
      refNumber = '$_selectedBank-${_cardRefController.text.trim()}';
    } else if (_selectedMethod == PaymentMethod.split) {
      final splitCash = int.tryParse(_splitCashController.text.trim()) ?? 0;
      final remainder = summary.grandTotal - splitCash;
      refNumber = 'Split: Tunai ${CurrencyFormatter.format(splitCash)} + ${_splitSecondMethod.displayName} ${CurrencyFormatter.format(remainder)}';
    }

    final newOrder = ref.read(ordersProvider.notifier).completeTransaction(
      paymentMethod: _selectedMethod,
      amountTendered: tendered,
      changeDue: change,
      paymentReference: refNumber,
    );

    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReceiptDialog(order: newOrder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(cartSummaryProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Total Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pastikan nominal sudah sesuai',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(summary.grandTotal),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Payment Method Selector Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildMethodChip(PaymentMethod.cash, 'Tunai', Icons.payments_outlined),
                const SizedBox(width: 8),
                _buildMethodChip(PaymentMethod.qris, 'QRIS', Icons.qr_code_scanner),
                const SizedBox(width: 8),
                _buildMethodChip(PaymentMethod.debit, 'Kartu / EDC', Icons.credit_card),
                const SizedBox(width: 8),
                _buildMethodChip(PaymentMethod.split, 'Split Bill', Icons.call_split),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Active Method Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_selectedMethod == PaymentMethod.cash)
                  _buildCashView(summary.grandTotal, isDark)
                else if (_selectedMethod == PaymentMethod.qris)
                  _buildQrisView(summary.grandTotal, settings, isDark)
                else if (_selectedMethod == PaymentMethod.debit)
                  _buildDebitView(isDark)
                else if (_selectedMethod == PaymentMethod.split)
                  _buildSplitView(summary.grandTotal, isDark),
              ],
            ),
          ),

          // Confirm Action Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _onCompletePayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Selesaikan Pembayaran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashView(int total, bool isDark) {
    final presets = <int>[total];
    final rounded50 = ((total / 50000).ceil()) * 50000;
    if (rounded50 > total && !presets.contains(rounded50)) presets.add(rounded50);
    final rounded100 = ((total / 100000).ceil()) * 100000;
    if (rounded100 > total && !presets.contains(rounded100)) presets.add(rounded100);
    if (!presets.contains(100000) && 100000 > total) presets.add(100000);
    if (!presets.contains(200000) && 200000 > total) presets.add(200000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uang Diterima dari Pelanggan:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cashController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          onChanged: (val) {
            setState(() {
              _cashTendered = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            });
          },
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((amount) {
            final isExact = amount == total;
            return ActionChip(
              avatar: isExact ? const Icon(Icons.check, size: 16, color: AppColors.primary) : null,
              label: Text(
                isExact ? 'Uang Pas' : CurrencyFormatter.format(amount),
                style: TextStyle(
                  fontWeight: isExact ? FontWeight.w800 : FontWeight.w600,
                  color: isExact ? AppColors.primaryDark : null,
                ),
              ),
              onPressed: () {
                setState(() {
                  _cashTendered = amount;
                  _cashController.text = amount.toString();
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _calculatedChange >= 0
                ? AppColors.successLight.withValues(alpha: 0.5)
                : AppColors.dangerLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _calculatedChange >= 0 ? AppColors.success : AppColors.danger,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _calculatedChange >= 0 ? Icons.change_circle_outlined : Icons.warning_amber_rounded,
                    color: _calculatedChange >= 0 ? AppColors.success : AppColors.danger,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _calculatedChange >= 0 ? 'Kembalian' : 'Uang Kurang',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _calculatedChange >= 0 ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      Text(
                        _calculatedChange >= 0 ? 'Harap kembalikan ke pelanggan' : 'Nominal belum mencukupi',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.format(_calculatedChange.abs()),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _calculatedChange >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrisView(int total, StoreSettings settings, bool isDark) {
    final qrisPayload = '00020101021226610014ID.LINKAJA.WWW0118936000000000000000520458125303360540${total}5802ID5914${settings.storeName}6007JAKARTA6304';

    return Column(
      children: [
        const Text(
          'Scan QRIS Statis Toko',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Mendukung GoPay, OVO, Dana, ShopeePay, BCA, Mandiri, dll.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              QrImageView(
                data: qrisPayload,
                version: QrVersions.auto,
                size: 190.0,
                gapless: true,
              ),
              const SizedBox(height: 8),
              Text(
                settings.storeName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                'NMID: ID102003891829 • ${CurrencyFormatter.format(total)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        CheckboxListTile(
          value: _qrisConfirmed,
          onChanged: (val) => setState(() => _qrisConfirmed = val ?? false),
          title: const Text(
            'Konfirmasi Pembayaran Diterima',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Kasir telah memverifikasi bukti transaksi sukses pada ponsel pelanggan.',
            style: TextStyle(fontSize: 12),
          ),
          activeColor: AppColors.success,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildDebitView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Bank / Mesin EDC:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['BCA', 'Mandiri', 'BRI', 'BNI', 'CIMB'].map((bank) {
            final isSelected = _selectedBank == bank;
            return ChoiceChip(
              label: Text(bank),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedBank = bank);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text(
          'Nomor Approval / Trace Reference (EDC):',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cardRefController,
          keyboardType: TextInputType.text,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Misal: 084920 atau Ref ID struk EDC',
            prefixIcon: Icon(Icons.receipt_long, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '* Sesuai standar keamanan (FR-PAY-03), nomor kartu tidak disimpan.',
          style: TextStyle(fontSize: 11, color: AppColors.textMutedLight),
        ),
      ],
    );
  }

  Widget _buildSplitView(int total, bool isDark) {
    final splitCash = int.tryParse(_splitCashController.text.trim()) ?? 0;
    final remainder = (total - splitCash).clamp(0, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bagi Pembayaran (Split Bill):',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        const Text('1. Bayar Tunai:'),
        const SizedBox(height: 6),
        TextField(
          controller: _splitCashController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            hintText: 'Nominal tunai',
          ),
        ),
        const SizedBox(height: 16),

        Text('2. Sisa Tagihan: ${CurrencyFormatter.format(remainder)}'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Bayar via QRIS'),
                selected: _splitSecondMethod == PaymentMethod.qris,
                onSelected: (val) {
                  if (val) setState(() => _splitSecondMethod = PaymentMethod.qris);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Bayar via Debit'),
                selected: _splitSecondMethod == PaymentMethod.debit,
                onSelected: (val) {
                  if (val) setState(() => _splitSecondMethod = PaymentMethod.debit);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
