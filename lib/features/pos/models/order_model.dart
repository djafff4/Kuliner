import 'package:uuid/uuid.dart';
import 'cart_item_model.dart';

enum OrderType {
  dineIn,
  takeaway,
  delivery;

  String get displayName {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine-In (Meja)';
      case OrderType.takeaway:
        return 'Bungkus (Takeaway)';
      case OrderType.delivery:
        return 'Pesan Antar (Delivery)';
    }
  }

  String get shortName {
    switch (this) {
      case OrderType.dineIn:
        return 'DINE-IN';
      case OrderType.takeaway:
        return 'TAKEAWAY';
      case OrderType.delivery:
        return 'DELIVERY';
    }
  }
}

enum OrderStatus {
  active,
  held,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.active:
        return 'Aktif';
      case OrderStatus.held:
        return 'Tertahan (Hold)';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }
}

enum PaymentMethod {
  cash,
  qris,
  debit,
  split;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tunai (Cash)';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.debit:
        return 'Kartu Debit / EDC';
      case PaymentMethod.split:
        return 'Split Bill (Bagi Bayar)';
    }
  }
}

class OrderSnapshotItem {
  final String id;
  final String productId;
  final String productName;
  final String? variantName;
  final int unitPrice;
  final int quantity;
  final int totalPrice;
  final String note;
  final List<CartItemModifier> modifiers;

  const OrderSnapshotItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.variantName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.note = '',
    this.modifiers = const [],
  });

  factory OrderSnapshotItem.fromCartItem(CartItem item) {
    return OrderSnapshotItem(
      id: const Uuid().v4(),
      productId: item.product.id,
      productName: item.displayName,
      variantName: item.selectedVariant?.name,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
      totalPrice: item.totalPrice,
      note: item.note,
      modifiers: item.selectedModifiers,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'variant_name': variantName,
    'unit_price': unitPrice,
    'quantity': quantity,
    'total_price': totalPrice,
    'note': note,
    'modifiers': modifiers.map((m) => m.toJson()).toList(),
  };

  factory OrderSnapshotItem.fromJson(Map<String, dynamic> json) => OrderSnapshotItem(
    id: json['id'] as String,
    productId: json['product_id'] as String,
    productName: json['product_name'] as String,
    variantName: json['variant_name'] as String?,
    unitPrice: json['unit_price'] as int,
    quantity: json['quantity'] as int,
    totalPrice: json['total_price'] as int,
    note: json['note'] as String? ?? '',
    modifiers: (json['modifiers'] as List<dynamic>? ?? [])
        .map((m) => CartItemModifier.fromJson(m as Map<String, dynamic>))
        .toList(),
  );
}

class Order {
  final String id; // UUID v4 client generated
  final int queueNumber; // Daily auto-increment
  final String outletId;
  final String shiftId;
  final OrderType orderType;
  final String tableNumber; // for dine-in
  final String customerName; // for takeaway / delivery
  final String deliveryAddress; // for delivery
  final List<OrderSnapshotItem> items;
  final int subtotal;
  final int discountAmount;
  final String discountReason;
  final int taxAmount;
  final int serviceChargeAmount;
  final int total;
  final PaymentMethod paymentMethod;
  final int amountTendered; // uang diterima
  final int changeDue; // kembalian
  final String paymentReference; // nomor referensi kartu / QRIS
  final DateTime createdAt;
  final String cashierId;
  final String cashierName;
  final OrderStatus status;
  final String cancellationReason;

  const Order({
    required this.id,
    required this.queueNumber,
    required this.outletId,
    required this.shiftId,
    required this.orderType,
    this.tableNumber = '',
    this.customerName = '',
    this.deliveryAddress = '',
    required this.items,
    required this.subtotal,
    this.discountAmount = 0,
    this.discountReason = '',
    this.taxAmount = 0,
    this.serviceChargeAmount = 0,
    required this.total,
    required this.paymentMethod,
    this.amountTendered = 0,
    this.changeDue = 0,
    this.paymentReference = '',
    required this.createdAt,
    required this.cashierId,
    required this.cashierName,
    this.status = OrderStatus.completed,
    this.cancellationReason = '',
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get shortId => id.length >= 8 ? id.substring(0, 8).toUpperCase() : id;

  Order copyWith({
    String? id,
    int? queueNumber,
    String? outletId,
    String? shiftId,
    OrderType? orderType,
    String? tableNumber,
    String? customerName,
    String? deliveryAddress,
    List<OrderSnapshotItem>? items,
    int? subtotal,
    int? discountAmount,
    String? discountReason,
    int? taxAmount,
    int? serviceChargeAmount,
    int? total,
    PaymentMethod? paymentMethod,
    int? amountTendered,
    int? changeDue,
    String? paymentReference,
    DateTime? createdAt,
    String? cashierId,
    String? cashierName,
    OrderStatus? status,
    String? cancellationReason,
  }) {
    return Order(
      id: id ?? this.id,
      queueNumber: queueNumber ?? this.queueNumber,
      outletId: outletId ?? this.outletId,
      shiftId: shiftId ?? this.shiftId,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountReason: discountReason ?? this.discountReason,
      taxAmount: taxAmount ?? this.taxAmount,
      serviceChargeAmount: serviceChargeAmount ?? this.serviceChargeAmount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountTendered: amountTendered ?? this.amountTendered,
      changeDue: changeDue ?? this.changeDue,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
