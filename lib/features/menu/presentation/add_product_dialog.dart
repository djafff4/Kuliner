import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_kuliner/core/theme/app_colors.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/features/menu/models/menu_models.dart';
import 'package:pos_kuliner/features/menu/providers/menu_provider.dart';
import 'package:pos_kuliner/features/sync/providers/sync_provider.dart';
import 'package:uuid/uuid.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  final Product? productToEdit;

  const AddProductDialog({super.key, this.productToEdit});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;

  late String _selectedCategoryId;

  // Variants list
  final List<ProductVariant> _variants = [];
  final _variantNameController = TextEditingController();
  final _variantPriceDiffController = TextEditingController();
  bool _showAddVariantForm = false;

  // Modifiers list
  final List<ModifierOption> _toppings = [];
  final _toppingNameController = TextEditingController();
  final _toppingPriceController = TextEditingController();
  bool _showAddToppingForm = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.productToEdit;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _priceController = TextEditingController(text: edit != null ? edit.basePrice.toString() : '');
    _descController = TextEditingController(text: edit?.description ?? '');
    _selectedCategoryId = edit?.categoryId ?? 'cat-food';

    if (edit != null) {
      _variants.addAll(edit.variants);
      for (final g in edit.modifierGroups) {
        _toppings.addAll(g.options);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _variantNameController.dispose();
    _variantPriceDiffController.dispose();
    _toppingNameController.dispose();
    _toppingPriceController.dispose();
    super.dispose();
  }

  void _addVariant() {
    final name = _variantNameController.text.trim();
    final diff = int.tryParse(_variantPriceDiffController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (name.isNotEmpty) {
      setState(() {
        _variants.add(ProductVariant(
          id: const Uuid().v4(),
          name: name,
          priceDifference: diff,
        ));
        _variantNameController.clear();
        _variantPriceDiffController.clear();
        _showAddVariantForm = false;
      });
    }
  }

  void _addTopping() {
    final name = _toppingNameController.text.trim();
    final price = int.tryParse(_toppingPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (name.isNotEmpty) {
      setState(() {
        _toppings.add(ModifierOption(
          id: const Uuid().v4(),
          name: name,
          additionalPrice: price,
        ));
        _toppingNameController.clear();
        _toppingPriceController.clear();
        _showAddToppingForm = false;
      });
    }
  }

  void _saveProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      final basePrice = int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (basePrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harga dasar produk harus lebih dari Rp 0!')),
        );
        return;
      }

      final List<ModifierGroup> modifierGroups = [];
      if (_toppings.isNotEmpty) {
        modifierGroups.add(
          ModifierGroup(
            id: widget.productToEdit?.modifierGroups.isNotEmpty == true
                ? widget.productToEdit!.modifierGroups.first.id
                : const Uuid().v4(),
            name: 'Pilihan Topping',
            isRequired: false,
            minSelect: 0,
            maxSelect: _toppings.length,
            options: List.from(_toppings),
          ),
        );
      }

      final isEditing = widget.productToEdit != null;
      final productId = isEditing ? widget.productToEdit!.id : const Uuid().v4();

      final product = Product(
        id: productId,
        categoryId: _selectedCategoryId,
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? 'Menu spesial lezat disajikan hangat dan segar.'
            : _descController.text.trim(),
        basePrice: basePrice,
        imageUrl: widget.productToEdit?.imageUrl,
        isActive: widget.productToEdit?.isActive ?? true,
        variants: List.from(_variants),
        modifierGroups: modifierGroups,
      );

      // Save to Riverpod state
      if (isEditing) {
        ref.read(allProductsProvider.notifier).updateProduct(product);
      } else {
        ref.read(allProductsProvider.notifier).addProduct(product);
      }

      // Add to outbox for cloud sync
      ref.read(syncProvider.notifier).addToOutbox(
        entityType: 'product',
        entityId: product.id,
        payload: {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'base_price': product.basePrice,
          'category_id': product.categoryId,
          'is_active': product.isActive,
        },
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Menu "${product.name}" berhasil diperbarui!'
              : 'Menu "${product.name}" berhasil ditambahkan ke katalog kasir!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDeleteProduct() {
    final product = widget.productToEdit;
    if (product == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 26),
            SizedBox(width: 10),
            Text('Hapus Menu Ini?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${product.name}" dari daftar menu?\n\n'
          'Menu yang dihapus akan langsung hilang dari katalog kasir.',
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menu "${product.name}" telah dihapus!'),
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
    final categories = ref.watch(categoriesProvider).where((c) => c.id != 'cat-all').toList();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          children: [
            // Dialog Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        widget.productToEdit != null ? Icons.edit_note : Icons.add_circle_outline,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.productToEdit != null ? 'Edit Menu' : 'Tambah Menu Baru',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.productToEdit != null)
                      IconButton(
                        onPressed: _confirmDeleteProduct,
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        tooltip: 'Hapus Menu Ini',
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),

            // Scrollable Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 1. Nama Produk
                    const Text('Nama Produk / Menu *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Misal: Soto Ayam Lamongan, Es Kopi Tarik',
                        prefixIcon: Icon(Icons.fastfood_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama produk wajib diisi!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Kategori Menu
                    const Text('Kategori Menu *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = cat.id == _selectedCategoryId;
                        return ChoiceChip(
                          avatar: Text(cat.icon, style: const TextStyle(fontSize: 14)),
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategoryId = cat.id);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 3. Harga Dasar
                    const Text('Harga Dasar (Rp) *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '25000',
                        prefixIcon: Icon(Icons.monetization_on_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Harga dasar wajib diisi!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 4. Deskripsi Produk
                    const Text('Deskripsi Singkat Menu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Misal: Kuah koya gurih kaya rempah dengan irisan ayam kampung dan telur rebus.',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // 5. Varian Produk (Opsional, e.g. Reguler vs Jumbo)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Varian Ukuran / Porsi (Opsional)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _showAddVariantForm = !_showAddVariantForm),
                          icon: Icon(_showAddVariantForm ? Icons.remove : Icons.add, size: 16),
                          label: Text(_showAddVariantForm ? 'Tutup' : '+ Varian'),
                        ),
                      ],
                    ),
                    if (_variants.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _variants.map((v) {
                          return Chip(
                            label: Text('${v.name} (+${CurrencyFormatter.format(v.priceDifference)})'),
                            onDeleted: () {
                              setState(() => _variants.remove(v));
                            },
                            deleteIconColor: AppColors.danger,
                          );
                        }).toList(),
                      ),
                    ],
                    if (_showAddVariantForm) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.bgDark : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _variantNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Varian (misal: Porsi Jumbo)',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _variantPriceDiffController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Selisih Harga Tambahan (Rp)',
                                prefixText: 'Rp ',
                                hintText: '7000',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _addVariant,
                              child: const Text('Simpan Varian'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 6. Topping / Modifier Tambahan (Opsional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Topping / Add-on Tambahan (Opsional)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _showAddToppingForm = !_showAddToppingForm),
                          icon: Icon(_showAddToppingForm ? Icons.remove : Icons.add, size: 16),
                          label: Text(_showAddToppingForm ? 'Tutup' : '+ Topping'),
                        ),
                      ],
                    ),
                    if (_toppings.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _toppings.map((t) {
                          return Chip(
                            label: Text('${t.name} (+${CurrencyFormatter.format(t.additionalPrice)})'),
                            onDeleted: () {
                              setState(() => _toppings.remove(t));
                            },
                            deleteIconColor: AppColors.danger,
                          );
                        }).toList(),
                      ),
                    ],
                    if (_showAddToppingForm) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.bgDark : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _toppingNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Topping (misal: Telur Ceplok, Keju Mozzarella)',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _toppingPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga Topping (Rp)',
                                prefixText: 'Rp ',
                                hintText: '4000',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _addTopping,
                              child: const Text('Simpan Topping'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Bottom Dialog Actions
            Row(
              children: [
                if (widget.productToEdit != null) ...[
                  IconButton.outlined(
                    onPressed: _confirmDeleteProduct,
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                    tooltip: 'Hapus Menu Ini',
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveProduct,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(widget.productToEdit != null ? 'Simpan' : 'Simpan Menu'),
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
