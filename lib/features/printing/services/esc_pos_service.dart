import 'package:pos_kuliner/core/utils/currency_formatter.dart';
import 'package:pos_kuliner/core/utils/date_formatter.dart';
import 'package:pos_kuliner/features/pos/models/order_model.dart';
import 'package:pos_kuliner/features/settings/models/store_settings_model.dart';

class BluetoothPrinterDevice {
  final String name;
  final String address;
  final bool isConnected;
  final int paperWidthMm;

  const BluetoothPrinterDevice({
    required this.name,
    required this.address,
    this.isConnected = false,
    this.paperWidthMm = 58,
  });
}

class EscPosService {
  static const int width58mm = 32; // Characters per line for 58mm thermal printer
  static const int width80mm = 42; // Characters per line for 80mm thermal printer

  /// Formats a complete text receipt simulating ESC/POS thermal output
  static String generateReceiptText({
    required Order order,
    required StoreSettings settings,
  }) {
    final maxChars = settings.paperWidthMm == 80 ? width80mm : width58mm;
    final buffer = StringBuffer();

    // Store Header
    buffer.writeln(_center(settings.storeName.toUpperCase(), maxChars));
    buffer.writeln(_center(settings.outletName, maxChars));
    buffer.writeln(_center(settings.address, maxChars));
    buffer.writeln(_center('Telp: ${settings.phone}', maxChars));
    if (settings.npwp.isNotEmpty) {
      buffer.writeln(_center('NPWP: ${settings.npwp}', maxChars));
    }
    buffer.writeln(_divider('=', maxChars));

    // Order Meta Info
    buffer.writeln(_row('No. Antrean:', '#${order.queueNumber}', maxChars));
    buffer.writeln(_row('No. Nota:', order.shortId, maxChars));
    buffer.writeln(_row('Waktu:', DateFormatter.formatDateTime(order.createdAt), maxChars));
    buffer.writeln(_row('Kasir:', order.cashierName, maxChars));
    buffer.writeln(_row('Tipe Pesanan:', order.orderType.shortName, maxChars));
    if (order.tableNumber.isNotEmpty) {
      buffer.writeln(_row('Meja:', order.tableNumber, maxChars));
    }
    if (order.customerName.isNotEmpty) {
      buffer.writeln(_row('Pelanggan:', order.customerName, maxChars));
    }
    buffer.writeln(_divider('-', maxChars));

    // Items List
    for (final item in order.items) {
      buffer.writeln(item.productName);
      final qtyPrice = '${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}';
      final totalStr = CurrencyFormatter.format(item.totalPrice);
      buffer.writeln(_row('  $qtyPrice', totalStr, maxChars));

      // Modifiers
      for (final mod in item.modifiers) {
        final modPrice = mod.priceSnapshot > 0 ? ' (+${CurrencyFormatter.format(mod.priceSnapshot)})' : '';
        buffer.writeln('   + ${mod.nameSnapshot}$modPrice');
      }

      // Notes
      if (item.note.isNotEmpty) {
        buffer.writeln('   * Catatan: "${item.note}"');
      }
    }

    buffer.writeln(_divider('-', maxChars));

    // Calculations
    buffer.writeln(_row('Subtotal:', CurrencyFormatter.format(order.subtotal), maxChars));
    if (order.discountAmount > 0) {
      final desc = order.discountReason.isNotEmpty ? ' (${order.discountReason})' : '';
      buffer.writeln(_row('Diskon$desc:', '-${CurrencyFormatter.format(order.discountAmount)}', maxChars));
    }
    if (order.serviceChargeAmount > 0) {
      buffer.writeln(_row('Service Charge (${settings.serviceChargePercent}%):', CurrencyFormatter.format(order.serviceChargeAmount), maxChars));
    }
    if (order.taxAmount > 0) {
      buffer.writeln(_row('PB1 / Pajak (${settings.taxPercent}%):', CurrencyFormatter.format(order.taxAmount), maxChars));
    }

    buffer.writeln(_divider('=', maxChars));
    buffer.writeln(_row('TOTAL:', CurrencyFormatter.format(order.total), maxChars));
    buffer.writeln(_row('Metode:', order.paymentMethod.displayName, maxChars));

    if (order.paymentMethod == PaymentMethod.cash) {
      buffer.writeln(_row('Tunai Diterima:', CurrencyFormatter.format(order.amountTendered), maxChars));
      buffer.writeln(_row('Kembalian:', CurrencyFormatter.format(order.changeDue), maxChars));
    } else if (order.paymentReference.isNotEmpty) {
      buffer.writeln(_row('Ref/Approval:', order.paymentReference, maxChars));
    }

    buffer.writeln(_divider('-', maxChars));

    // Footer
    final footerLines = settings.receiptFooter.split('\n');
    for (final line in footerLines) {
      buffer.writeln(_center(line, maxChars));
    }
    buffer.writeln(_center('[ LUNAS - TRANSAKSI SAH ]', maxChars));
    buffer.writeln('\n\n');

    return buffer.toString();
  }

  /// Formats Kitchen Ticket (Order untuk Koki / Dapur)
  static String generateKitchenTicketText({
    required Order order,
    required StoreSettings settings,
  }) {
    final maxChars = settings.paperWidthMm == 80 ? width80mm : width58mm;
    final buffer = StringBuffer();

    buffer.writeln(_center('*** TIKET DAPUR / KITCHEN ***', maxChars));
    buffer.writeln(_divider('=', maxChars));
    buffer.writeln(_row('ANTREAN:', '#${order.queueNumber}', maxChars));
    buffer.writeln(_row('TIPE:', order.orderType.shortName, maxChars));
    if (order.tableNumber.isNotEmpty) {
      buffer.writeln(_row('MEJA:', order.tableNumber, maxChars));
    }
    if (order.customerName.isNotEmpty) {
      buffer.writeln(_row('PEMESAN:', order.customerName, maxChars));
    }
    buffer.writeln(_row('WAKTU:', DateFormatter.formatTime(order.createdAt), maxChars));
    buffer.writeln(_divider('=', maxChars));

    for (final item in order.items) {
      buffer.writeln('[ ${item.quantity}x ] ${item.productName}');
      for (final mod in item.modifiers) {
        buffer.writeln('    >> ${mod.nameSnapshot}');
      }
      if (item.note.isNotEmpty) {
        buffer.writeln('    ** PESAN: ${item.note.toUpperCase()} **');
      }
      buffer.writeln('');
    }

    buffer.writeln(_divider('-', maxChars));
    buffer.writeln(_center('-- SEGERA DISIAPKAN --', maxChars));
    buffer.writeln('\n\n');

    return buffer.toString();
  }

  static String _center(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final pad = (width - text.length) ~/ 2;
    return ' ' * pad + text;
  }

  static String _divider(String char, int width) {
    return char * width;
  }

  static String _row(String left, String right, int width) {
    final available = width - left.length - right.length;
    if (available > 0) {
      return '$left${' ' * available}$right';
    }
    return '$left $right';
  }
}
