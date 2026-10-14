import 'package:flutter/material.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';

class DiscountDialog extends StatefulWidget {
  final int subtotal;
  final double currentPercent;
  final int currentNominal;
  final String currentReason;
  final Function({double percent, int nominal, String reason}) onApply;

  const DiscountDialog({
    super.key,
    required this.subtotal,
    this.currentPercent = 0,
    this.currentNominal = 0,
    this.currentReason = '',
    required this.onApply,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  bool _isPercentage = true;
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.currentNominal > 0) {
      _isPercentage = false;
      _valueController.text = widget.currentNominal.toString();
    } else if (widget.currentPercent > 0) {
      _isPercentage = true;
      _valueController.text = widget.currentPercent.toStringAsFixed(0);
    }
    _reasonController.text = widget.currentReason;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _calculatedDiscount {
    final text = _valueController.text.trim();
    final val = double.tryParse(text) ?? 0;
    if (_isPercentage) {
      return ((widget.subtotal * val) / 100).round();
    } else {
      return val.toInt().clamp(0, widget.subtotal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.discount_outlined, color: AppColors.primary, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Terapkan Diskon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Toggle Percentage vs Nominal
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isPercentage = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isPercentage ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isPercentage ? AppColors.primary : Colors.grey.shade400,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Persentase (%)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isPercentage ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isPercentage = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isPercentage ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_isPercentage ? AppColors.primary : Colors.grey.shade400,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Nominal (Rp)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: !_isPercentage ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Value Input
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _isPercentage ? 'Persen Diskon (%)' : 'Nominal Diskon (Rp)',
                prefixText: _isPercentage ? null : 'Rp ',
                suffixText: _isPercentage ? '%' : null,
              ),
            ),
            const SizedBox(height: 12),

            // Preset Buttons
            Wrap(
              spacing: 8,
              children: _isPercentage
                  ? [5, 10, 15, 20, 50].map((p) {
                      return ActionChip(
                        label: Text('$p%'),
                        onPressed: () {
                          setState(() {
                            _valueController.text = p.toString();
                          });
                        },
                      );
                    }).toList()
                  : [5000, 10000, 20000, 50000].map((nom) {
                      return ActionChip(
                        label: Text(CurrencyFormatter.formatCompact(nom)),
                        onPressed: () {
                          setState(() {
                            _valueController.text = nom.toString();
                          });
                        },
                      );
                    }).toList(),
            ),
            const SizedBox(height: 12),

            // Reason Input
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan Diskon (Wajib Audit)',
                hintText: 'Misal: Promo Akhir Pekan, Voucher Tamu',
                prefixIcon: Icon(Icons.notes, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Potongan Harga:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    CurrencyFormatter.format(_calculatedDiscount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(percent: 0, nominal: 0, reason: '');
                      Navigator.pop(context);
                    },
                    child: const Text('Hapus Diskon'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _calculatedDiscount > 0
                        ? () {
                            final val = double.tryParse(_valueController.text.trim()) ?? 0;
                            widget.onApply(
                              percent: _isPercentage ? val : 0,
                              nominal: !_isPercentage ? val.toInt() : 0,
                              reason: _reasonController.text.trim().isEmpty
                                  ? (_isPercentage ? 'Diskon $val%' : 'Diskon Rp ${val.toInt()}')
                                  : _reasonController.text.trim(),
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    child: const Text('Terapkan'),
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
