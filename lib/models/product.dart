class Product {
  final int id;
  final String name;
  final String originalPrice; // was unit_price
  final String unitPrice; // was unit_price
  final String imagePath;

  final String discountType;
  final String remainingQuantity;
  final String sdate;
  final String edate;
  final double discountValue;
  final double currentPrice;

  /// Cost price from catalog; if 0 or null, negotiate is not available
  final double? costPrice;

  Product({
    required this.id,
    required this.name,
    required this.originalPrice,
    required this.unitPrice,
    required this.imagePath,
    required this.discountType,
    required this.remainingQuantity,
    required this.sdate,
    required this.edate,
    required this.discountValue,
    required this.currentPrice,
    this.costPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle remaining_quantity - can be int, double, or null
    String remainingQty = '0';
    if (json['remaining_quantity'] != null) {
      if (json['remaining_quantity'] is num) {
        remainingQty = json['remaining_quantity'].toString();
      } else {
        remainingQty = json['remaining_quantity'].toString();
      }
    }

    // Handle unit_price - can be int, double, or string
    String unitPriceStr = '0';
    if (json['unit_price'] != null) {
      if (json['unit_price'] is num) {
        unitPriceStr = json['unit_price'].toString();
      } else {
        unitPriceStr = json['unit_price'].toString();
      }
    }

    final costPriceVal = json['cost_price'];
    final double? costPriceParsed = costPriceVal == null
        ? null
        : (costPriceVal is num
            ? costPriceVal.toDouble()
            : double.tryParse(costPriceVal.toString()));

    return Product(
      id: int.tryParse(json['product_id'].toString()) ?? 0,
      name: json['name'] ?? '',
      originalPrice: json['original_price']?.toString() ?? unitPriceStr,
      imagePath: json['image_path'] ?? '',
      edate: json['end_date']?.toString() ?? '',
      sdate: json['start_date']?.toString() ?? '',
      unitPrice: unitPriceStr,
      remainingQuantity: remainingQty,
      discountType: json['discount_type']?.toString() ?? '',
      discountValue:
          double.tryParse(json['discount_value']?.toString() ?? '0') ?? 0.0,
      currentPrice:
          double.tryParse(json['current_price']?.toString() ?? unitPriceStr) ??
              double.tryParse(unitPriceStr) ??
              0.0,
      costPrice: costPriceParsed,
    );
  }
}
