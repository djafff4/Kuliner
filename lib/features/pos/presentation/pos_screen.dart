import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/features/menu/models/menu_models.dart';
import 'package:pos_kuliner/features/menu/presentation/add_product_dialog.dart';
import 'package:pos_kuliner/features/menu/providers/menu_provider.dart';
import 'package:pos_kuliner/features/pos/presentation/widgets/cart_panel.dart';
import 'package:pos_kuliner/features/pos/presentation/widgets/modifier_selector_sheet.dart';
import 'package:pos_kuliner/features/pos/presentation/widgets/product_card.dart';
import 'package:pos_kuliner/features/pos/providers/cart_provider.dart';
import 'package:pos_kuliner/features/sync/providers/sync_provider.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryIdProvider);
    final products = ref.watch(filteredProductsProvider);
    final cart = ref.watch(cartProvider);
    final cartSummary = ref.watch(cartSummaryProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 820;

        return Scaffold(
          body: Row(
            children: [
              // Left Column: Catalog & Search
              Expanded(
                child: Column(
                  children: [
                    // Top Search & Category Filter Bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (val) {
                              ref.read(searchQueryProvider.notifier).setQuery(val);
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari menu kuliner, minuman, atau snack...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        ref.read(searchQueryProvider.notifier).clear();
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              // Categories Chips
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      final cat = categories[index];
                                      final isSelected = cat.id == selectedCategory;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: FilterChip(
                                          selected: isSelected,
                                          label: Text('${cat.icon} ${cat.name}'),
                                          labelStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? Colors.white : null,
                                          ),
                                          backgroundColor: isDark ? AppColors.bgDark : Colors.grey.shade100,
                                          selectedColor: AppColors.primary,
                                          checkmarkColor: Colors.white,
                                          showCheckmark: false,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          onSelected: (_) {
                                            ref.read(selectedCategoryIdProvider.notifier).setCategory(cat.id);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Quick Add Product Button
                              ElevatedButton.icon(
                                onPressed: () => _showAddProductDialog(context),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Menu Baru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Products Grid
                    Expanded(
                      child: products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 52,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Menu tidak ditemukan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddProductDialog(context),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Tambah Menu Sekarang'),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isWideScreen
                                    ? (constraints.maxWidth > 1150 ? 4 : 3)
                                    : (constraints.maxWidth < 360 ? 1 : 2),
                                childAspectRatio: isWideScreen
                                    ? 0.85
                                    : (constraints.maxWidth < 360 ? 2.3 : 0.76),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: products.length + 1, // +1 for "Add New Product" Card
                              itemBuilder: (context, index) {
                                // If last item: Show "+ Tambah Menu Baru" Card
                                if (index == products.length) {
                                  return Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      onTap: () => _showAddProductDialog(context),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(alpha: 0.6),
                                            width: 1.5,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight.withValues(alpha: 0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.add, color: AppColors.primary, size: 28),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Tambah Menu Baru',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Input makanan / minuman',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final product = products[index];
                                return ProductCard(
                                  product: product,
                                  onTap: () {
                                    if (product.hasOptions) {
                                      _showModifierSheet(context, ref, product);
                                    } else {
                                      ref.read(cartProvider.notifier).addItem(product: product);
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${product.name} ditambahkan'),
                                          duration: const Duration(milliseconds: 700),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  onLongPress: () {
                                    _showProductQuickMenu(context, ref, product);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // Right Column: Cart Panel (on Wide Screen)
              if (isWideScreen)
                const SizedBox(
                  width: 380,
                  child: CartPanel(),
                ),
            ],
          ),

          // Bottom Bar for Mobile Screen (< 820px)
          bottomNavigationBar: (!isWideScreen && cart.items.isNotEmpty)
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.9,
                          ),
                          child: const ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            child: CartPanel(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${cart.totalItemCount} Item',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Lihat Keranjang',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(cartSummary.grandTotal),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AddProductDialog(),
    );
  }

  void _showModifierSheet(BuildContext context, WidgetRef ref, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModifierSelectorSheet(
        product: product,
        onConfirm: ({
          required product,
          variant,
          required modifiers,
          required quantity,
          required note,
        }) {
          ref.read(cartProvider.notifier).addItem(
                product: product,
                variant: variant,
                modifiers: modifiers,
                quantity: quantity,
                note: note,
              );
        },
      ),
    );
  }

  void _showProductQuickMenu(BuildContext context, WidgetRef ref, Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fastfood, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(product.basePrice),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (product.hasOptions)
                  ListTile(
                    leading: const Icon(Icons.tune, color: AppColors.primary),
                    title: const Text('Pesan dengan Varian & Topping', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showModifierSheet(context, ref, product);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.info),
                  title: const Text('Edit Produk Menu Ini', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (ctx2) => AddProductDialog(productToEdit: product),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: AppColors.warning),
                  title: const Text('Tandai Stok Habis (Nonaktifkan)', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    ref.read(allProductsProvider.notifier).toggleProductStatus(product.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menu "${product.name}" dinonaktifkan dari katalog.'),
                        backgroundColor: AppColors.warning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: const Text(
                    'Hapus Menu dari Katalog',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteProduct(context, ref, product);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteProduct(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 26),
            SizedBox(width: 10),
            Text('Hapus Produk Menu?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${product.name}" dari katalog kasir?\n\n'
          'Perhatian: Menu yang telah dihapus tidak dapat dipulihkan kembali.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(allProductsProvider.notifier).deleteProduct(product.id);
              ref.read(syncProvider.notifier).addToOutbox(
                entityType: 'delete_product',
                entityId: product.id,
                payload: {'id': product.id},
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menu "${product.name}" berhasil dihapus dari katalog!'),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Ya, Hapus Menu'),
          ),
        ],
      ),
    );
  }
}
