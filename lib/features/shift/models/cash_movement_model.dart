enum CashMovementType {
  cashIn,
  cashOut;

  String get displayName {
    switch (this) {
      case CashMovementType.cashIn:
        return 'Kas Masuk';
      case CashMovementType.cashOut:
        return 'Kas Keluar';
    }
  }
}

class CashMovement {
  final String id;
  final String shiftId;
  final CashMovementType type;
  final int amount;
  final String note;
  final DateTime timestamp;
  final String createdByName;

  const CashMovement({
    required this.id,
    required this.shiftId,
    required this.type,
    required this.amount,
    required this.note,
    required this.timestamp,
    required this.createdByName,
  });
}
