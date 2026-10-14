import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shift/providers/shift_provider.dart';
import '../../sync/providers/sync_provider.dart';
import '../models/order_model.dart';
import 'cart_provider.dart';

class OrdersState {
  final List<Order> completedOrders;
  final List<Order> heldOrders;
  final int dailyQueueCounter;

  const OrdersState({
    this.completedOrders = const [],
    this.heldOrders = const [],
    this.dailyQueueCounter = 100, // Starts at #101 for today
  });

  OrdersState copyWith({
    List<Order>? completedOrders,
    List<Order>? heldOrders,
    int? dailyQueueCounter,
  }) {
    return OrdersState(
      completedOrders: completedOrders ?? this.completedOrders,
      heldOrders: heldOrders ?? this.heldOrders,
      dailyQueueCounter: dailyQueueCounter ?? this.dailyQueueCounter,
    );
  }
}

class OrdersNotifier extends Notifier<OrdersState> {
  @override
  OrdersState build() {
    // Generate 2 sample completed transactions for demo & instant reporting
    final now = DateTime.now();
    final sampleOrder1 = Order(
      id: const Uuid().v4(),
      queueNumber: 101,
      outletId: 'out-01',
      shiftId: 'shift-demo',
      orderType: OrderType.dineIn,
      tableNumber: 'Meja 04',
      items: [
        OrderSnapshotItem(
          id: const Uuid().v4(),
          productId: 'prd-001',
          productName: 'Nasi Goreng Spesial Warung',
          variantName: 'Porsi Jumbo',
          unitPrice: 32000,
          quantity: 2,
          totalPrice: 64000,
          modifiers: const [],
        ),
        OrderSnapshotItem(
          id: const Uuid().v4(),
          productId: 'prd-006',
          productName: 'Es Teh Manis Jumbo',
          unitPrice: 6000,
          quantity: 2,
          totalPrice: 12000,
          modifiers: const [],
        ),
      ],
      subtotal: 76000,
      total: 76000,
      paymentMethod: PaymentMethod.cash,
      amountTendered: 100000,
      changeDue: 24000,
      createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      cashierId: 'usr-003',
      cashierName: 'Andi Pratama',
      status: OrderStatus.completed,
    );

    final sampleOrder2 = Order(
      id: const Uuid().v4(),
      queueNumber: 102,
      outletId: 'out-01',
      shiftId: 'shift-demo',
      orderType: OrderType.takeaway,
      customerName: 'Kak Doni',
      items: [
        OrderSnapshotItem(
          id: const Uuid().v4(),
          productId: 'prd-002',
          productName: 'Ayam Geprek Sambal Matah',
          unitPrice: 24000,
          quantity: 1,
          totalPrice: 24000,
          modifiers: const [],
        ),
        OrderSnapshotItem(
          id: const Uuid().v4(),
          productId: 'prd-007',
          productName: 'Kopi Susu Gula Aren Asli',
          unitPrice: 18000,
          quantity: 1,
          totalPrice: 18000,
          modifiers: const [],
        ),
      ],
      subtotal: 42000,
      total: 42000,
      paymentMethod: PaymentMethod.qris,
      amountTendered: 42000,
      changeDue: 0,
      paymentReference: 'QRIS-NMD8928374',
      createdAt: now.subtract(const Duration(minutes: 45)),
      cashierId: 'usr-003',
      cashierName: 'Andi Pratama',
      status: OrderStatus.completed,
    );

    return OrdersState(
      completedOrders: [sampleOrder2, sampleOrder1],
      heldOrders: [],
      dailyQueueCounter: 102,
    );
  }

  Order completeTransaction({
    required PaymentMethod paymentMethod,
    required int amountTendered,
    required int changeDue,
    String paymentReference = '',
  }) {
    final cart = ref.read(cartProvider);
    final summary = ref.read(cartSummaryProvider);
    final currentUser = ref.read(currentUserProvider);
    final shiftState = ref.read(shiftProvider);

    final nextQueue = state.dailyQueueCounter + 1;
    final orderId = const Uuid().v4();

    final orderItems = cart.items.map((ci) => OrderSnapshotItem.fromCartItem(ci)).toList();

    final newOrder = Order(
      id: orderId,
      queueNumber: nextQueue,
      outletId: currentUser.outletId,
      shiftId: shiftState.activeShift?.id ?? 'no-shift',
      orderType: cart.orderType,
      tableNumber: cart.tableNumber,
      customerName: cart.customerName,
      deliveryAddress: cart.deliveryAddress,
      items: orderItems,
      subtotal: summary.subtotal,
      discountAmount: summary.discount,
      discountReason: cart.discountReason,
      taxAmount: summary.tax,
      serviceChargeAmount: summary.serviceCharge,
      total: summary.grandTotal,
      paymentMethod: paymentMethod,
      amountTendered: amountTendered,
      changeDue: changeDue,
      paymentReference: paymentReference,
      createdAt: DateTime.now(),
      cashierId: currentUser.id,
      cashierName: currentUser.name,
      status: OrderStatus.completed,
    );

    // 1. Add order to completed orders
    state = state.copyWith(
      completedOrders: [newOrder, ...state.completedOrders],
      dailyQueueCounter: nextQueue,
    );

    // 2. Record sale into active shift
    final isCash = paymentMethod == PaymentMethod.cash;
    ref.read(shiftProvider.notifier).recordSale(
      cashAmount: isCash ? summary.grandTotal : 0,
      nonCashAmount: !isCash ? summary.grandTotal : 0,
    );

    // 3. Add to Outbox for offline-first sync
    ref.read(syncProvider.notifier).addToOutbox(
      entityType: 'order',
      entityId: orderId,
      payload: {
        'order_id': orderId,
        'queue_number': nextQueue,
        'total': summary.grandTotal,
        'payment_method': paymentMethod.name,
      },
    );

    // 4. Clear cart
    ref.read(cartProvider.notifier).clearCart();

    return newOrder;
  }

  Order? holdCurrentCart() {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) return null;

    final summary = ref.read(cartSummaryProvider);
    final currentUser = ref.read(currentUserProvider);
    final shiftState = ref.read(shiftProvider);

    final nextQueue = state.dailyQueueCounter + 1;
    final orderId = const Uuid().v4();
    final orderItems = cart.items.map((ci) => OrderSnapshotItem.fromCartItem(ci)).toList();

    final heldOrder = Order(
      id: orderId,
      queueNumber: nextQueue,
      outletId: currentUser.outletId,
      shiftId: shiftState.activeShift?.id ?? 'no-shift',
      orderType: cart.orderType,
      tableNumber: cart.tableNumber,
      customerName: cart.customerName,
      deliveryAddress: cart.deliveryAddress,
      items: orderItems,
      subtotal: summary.subtotal,
      discountAmount: summary.discount,
      discountReason: cart.discountReason,
      taxAmount: summary.tax,
      serviceChargeAmount: summary.serviceCharge,
      total: summary.grandTotal,
      paymentMethod: PaymentMethod.cash,
      createdAt: DateTime.now(),
      cashierId: currentUser.id,
      cashierName: currentUser.name,
      status: OrderStatus.held,
    );

    state = state.copyWith(
      heldOrders: [heldOrder, ...state.heldOrders],
      dailyQueueCounter: nextQueue,
    );

    ref.read(cartProvider.notifier).clearCart();
    return heldOrder;
  }

  void resumeHeldOrder(String orderId) {
    final heldOrder = state.heldOrders.where((o) => o.id == orderId).firstOrNull;
    if (heldOrder == null) return;

    ref.read(cartProvider.notifier).restoreFromOrder(heldOrder);
    state = state.copyWith(
      heldOrders: state.heldOrders.where((o) => o.id != orderId).toList(),
    );
  }

  void cancelHeldOrder(String orderId) {
    state = state.copyWith(
      heldOrders: state.heldOrders.where((o) => o.id != orderId).toList(),
    );
  }

  bool cancelCompletedOrder(String orderId, String reason) {
    final index = state.completedOrders.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;

    final target = state.completedOrders[index];
    final updated = target.copyWith(
      status: OrderStatus.cancelled,
      cancellationReason: reason,
    );

    final list = List<Order>.from(state.completedOrders);
    list[index] = updated;

    state = state.copyWith(completedOrders: list);

    // Reverse cash sale if it was cash
    if (target.paymentMethod == PaymentMethod.cash) {
      ref.read(shiftProvider.notifier).recordSale(
        cashAmount: -target.total,
        nonCashAmount: 0,
      );
    } else {
      ref.read(shiftProvider.notifier).recordSale(
        cashAmount: 0,
        nonCashAmount: -target.total,
      );
    }

    return true;
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);
