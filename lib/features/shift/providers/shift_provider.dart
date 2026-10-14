import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/cash_movement_model.dart';
import '../models/shift_model.dart';

class ShiftState {
  final Shift? activeShift;
  final List<CashMovement> movements;
  final List<Shift> pastShifts;

  const ShiftState({
    this.activeShift,
    this.movements = const [],
    this.pastShifts = const [],
  });

  bool get isShiftOpen => activeShift != null && activeShift!.isOpen;

  ShiftState copyWith({
    Shift? activeShift,
    bool clearActiveShift = false,
    List<CashMovement>? movements,
    List<Shift>? pastShifts,
  }) {
    return ShiftState(
      activeShift: clearActiveShift ? null : (activeShift ?? this.activeShift),
      movements: movements ?? this.movements,
      pastShifts: pastShifts ?? this.pastShifts,
    );
  }
}

class ShiftNotifier extends Notifier<ShiftState> {
  @override
  ShiftState build() {
    final currentUser = ref.watch(currentUserProvider);
    // Auto initialize an active shift for smooth demo experience
    final initialShift = Shift(
      id: 'shift-${DateTime.now().millisecondsSinceEpoch}',
      outletId: currentUser.outletId,
      userId: currentUser.id,
      userName: currentUser.name,
      openingCash: 200000, // Rp 200.000 modal awal
      openedAt: DateTime.now().subtract(const Duration(hours: 3)),
      isOpen: true,
    );

    return ShiftState(
      activeShift: initialShift,
      movements: [
        CashMovement(
          id: const Uuid().v4(),
          shiftId: initialShift.id,
          type: CashMovementType.cashOut,
          amount: 25000,
          note: 'Beli es batu kristal 2 karung',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          createdByName: currentUser.name,
        ),
      ],
      pastShifts: [],
    );
  }

  void openShift({required int openingCash}) {
    final currentUser = ref.read(currentUserProvider);
    final newShift = Shift(
      id: const Uuid().v4(),
      outletId: currentUser.outletId,
      userId: currentUser.id,
      userName: currentUser.name,
      openingCash: openingCash,
      openedAt: DateTime.now(),
      isOpen: true,
    );

    state = state.copyWith(
      activeShift: newShift,
      movements: [],
    );
  }

  void recordSale({required int cashAmount, required int nonCashAmount}) {
    if (state.activeShift == null) return;
    final current = state.activeShift!;
    state = state.copyWith(
      activeShift: current.copyWith(
        totalCashSales: current.totalCashSales + cashAmount,
        totalNonCashSales: current.totalNonCashSales + nonCashAmount,
      ),
    );
  }

  void recordCashMovement({
    required CashMovementType type,
    required int amount,
    required String note,
  }) {
    if (state.activeShift == null) return;
    final currentUser = ref.read(currentUserProvider);
    final movement = CashMovement(
      id: const Uuid().v4(),
      shiftId: state.activeShift!.id,
      type: type,
      amount: amount,
      note: note,
      timestamp: DateTime.now(),
      createdByName: currentUser.name,
    );

    final currentShift = state.activeShift!;
    final updatedShift = type == CashMovementType.cashIn
        ? currentShift.copyWith(totalCashIn: currentShift.totalCashIn + amount)
        : currentShift.copyWith(totalCashOut: currentShift.totalCashOut + amount);

    state = state.copyWith(
      activeShift: updatedShift,
      movements: [movement, ...state.movements],
    );
  }

  Shift? closeShift({required int actualCash}) {
    if (state.activeShift == null) return null;
    final closed = state.activeShift!.copyWith(
      closingCashActual: actualCash,
      closedAt: DateTime.now(),
      isOpen: false,
    );

    state = state.copyWith(
      clearActiveShift: true,
      pastShifts: [closed, ...state.pastShifts],
    );
    return closed;
  }
}

final shiftProvider = NotifierProvider<ShiftNotifier, ShiftState>(ShiftNotifier.new);
