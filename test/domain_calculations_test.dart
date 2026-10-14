import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/features/menu/models/menu_models.dart';
import 'package:pos_kuliner/features/menu/providers/menu_provider.dart';
import 'package:pos_kuliner/features/pos/models/cart_item_model.dart';
import 'package:pos_kuliner/features/pos/models/order_model.dart';
import 'package:pos_kuliner/features/shift/models/shift_model.dart';

void main() {
  group('Perhitungan Harga, Varian, dan Modifiers (FR-MENU & FR-POS)', () {
    test('CartItem menghitung harga satuan dengan varian dan modifiers', () {
      const product = Product(
        id: 'prd-01',
        categoryId: 'cat-food',
        name: 'Nasi Goreng Spesial',
        description: 'Enak',
        basePrice: 25000,
      );

      const variant = ProductVariant(
        id: 'v-1',
        name: 'Jumbo',
        priceDifference: 7000,
      );

      const modifiers = [
        CartItemModifier(
          optionId: 'top-1',
          nameSnapshot: 'Telur Ceplok',
          priceSnapshot: 4000,
        ),
        CartItemModifier(
          optionId: 'top-2',
          nameSnapshot: 'Keju Mozzarella',
          priceSnapshot: 6000,
        ),
      ];

      final cartItem = CartItem(
        id: 'ci-1',
        product: product,
        selectedVariant: variant,
        selectedModifiers: modifiers,
        quantity: 2,
        note: 'tanpa bawang',
      );

      // Base 25.000 + Variant 7.000 + Modifier 4.000 + Modifier 6.000 = 42.000
      expect(cartItem.unitPrice, 42000);
      // Total price = 42.000 * 2 = 84.000
      expect(cartItem.totalPrice, 84000);
      expect(cartItem.displayName, 'Nasi Goreng Spesial (Jumbo)');
    });

    test('Snapshot OrderItem menyimpan data harga dan nama secara permanen', () {
      const product = Product(
        id: 'prd-01',
        categoryId: 'cat-food',
        name: 'Ayam Geprek',
        description: '',
        basePrice: 20000,
      );

      final cartItem = CartItem(
        id: 'ci-2',
        product: product,
        quantity: 3,
      );

      final snapshot = OrderSnapshotItem.fromCartItem(cartItem);
      expect(snapshot.productName, 'Ayam Geprek');
      expect(snapshot.unitPrice, 20000);
      expect(snapshot.quantity, 3);
      expect(snapshot.totalPrice, 60000);
    });
  });

  group('Manajemen Shift & Rekonsiliasi Kas (FR-SHIFT)', () {
    test('Menghitung estimasi kas di laci dan selisih kas dengan benar', () {
      final shift = Shift(
        id: 'shift-1',
        outletId: 'out-1',
        userId: 'usr-1',
        userName: 'Andi Kasir',
        openingCash: 200000, // Modal awal Rp 200.000
        totalCashSales: 150000, // Penjualan tunai Rp 150.000
        totalNonCashSales: 80000, // QRIS (tidak masuk fisik laci)
        totalCashIn: 50000, // Kas masuk tambahan kembalian
        totalCashOut: 20000, // Kas keluar beli es batu
        openedAt: DateTime.now(),
      );

      // Expected Cash = 200.000 + 150.000 + 50.000 - 20.000 = 380.000
      expect(shift.expectedClosingCash, 380000);

      // Kasus kas aktual pas
      final shiftExact = shift.copyWith(closingCashActual: 380000);
      expect(shiftExact.cashDifference, 0);

      // Kasus kas aktual lebih Rp 5.000
      final shiftOver = shift.copyWith(closingCashActual: 385000);
      expect(shiftOver.cashDifference, 5000);

      // Kasus kas aktual kurang Rp 10.000
      final shiftShort = shift.copyWith(closingCashActual: 370000);
      expect(shiftShort.cashDifference, -10000);
    });
  });

  group('Format Mata Uang Rupiah (FR-IDR)', () {
    test('CurrencyFormatter memformat angka tanpa desimal', () {
      expect(CurrencyFormatter.format(25000), 'Rp 25.000');
      expect(CurrencyFormatter.format(1500000), 'Rp 1.500.000');
      expect(CurrencyFormatter.formatCompact(25000), 'Rp 25rb');
      expect(CurrencyFormatter.formatCompact(1500000), 'Rp 1.5jt');
    });
  });

  group('Pengelolaan Menu dan Produk Baru (FR-MENU)', () {
    test('ProductsNotifier dapat menambah, memperbarui, mengubah status, dan menghapus produk baru', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCount = container.read(allProductsProvider).length;

      const newProduct = Product(
        id: 'test-prd-1',
        categoryId: 'cat-food',
        name: 'Sop Buntut Sapi',
        description: 'Kuah kaldu gurih berempah',
        basePrice: 45000,
        variants: [
          ProductVariant(id: 'v-buntut-1', name: 'Goreng', priceDifference: 5000),
        ],
      );

      // 1. Tambah produk baru
      container.read(allProductsProvider.notifier).addProduct(newProduct);
      final productsAfterAdd = container.read(allProductsProvider);
      expect(productsAfterAdd.length, initialCount + 1);
      expect(productsAfterAdd.first.name, 'Sop Buntut Sapi');
      expect(productsAfterAdd.first.basePrice, 45000);

      // 2. Perbarui produk
      const updatedProduct = Product(
        id: 'test-prd-1',
        categoryId: 'cat-food',
        name: 'Sop Buntut Sapi Bakar Madu',
        description: 'Kuah kaldu gurih berempah',
        basePrice: 50000,
      );
      container.read(allProductsProvider.notifier).updateProduct(updatedProduct);
      final productsAfterUpdate = container.read(allProductsProvider);
      final found = productsAfterUpdate.firstWhere((p) => p.id == 'test-prd-1');
      expect(found.name, 'Sop Buntut Sapi Bakar Madu');
      expect(found.basePrice, 50000);

      // 3. Toggle status keaktifan (stok habis)
      container.read(allProductsProvider.notifier).toggleProductStatus('test-prd-1');
      final toggled = container.read(allProductsProvider).firstWhere((p) => p.id == 'test-prd-1');
      expect(toggled.isActive, false);

      // 4. Hapus produk
      container.read(allProductsProvider.notifier).deleteProduct('test-prd-1');
      final productsAfterDelete = container.read(allProductsProvider);
      expect(productsAfterDelete.length, initialCount);
      expect(productsAfterDelete.any((p) => p.id == 'test-prd-1'), false);
    });

    test('Menghapus menu menghapus produk dari filteredProductsProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final productToDelete = container.read(allProductsProvider).first;
      container.read(allProductsProvider.notifier).deleteProduct(productToDelete.id);

      final filteredProducts = container.read(filteredProductsProvider);
      expect(filteredProducts.any((p) => p.id == productToDelete.id), false);
    });
  });
}
