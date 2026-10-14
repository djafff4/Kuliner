import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/features/menu/models/menu_models.dart';
import 'package:pos_kuliner/features/menu/presentation/add_product_dialog.dart';
import 'package:pos_kuliner/features/menu/providers/menu_provider.dart';
import 'package:pos_kuliner/features/sync/providers/sync_provider.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  String _selectedCategory = 'cat-all';
  String _searchQuery = '';
  int _statusFilterIndex = 0; // 0: Semua, 1: Hanya Aktif, 2: Hanya Nonaktif

  void _openAddProductDialog([Product? productToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddProductDialog(productToEdit: productToEdit),
    );
  }

  void _confirmDeleteProduct(BuildContext context, Product product) {
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
          'Apakah Anda yakin ingin menghapus "${product.name}" dari katalog menu?\n\n'
          'Perhatian: Menu yang telah dihapus tidak dapat dipulihkan.',
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
                  content: Text('Menu "${product.name}" telah dihapus.'),
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

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(allProductsProvider);
    final categories = ref.watch(categoriesProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter products
    final filtered = allProducts.where((p) {
      final matchCat = _selectedCategory == 'cat-all' || p.categoryId == _selectedCategory;
      final matchQuery = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus = _statusFilterIndex == 0
          ? true
          : (_statusFilterIndex == 1 ? p.isActive : !p.isActive);
      return matchCat && matchQuery && matchStatus;
    }).toList();

    // Stats
    final totalCount = allProducts.length;
    final activeCount = allProducts.where((p) => p.isActive).length;
    final inactiveCount = totalCount - activeCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        return Scaffold(
          body: Column(
            children: [
              // 1. KPI Stats Summary Bar
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 16 : 20,
                  vertical: isCompact ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                ),
                child: isCompact
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildCompactStatCard(
                              'Total',
                              '$totalCount',
                              Icons.restaurant_menu,
                              AppColors.primary,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCompactStatCard(
                              'Aktif',
                              '$activeCount',
                              Icons.check_circle_outline,
                              AppColors.success,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCompactStatCard(
                              'Habis',
                              '$inactiveCount',
                              Icons.block,
                              AppColors.warning,
                              isDark,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Total Menu',
                              value: '$totalCount Item',
                              icon: Icons.restaurant_menu,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Menu Aktif',
                              value: '$activeCount Item',
                              icon: Icons.check_circle_outline,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Stok Habis / Nonaktif',
                              value: '$inactiveCount Item',
                              icon: Icons.block,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => _openAddProductDialog(),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text(
                              'Tambah Produk Baru',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
              ),

              // 2. Filter & Search Toolbar
              Container(
                padding: EdgeInsets.fromLTRB(isCompact ? 16 : 20, 10, isCompact ? 16 : 20, 8),
                color: isDark ? AppColors.bgDark : Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCompact) ...[
                      // Mobile: Search field on top row
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Cari menu atau bahan...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Mobile: Horizontal Scrollable Status Filter
                      SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<int>(
                            segments: [
                              ButtonSegment(value: 0, label: Text('Semua ($totalCount)')),
                              ButtonSegment(value: 1, label: Text('Aktif ($activeCount)')),
                              ButtonSegment(value: 2, label: Text('Habis ($inactiveCount)')),
                            ],
                            selected: {_statusFilterIndex},
                            onSelectionChanged: (set) => setState(() => _statusFilterIndex = set.first),
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Desktop: Search and Status Segmented Button side-by-side
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              decoration: InputDecoration(
                                hintText: 'Cari menu berdasarkan nama atau bahan...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setState(() => _searchQuery = ''),
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SegmentedButton<int>(
                            segments: [
                              ButtonSegment(value: 0, label: Text('Semua ($totalCount)')),
                              ButtonSegment(value: 1, label: Text('Aktif ($activeCount)')),
                              ButtonSegment(value: 2, label: Text('Habis ($inactiveCount)')),
                            ],
                            selected: {_statusFilterIndex},
                            onSelectionChanged: (set) => setState(() => _statusFilterIndex = set.first),
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Category Filter Pills
                    SizedBox(
                      height: 34,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = cat.id == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text('${cat.icon} ${cat.name}'),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : null,
                              ),
                              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                              selectedColor: AppColors.primary,
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => setState(() => _selectedCategory = cat.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Products List / Grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_outlined,
                                size: 56,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum Ada Produk Menu yang Sesuai',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Coba ubah kata kunci pencarian atau klik tombol di bawah untuk menambah menu.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _openAddProductDialog(),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Tambah Menu Sekarang'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(isCompact ? 12 : 20),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => SizedBox(height: isCompact ? 8 : 10),
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return isCompact
                              ? _buildMobileProductCard(context, product, isDark)
                              : _buildDesktopProductListItem(context, product, isDark);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddProductDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Menu'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildCompactStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile clean card layout for phone screen
  Widget _buildMobileProductCard(BuildContext context, Product product, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          // Top: Icon + Name + Status Badge + Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _getCategoryIcon(product.categoryId),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.isActive ? AppColors.successLight : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.isActive ? 'Tersedia' : 'Habis / Nonaktif',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: product.isActive ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Menu',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _openAddProductDialog(product),
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                tooltip: 'Hapus Menu',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _confirmDeleteProduct(context, product),
              ),
            ],
          ),

          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.3,
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Bottom Row: Price + Tags & Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      CurrencyFormatter.format(product.basePrice),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (product.variants.isNotEmpty)
                      _buildChipTag(
                        '${product.variants.length} Varian',
                        Icons.layers_outlined,
                        isDark,
                      ),
                    if (product.modifierGroups.isNotEmpty)
                      _buildChipTag(
                        '${product.modifierGroups.length} Modifier',
                        Icons.tune,
                        isDark,
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.isActive ? 'Aktif' : 'Habis',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: product.isActive,
                      activeThumbColor: AppColors.success,
                      onChanged: (_) {
                        ref.read(allProductsProvider.notifier).toggleProductStatus(product.id);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Desktop/Tablet spacious horizontal list item
  Widget _buildDesktopProductListItem(BuildContext context, Product product, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getCategoryIcon(product.categoryId),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.isActive
                            ? AppColors.successLight
                            : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.isActive ? 'Tersedia' : 'Habis / Nonaktif',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: product.isActive ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),

                // Tags for variants & modifiers
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      CurrencyFormatter.format(product.basePrice),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (product.variants.isNotEmpty)
                      _buildChipTag(
                        '${product.variants.length} Varian',
                        Icons.layers_outlined,
                        isDark,
                      ),
                    if (product.modifierGroups.isNotEmpty)
                      _buildChipTag(
                        '${product.modifierGroups.length} Grup Modifier',
                        Icons.tune,
                        isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Toggle Availability Switch (FR-MENU-04)
          Column(
            children: [
              Switch(
                value: product.isActive,
                activeThumbColor: AppColors.success,
                onChanged: (_) {
                  ref.read(allProductsProvider.notifier).toggleProductStatus(product.id);
                },
              ),
              Text(
                product.isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Action Buttons: Edit & Delete
          IconButton.filledTonal(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit Produk',
            onPressed: () => _openAddProductDialog(product),
          ),
          const SizedBox(width: 6),
          IconButton.outlined(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
            tooltip: 'Hapus Produk',
            onPressed: () => _confirmDeleteProduct(context, product),
          ),
        ],
      ),
    );
  }

  Widget _buildChipTag(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'cat-food':
        return '🍛';
      case 'cat-drink':
        return '🥤';
      case 'cat-snack':
        return '🍟';
      case 'cat-package':
        return '🍱';
      default:
        return '🍽️';
    }
  }
}
