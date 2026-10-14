class Shift {
  final String id;
  final String outletId;
  final String userId;
  final String userName;
  final int openingCash; // Kas Awal / Modal
  final int? closingCashActual; // Kas Akhir Aktual yang dihitung kasir
  final int totalCashSales; // Total penjualan tunai selama shift
  final int totalNonCashSales; // Total penjualan QRIS & EDC
  final int totalCashIn; // Kas masuk lain-lain
  final int totalCashOut; // Kas keluar operasional (es batu, dll)
  final DateTime openedAt;
  final DateTime? closedAt;
  final bool isOpen;

  const Shift({
    required this.id,
    required this.outletId,
    required this.userId,
    required this.userName,
    required this.openingCash,
    this.closingCashActual,
    this.totalCashSales = 0,
    this.totalNonCashSales = 0,
    this.totalCashIn = 0,
    this.totalCashOut = 0,
    required this.openedAt,
    this.closedAt,
    this.isOpen = true,
  });

  // Expected Cash = Opening Cash + Cash Sales + Cash In - Cash Out
  int get expectedClosingCash => openingCash + totalCashSales + totalCashIn - totalCashOut;

  // Discrepancy (Selisih) = Actual - Expected
  int get cashDifference => (closingCashActual ?? expectedClosingCash) - expectedClosingCash;

  Shift copyWith({
    String? id,
    String? outletId,
    String? userId,
    String? userName,
    int? openingCash,
    int? closingCashActual,
    int? totalCashSales,
    int? totalNonCashSales,
    int? totalCashIn,
    int? totalCashOut,
    DateTime? openedAt,
    DateTime? closedAt,
    bool? isOpen,
  }) {
    return Shift(
      id: id ?? this.id,
      outletId: outletId ?? this.outletId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      openingCash: openingCash ?? this.openingCash,
      closingCashActual: closingCashActual ?? this.closingCashActual,
      totalCashSales: totalCashSales ?? this.totalCashSales,
      totalNonCashSales: totalNonCashSales ?? this.totalNonCashSales,
      totalCashIn: totalCashIn ?? this.totalCashIn,
      totalCashOut: totalCashOut ?? this.totalCashOut,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
