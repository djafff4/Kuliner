import '../../menu/models/menu_models.dart';

class CartItemModifier {
  final String optionId;
  final String nameSnapshot;
  final int priceSnapshot;

  const CartItemModifier({
    required this.optionId,
    required this.nameSnapshot,
    required this.priceSnapshot,
  });

  Map<String, dynamic> toJson() => {
    'option_id': optionId,
    'name_snapshot': nameSnapshot,
    'price_snapshot': priceSnapshot,
  };

  factory CartItemModifier.fromJson(Map<String, dynamic> json) => CartItemModifier(
    optionId: json['option_id'] as String,
    nameSnapshot: json['name_snapshot'] as String,
    priceSnapshot: json['price_snapshot'] as int,
  );
}

class CartItem {
  final String id; // unique cart item id
  final Product product;
  final ProductVariant? selectedVariant;
  final List<CartItemModifier> selectedModifiers;
  final int quantity;
  final String note;

  const CartItem({
    required this.id,
    required this.product,
    this.selectedVariant,
    this.selectedModifiers = const [],
    this.quantity = 1,
    this.note = '',
  });

  // Snapshot unit price: base + variant + all modifiers
  int get unitPrice {
    int price = product.basePrice;
    if (selectedVariant != null) {
      price += selectedVariant!.priceDifference;
    }
    for (final mod in selectedModifiers) {
      price += mod.priceSnapshot;
    }
    return price;
  }

  int get totalPrice => unitPrice * quantity;

  String get displayName {
    if (selectedVariant != null) {
      return '${product.name} (${selectedVariant!.name})';
    }
    return product.name;
  }

  CartItem copyWith({
    String? id,
    Product? product,
    ProductVariant? selectedVariant,
    List<CartItemModifier>? selectedModifiers,
    int? quantity,
    String? note,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }
}
