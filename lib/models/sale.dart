class SaleItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const SaleItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
    productName: j['product_name'] as String? ?? '',
    quantity:    int.tryParse(j['quantity'].toString()) ?? 0,
    unitPrice:   double.tryParse(j['unit_price'].toString()) ?? 0,
    subtotal:    double.tryParse(j['subtotal'].toString()) ?? 0,
  );
}

class Sale {
  final int id;
  final String? invoiceNumber;
  final String? productName;
  final int itemCount;
  final double subtotal;
  final double discountRate;
  final double discountAmount;
  final double ivaRate;
  final double ivaAmount;
  final double total;
  final String? customerName;
  final String? customerNif;
  final String? customerEmail;
  final int? customerId;
  final DateTime saleDate;
  final String paymentStatus;
  final List<SaleItem> items;

  const Sale({
    required this.id,
    this.invoiceNumber,
    this.productName,
    required this.itemCount,
    required this.subtotal,
    required this.discountRate,
    required this.discountAmount,
    required this.ivaRate,
    required this.ivaAmount,
    required this.total,
    this.customerName,
    this.customerNif,
    this.customerEmail,
    this.customerId,
    required this.saleDate,
    required this.paymentStatus,
    required this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
    id:             j['id'] as int,
    invoiceNumber:  j['invoice_number'] as String?,
    productName:    j['product_name'] as String?,
    itemCount:      int.tryParse(j['item_count']?.toString() ?? '1') ?? 1,
    subtotal:       double.tryParse(j['subtotal']?.toString() ?? '0') ?? 0,
    discountRate:   double.tryParse(j['discount_rate']?.toString() ?? '0') ?? 0,
    discountAmount: double.tryParse(j['discount_amount']?.toString() ?? '0') ?? 0,
    ivaRate:        double.tryParse(j['iva_rate']?.toString() ?? '21') ?? 21,
    ivaAmount:      double.tryParse(j['iva_amount']?.toString() ?? '0') ?? 0,
    total:          double.tryParse(j['total']?.toString() ?? '0') ?? 0,
    customerName:   j['customer_name'] as String?,
    customerNif:    j['customer_nif'] as String?,
    customerEmail:  j['customer_email'] as String?,
    customerId:     j['customer_id'] as int?,
    saleDate:       DateTime.tryParse(j['sale_date']?.toString() ?? '') ?? DateTime.now(),
    paymentStatus:  j['payment_status'] as String? ?? 'pendiente',
    items:          (j['items'] as List<dynamic>?)
                      ?.map((i) => SaleItem.fromJson(i as Map<String, dynamic>))
                      .toList() ?? [],
  );

  String get statusLabel {
    switch (paymentStatus) {
      case 'pagada':   return 'Pagada';
      case 'vencida':  return 'Vencida';
      default:         return 'Pendiente';
    }
  }

  String get nextStatus {
    switch (paymentStatus) {
      case 'pendiente': return 'pagada';
      case 'pagada':    return 'vencida';
      default:          return 'pendiente';
    }
  }
}
