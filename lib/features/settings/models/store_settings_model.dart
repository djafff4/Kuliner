class StoreSettings {
  final String storeName;
  final String outletName;
  final String address;
  final String phone;
  final String npwp;
  final double taxPercent;
  final double serviceChargePercent;
  final bool enableTax;
  final bool enableServiceCharge;
  final String receiptFooter;
  final int paperWidthMm; // 58 or 80
  final bool autoPrintReceipt;
  final bool autoPrintKitchenTicket;
  final bool isDarkMode;

  const StoreSettings({
    this.storeName = 'Warung Kuliner Sedap',
    this.outletName = 'Outlet Kemang Raya',
    this.address = 'Jl. Kemang Raya No. 45, Jakarta Selatan',
    this.phone = '0812-3456-7890',
    this.npwp = '01.234.567.8-901.000',
    this.taxPercent = 10.0,
    this.serviceChargePercent = 5.0,
    this.enableTax = false,
    this.enableServiceCharge = false,
    this.receiptFooter = 'Terima kasih atas kunjungan Anda!\nSelamat Menikmati Hidangan!',
    this.paperWidthMm = 58,
    this.autoPrintReceipt = true,
    this.autoPrintKitchenTicket = true,
    this.isDarkMode = false,
  });

  StoreSettings copyWith({
    String? storeName,
    String? outletName,
    String? address,
    String? phone,
    String? npwp,
    double? taxPercent,
    double? serviceChargePercent,
    bool? enableTax,
    bool? enableServiceCharge,
    String? receiptFooter,
    int? paperWidthMm,
    bool? autoPrintReceipt,
    bool? autoPrintKitchenTicket,
    bool? isDarkMode,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      outletName: outletName ?? this.outletName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      npwp: npwp ?? this.npwp,
      taxPercent: taxPercent ?? this.taxPercent,
      serviceChargePercent: serviceChargePercent ?? this.serviceChargePercent,
      enableTax: enableTax ?? this.enableTax,
      enableServiceCharge: enableServiceCharge ?? this.enableServiceCharge,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      autoPrintKitchenTicket: autoPrintKitchenTicket ?? this.autoPrintKitchenTicket,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
