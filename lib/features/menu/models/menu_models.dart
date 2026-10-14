class Category {
  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
  });
}

class ProductVariant {
  final String id;
  final String name;
  final int priceDifference; // Selisih harga

  const ProductVariant({
    required this.id,
    required this.name,
    this.priceDifference = 0,
  });
}

class ModifierOption {
  final String id;
  final String name;
  final int additionalPrice; // Harga tambahan

  const ModifierOption({
    required this.id,
    required this.name,
    this.additionalPrice = 0,
  });
}

class ModifierGroup {
  final String id;
  final String name;
  final bool isRequired;
  final int minSelect;
  final int maxSelect;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.minSelect = 0,
    this.maxSelect = 1,
    required this.options,
  });
}

class Product {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int basePrice;
  final String? imageUrl;
  final bool isActive;
  final List<ProductVariant> variants;
  final List<ModifierGroup> modifierGroups;

  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    this.imageUrl,
    this.isActive = true,
    this.variants = const [],
    this.modifierGroups = const [],
  });

  bool get hasOptions => variants.isNotEmpty || modifierGroups.isNotEmpty;
}
