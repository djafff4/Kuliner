import 'package:flutter/material.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/features/menu/models/menu_models.dart';
import 'package:pos_kuliner/features/pos/models/cart_item_model.dart';

class ModifierSelectorSheet extends StatefulWidget {
  final Product product;
  final Function({
    required Product product,
    ProductVariant? variant,
    required List<CartItemModifier> modifiers,
    required int quantity,
    required String note,
  }) onConfirm;

  const ModifierSelectorSheet({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  @override
  State<ModifierSelectorSheet> createState() => _ModifierSelectorSheetState();
}

class _ModifierSelectorSheetState extends State<ModifierSelectorSheet> {
  ProductVariant? _selectedVariant;
  final Map<String, List<ModifierOption>> _selectedModifiers = {};
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }

    for (final group in widget.product.modifierGroups) {
      if (group.isRequired && group.options.isNotEmpty) {
        _selectedModifiers[group.id] = [group.options.first];
      } else {
        _selectedModifiers[group.id] = [];
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _calculatedUnitPrice {
    int total = widget.product.basePrice;
    if (_selectedVariant != null) {
      total += _selectedVariant!.priceDifference;
    }
    _selectedModifiers.forEach((groupId, options) {
      for (final opt in options) {
        total += opt.additionalPrice;
      }
    });
    return total;
  }

  int get _calculatedGrandTotal => _calculatedUnitPrice * _quantity;

  bool get _isValid {
    for (final group in widget.product.modifierGroups) {
      final selected = _selectedModifiers[group.id] ?? [];
      if (group.isRequired && selected.length < group.minSelect) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Harga Dasar: ${CurrencyFormatter.format(widget.product.basePrice)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 1. Variants Section (if any)
                if (widget.product.variants.isNotEmpty) ...[
                  _buildSectionHeader('PILIH VARIAN / UKURAN', isRequired: true),
                  ...widget.product.variants.map((v) {
                    final isSelected = _selectedVariant?.id == v.id;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedVariant = v;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight.withValues(alpha: 0.4)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? AppColors.primary : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                v.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (v.priceDifference > 0)
                              Text(
                                '+${CurrencyFormatter.format(v.priceDifference)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // 2. Modifier Groups (Required & Optional)
                ...widget.product.modifierGroups.map((group) {
                  final selectedList = _selectedModifiers[group.id] ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        group.name.toUpperCase(),
                        isRequired: group.isRequired,
                        subtitle: group.maxSelect > 1 ? '(Pilih maks. ${group.maxSelect})' : null,
                      ),
                      ...group.options.map((option) {
                        final isSelected = selectedList.any((opt) => opt.id == option.id);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (group.maxSelect == 1) {
                                _selectedModifiers[group.id] = [option];
                              } else {
                                if (isSelected) {
                                  _selectedModifiers[group.id] = selectedList
                                      .where((opt) => opt.id != option.id)
                                      .toList();
                                } else {
                                  if (selectedList.length < group.maxSelect) {
                                    _selectedModifiers[group.id] = [...selectedList, option];
                                  }
                                }
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryLight.withValues(alpha: 0.4)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  group.maxSelect == 1
                                      ? (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked)
                                      : (isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                                  color: isSelected ? AppColors.primary : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (option.additionalPrice > 0)
                                  Text(
                                    '+${CurrencyFormatter.format(option.additionalPrice)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  );
                }),

                // 3. Special Notes field
                _buildSectionHeader('CATATAN KHUSUS (OPSIONAL)'),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Misal: "tanpa bawang daun", "sambal dipisah"',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    prefixIcon: const Icon(Icons.edit_note, size: 22),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
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
                // Qty Stepper
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        icon: const Icon(Icons.remove, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm Add Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValid
                        ? () {
                            final List<CartItemModifier> flatModifiers = [];
                            _selectedModifiers.forEach((groupId, options) {
                              for (final opt in options) {
                                flatModifiers.add(CartItemModifier(
                                  optionId: opt.id,
                                  nameSnapshot: opt.name,
                                  priceSnapshot: opt.additionalPrice,
                                ));
                              }
                            });

                            widget.onConfirm(
                              product: widget.product,
                              variant: _selectedVariant,
                              modifiers: flatModifiers,
                              quantity: _quantity,
                              note: _noteController.text.trim(),
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_shopping_cart, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Tambah (${CurrencyFormatter.format(_calculatedGrandTotal)})',
                          style: const TextStyle(
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

  Widget _buildSectionHeader(String title, {bool isRequired = false, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (isRequired) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'WAJIB',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMutedLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
