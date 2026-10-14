import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_models.dart';

final categoriesProvider = Provider<List<Category>>((ref) {
  return const [
    Category(id: 'cat-all', name: 'Semua Menu', icon: '🍽️', sortOrder: 0),
    Category(id: 'cat-food', name: 'Makanan Utama', icon: '🍛', sortOrder: 1),
    Category(id: 'cat-drink', name: 'Minuman Segar', icon: '🥤', sortOrder: 2),
    Category(id: 'cat-snack', name: 'Camilan & Snack', icon: '🍟', sortOrder: 3),
    Category(id: 'cat-package', name: 'Paket Hemat', icon: '🍱', sortOrder: 4),
  ];
});

const List<Product> _initialProducts = [
    Product(
      id: 'prd-001',
      categoryId: 'cat-food',
      name: 'Nasi Goreng Spesial Warung',
      description: 'Nasi goreng harum rempah khas dengan suwiran ayam, acar segar, dan kerupuk renyah.',
      basePrice: 25000,
      variants: [
        ProductVariant(id: 'var-1', name: 'Porsi Reguler', priceDifference: 0),
        ProductVariant(id: 'var-2', name: 'Porsi Jumbo', priceDifference: 7000),
      ],
      modifierGroups: [
        ModifierGroup(
          id: 'modg-1',
          name: 'Tingkat Kepedasan',
          isRequired: true,
          minSelect: 1,
          maxSelect: 1,
          options: [
            ModifierOption(id: 'pedas-0', name: 'Tidak Pedas (Anak-anak)', additionalPrice: 0),
            ModifierOption(id: 'pedas-1', name: 'Sedang (Level 1)', additionalPrice: 0),
            ModifierOption(id: 'pedas-2', name: 'Pedas Mantap (Level 3)', additionalPrice: 0),
            ModifierOption(id: 'pedas-3', name: 'Pedas Gila (Level 5)', additionalPrice: 2000),
          ],
        ),
        ModifierGroup(
          id: 'modg-2',
          name: 'Topping Tambahan',
          isRequired: false,
          minSelect: 0,
          maxSelect: 3,
          options: [
            ModifierOption(id: 'top-telur', name: 'Telur Ceplok Mata Sapi', additionalPrice: 4000),
            ModifierOption(id: 'top-sosis', name: 'Sosis Sapi Panggang', additionalPrice: 4000),
            ModifierOption(id: 'top-ati', name: 'Ati Ampela Bumbu', additionalPrice: 5000),
            ModifierOption(id: 'top-keju', name: 'Keju Mozzarella Leleh', additionalPrice: 6000),
          ],
        ),
      ],
    ),
    Product(
      id: 'prd-002',
      categoryId: 'cat-food',
      name: 'Ayam Geprek Sambal Matah',
      description: 'Ayam krispi gurih dengan ulekan sambal matah Bali segar dan sereh wangi.',
      basePrice: 24000,
      variants: [
        ProductVariant(id: 'var-ag-1', name: 'Bagian Dada', priceDifference: 0),
        ProductVariant(id: 'var-ag-2', name: 'Bagian Paha Atas', priceDifference: 0),
      ],
      modifierGroups: [
        ModifierGroup(
          id: 'modg-ag-1',
          name: 'Level Sambal',
          isRequired: true,
          minSelect: 1,
          maxSelect: 1,
          options: [
            ModifierOption(id: 'matah-1', name: 'Level 1 (Sedang)', additionalPrice: 0),
            ModifierOption(id: 'matah-2', name: 'Level 3 (Pedas)', additionalPrice: 0),
            ModifierOption(id: 'matah-3', name: 'Level 5 (Ekstra Pedas)', additionalPrice: 2000),
          ],
        ),
        ModifierGroup(
          id: 'modg-ag-2',
          name: 'Pelengkap',
          isRequired: false,
          minSelect: 0,
          maxSelect: 2,
          options: [
            ModifierOption(id: 'ag-nasi', name: 'Tambah Nasi Putih Wangi', additionalPrice: 5000),
            ModifierOption(id: 'ag-tahu', name: 'Tahu & Tempe Goreng', additionalPrice: 4000),
          ],
        ),
      ],
    ),
    Product(
      id: 'prd-003',
      categoryId: 'cat-food',
      name: 'Mie Goreng Seafood Spesial',
      description: 'Mie telur kenyal dimasak dengan udang segar, cumi, bakso ikan, dan sawi hijau.',
      basePrice: 28000,
      variants: [
        ProductVariant(id: 'var-mg-1', name: 'Porsi Reguler', priceDifference: 0),
        ProductVariant(id: 'var-mg-2', name: 'Porsi Jumbo', priceDifference: 8000),
      ],
      modifierGroups: [
        ModifierGroup(
          id: 'modg-mg-1',
          name: 'Tingkat Kepedasan',
          isRequired: true,
          minSelect: 1,
          maxSelect: 1,
          options: [
            ModifierOption(id: 'mg-pedas-0', name: 'Tidak Pedas', additionalPrice: 0),
            ModifierOption(id: 'mg-pedas-1', name: 'Pedas Sedang', additionalPrice: 0),
            ModifierOption(id: 'mg-pedas-2', name: 'Pedas Banget', additionalPrice: 0),
          ],
        ),
      ],
    ),
    Product(
      id: 'prd-004',
      categoryId: 'cat-food',
      name: 'Sate Ayam Madura (10 Tusuk)',
      description: 'Daging ayam empuk dibakar arang dengan siraman bumbu kacang kental gurih.',
      basePrice: 30000,
      modifierGroups: [
        ModifierGroup(
          id: 'modg-sate-1',
          name: 'Pilihan Bumbu',
          isRequired: true,
          minSelect: 1,
          maxSelect: 1,
          options: [
            ModifierOption(id: 'sate-kacang', name: 'Bumbu Kacang Kental', additionalPrice: 0),
            ModifierOption(id: 'sate-kecap', name: 'Bumbu Kecap Rawit Manis', additionalPrice: 0),
          ],
        ),
        ModifierGroup(
          id: 'modg-sate-2',
          name: 'Karbohidrat Tambahan',
          isRequired: false,
          minSelect: 0,
          maxSelect: 1,
          options: [
            ModifierOption(id: 'sate-lontong', name: 'Lontong Daun Pisang (1 Porsi)', additionalPrice: 5000),
            ModifierOption(id: 'sate-nasi', name: 'Nasi Putih Hangat', additionalPrice: 5000),
          ],
        ),
      ],
    ),
    Product(
      id: 'prd-005',
      categoryId: 'cat-food',
      name: 'Kwetiau Goreng Daging Sapi',
      description: 'Kwetiau beras lembut tumis daging sapi iris lembut, tauge renyah, dan telur orak-arik.',
      basePrice: 32000,
      variants: [
        ProductVariant(id: 'var-kw-1', name: 'Porsi Reguler', priceDifference: 0),
        ProductVariant(id: 'var-kw-2', name: 'Porsi Jumbo', priceDifference: 8000),
      ],
    ),
    Product(
      id: 'prd-006',
      categoryId: 'cat-drink',
      name: 'Es Teh Manis Jumbo',
      description: 'Seduhan teh melati tradisional dingin menyegarkan dalam gelas jumbo.',
      basePrice: 6000,
      modifierGroups: [
        ModifierGroup(
          id: 'modg-teh-1',
          name: 'Kadar Gula',
          isRequired: true,
          minSelect: 1,
          maxSelect: 1,
          options: [
            ModifierOption(id: 'teh-normal', name: 'Manis Normal', additionalPrice: 0),
            ModifierOption(id: 'teh-less', name: 'Less Sugar (Sedikit Gula)', additionalPrice: 0),
            ModifierOption(id: 'teh-tawar', name: 'Tawar (Tanpa Gula)', additionalPrice: 0),
          ],
        ),
        ModifierGroup(
          id: 'modg-teh-2',
          name: 'Topping Tambahan',
          isRequired: false,
          minSelect: 0,
          maxSelect: 1,
          options: [
            ModifierOption(id: 'teh-lemon', name: 'Perasan Lemon Segar', additionalPrice: 3000),
            ModifierOption(id: 'teh-selasih', name: 'Biji Selasih', additionalPrice: 2000),
          ],
        ),
      ],
    ),
    Product(
      id: 'prd-007',
      categoryId: 'cat-drink',
      name: 'Kopi Susu Gula Aren Asli',
      description: 'Double shot espresso blend Nusantara dengan susu segar dan sirup aren organik.',
      basePrice: 18000,
      modifierGroups: [
        ModifierGroup(
          id: 'modg-kopi-1',
          name: 'Es Batu',
          isRequired: true,
          minSelect: 1,
          maxSelect: 1,
          options: [
            ModifierOption(id: 'ice-normal', name: 'Normal Ice', additionalPrice: 0),
            ModifierOption(id: 'ice-less', name: 'Less Ice', additionalPrice: 0),
            ModifierOption(id: 'ice-none', name: 'No Ice', additionalPrice: 0),
          ],
        ),
        ModifierGroup(
          id: 'modg-kopi-2',
          name: 'Ekstra',
          isRequired: false,
          minSelect: 0,
          maxSelect: 1,
          options: [
            ModifierOption(id: 'kopi-double', name: 'Extra Shot Espresso', additionalPrice: 5000),
            ModifierOption(id: 'kopi-jelly', name: 'Coffee Jelly Topping', additionalPrice: 4000),
          ],
        ),
      ],
    ),
    Product(
      id: 'prd-008',
      categoryId: 'cat-drink',
      name: 'Es Jeruk Peras Murni',
      description: 'Perasan jeruk Pontianak segar asli tanpa perisa buatan, manis alami.',
      basePrice: 12000,
    ),
    Product(
      id: 'prd-009',
      categoryId: 'cat-snack',
      name: 'Dimsum Mentai Panggang (4 pcs)',
      description: 'Dimsum ayam udang lembut diselimuti saus mentai gurih dibakar torch harum.',
      basePrice: 20000,
    ),
    Product(
      id: 'prd-010',
      categoryId: 'cat-snack',
      name: 'Pisang Goreng Keju Cokelat',
      description: 'Pisang raja goreng tepung renyah dengan taburan keju cheddar parut dan susu kental manis cokelat.',
      basePrice: 16000,
    ),
    Product(
      id: 'prd-011',
      categoryId: 'cat-snack',
      name: 'Kentang Goreng Crinkle Cut',
      description: 'Kentang goreng renyah bumbu keju gurih dengan saus sambal dan mayones.',
      basePrice: 15000,
    ),
    Product(
      id: 'prd-012',
      categoryId: 'cat-package',
      name: 'Paket Nasi Liwet Komplit',
      description: 'Nasi liwet wangi, ayam bakar bumbu rujak, tahu tempe, sambal terasi, lalap, dan es teh.',
      basePrice: 35000,
      modifierGroups: [
        ModifierGroup(
          id: 'modg-pkt-1',
          name: 'Varian Ayam',
          isRequired: true,
          minSelect: 1,
          maxSelect: 1,
          options: [
            ModifierOption(id: 'pkt-bakar', name: 'Ayam Bakar Madu', additionalPrice: 0),
            ModifierOption(id: 'pkt-goreng', name: 'Ayam Goreng Lengkuas', additionalPrice: 0),
          ],
        ),
      ],
    ),
    Product(
      id: 'prd-013',
      categoryId: 'cat-package',
      name: 'Paket Sarapan Hemat',
      description: 'Nasi Kuning komplit dengan orek tempe, telur balado, kerupuk, plus kopi/teh hangat.',
      basePrice: 22000,
    ),
  ];

class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    return _initialProducts;
  }

  void addProduct(Product product) {
    state = [product, ...state];
  }

  void updateProduct(Product product) {
    state = state.map((p) => p.id == product.id ? product : p).toList();
  }

  void deleteProduct(String productId) {
    state = state.where((p) => p.id != productId).toList();
  }

  void toggleProductStatus(String productId) {
    state = state.map((p) {
      if (p.id == productId) {
        return Product(
          id: p.id,
          categoryId: p.categoryId,
          name: p.name,
          description: p.description,
          basePrice: p.basePrice,
          imageUrl: p.imageUrl,
          isActive: !p.isActive,
          variants: p.variants,
          modifierGroups: p.modifierGroups,
        );
      }
      return p;
    }).toList();
  }
}

final allProductsProvider = NotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

// Category selection filter
class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'cat-all';
  void setCategory(String id) => state = id;
}

final selectedCategoryIdProvider = NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

// Product search query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// Filtered products provider based on active category & search query
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final allProducts = ref.watch(allProductsProvider);
  final selectedCategory = ref.watch(selectedCategoryIdProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return allProducts.where((product) {
    if (!product.isActive) return false;
    final matchesCategory = selectedCategory == 'cat-all' || product.categoryId == selectedCategory;
    final matchesQuery = query.isEmpty ||
        product.name.toLowerCase().contains(query) ||
        product.description.toLowerCase().contains(query);
    return matchesCategory && matchesQuery;
  }).toList();
});
