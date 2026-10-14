import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../menu/models/menu_models.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class CartState {
  final List<CartItem> items;
  final OrderType orderType;
  final String tableNumber;
  final String customerName;
  final String deliveryAddress;
  final double discountPercent;
  final int discountNominal;
  final String discountReason;

  const CartState({
    this.items = const [],
    this.orderType = OrderType.dineIn,
    this.tableNumber = 'Meja 01',
    this.customerName = '',
    this.deliveryAddress = '',
    this.discountPercent = 0.0,
    this.discountNominal = 0,
    this.discountReason = '',
  });

  int get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int calculateDiscount(int currentSubtotal) {
    if (discountNominal > 0) {
      return discountNominal > currentSubtotal ? currentSubtotal : discountNominal;
    }
    if (discountPercent > 0) {
      return ((currentSubtotal * discountPercent) / 100).round();
    }
    return 0;
  }

  CartState copyWith({
    List<CartItem>? items,
    OrderType? orderType,
    String? tableNumber,
    String? customerName,
    String? deliveryAddress,
    double? discountPercent,
    int? discountNominal,
    String? discountReason,
  }) {
    return CartState(
      items: items ?? this.items,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      discountPercent: discountPercent ?? this.discountPercent,
      discountNominal: discountNominal ?? this.discountNominal,
      discountReason: discountReason ?? this.discountReason,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  void addItem({
    required Product product,
    ProductVariant? variant,
    List<CartItemModifier> modifiers = const [],
    int quantity = 1,
    String note = '',
  }) {
    // Check if identical item (same product, variant, modifiers, and note) already exists
    final existingIndex = state.items.indexWhere((item) {
      if (item.product.id != product.id) return false;
      if (item.selectedVariant?.id != variant?.id) return false;
      if (item.note != note) return false;
      if (item.selectedModifiers.length != modifiers.length) return false;
      for (int i = 0; i < modifiers.length; i++) {
        if (item.selectedModifiers[i].optionId != modifiers[i].optionId) return false;
      }
      return true;
    });

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updatedList = List<CartItem>.from(state.items);
      updatedList[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = CartItem(
        id: const Uuid().v4(),
        product: product,
        selectedVariant: variant,
        selectedModifiers: modifiers,
        quantity: quantity,
        note: note,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(cartItemId);
      return;
    }
    final updated = state.items.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void removeItem(String cartItemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != cartItemId).toList(),
    );
  }

  void updateItemNote(String cartItemId, String note) {
    final updated = state.items.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(note: note);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void setOrderType(OrderType type) {
    state = state.copyWith(orderType: type);
  }

  void setTableNumber(String table) {
    state = state.copyWith(tableNumber: table);
  }

  void setCustomerName(String name) {
    state = state.copyWith(customerName: name);
  }

  void setDeliveryAddress(String address) {
    state = state.copyWith(deliveryAddress: address);
  }

  void applyDiscount({double percent = 0, int nominal = 0, String reason = ''}) {
    state = state.copyWith(
      discountPercent: percent,
      discountNominal: nominal,
      discountReason: reason,
    );
  }

  void removeDiscount() {
    state = state.copyWith(
      discountPercent: 0,
      discountNominal: 0,
      discountReason: '',
    );
  }

  void clearCart() {
    state = CartState(
      orderType: state.orderType,
      tableNumber: state.tableNumber,
    );
  }

  void restoreFromOrder(Order order) {
    final cartItems = order.items.map((item) {
      return CartItem(
        id: const Uuid().v4(),
        product: Product(
          id: item.productId,
          categoryId: '',
          name: item.productName,
          description: '',
          basePrice: item.unitPrice,
        ),
        selectedModifiers: item.modifiers,
        quantity: item.quantity,
        note: item.note,
      );
    }).toList();

    state = CartState(
      items: cartItems,
      orderType: order.orderType,
      tableNumber: order.tableNumber,
      customerName: order.customerName,
      deliveryAddress: order.deliveryAddress,
      discountNominal: order.discountAmount,
      discountReason: order.discountReason,
    );
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

class CartSummary {
  final int subtotal;
  final int discount;
  final int taxableAmount;
  final int tax;
  final int serviceCharge;
  final int grandTotal;

  const CartSummary({
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.tax,
    required this.serviceCharge,
    required this.grandTotal,
  });
}

final cartSummaryProvider = Provider<CartSummary>((ref) {
  final cart = ref.watch(cartProvider);
  final settings = ref.watch(settingsProvider);

  final subtotal = cart.subtotal;
  final discount = cart.calculateDiscount(subtotal);
  final afterDiscount = (subtotal - discount).clamp(0, double.infinity).toInt();

  int serviceCharge = 0;
  if (settings.enableServiceCharge && settings.serviceChargePercent > 0) {
    serviceCharge = ((afterDiscount * settings.serviceChargePercent) / 100).round();
  }

  int tax = 0;
  if (settings.enableTax && settings.taxPercent > 0) {
    tax = (((afterDiscount + serviceCharge) * settings.taxPercent) / 100).round();
  }

  final grandTotal = afterDiscount + serviceCharge + tax;

  return CartSummary(
    subtotal: subtotal,
    discount: discount,
    taxableAmount: afterDiscount,
    tax: tax,
    serviceCharge: serviceCharge,
    grandTotal: grandTotal,
  );
});
