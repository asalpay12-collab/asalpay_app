class Product {
  final int id;
  final String name;
  final String originalPrice;  // was unit_price
  final String unitPrice;  // was unit_price
  final String imagePath;

  final String discountType;
  final String remainingQuantity;
  final String sdate;
  final String edate;
  final double discountValue;
  final double currentPrice;

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
  });


  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.parse(json['product_id']),
      name: json['name'] ?? '',
      originalPrice: json['original_price'] ?? '0',
      imagePath: json['image_path'] ?? '',
      edate: json['end_date'] ?? '',
      sdate: json['start_date'] ?? '',
      unitPrice: json['unit_price'] ?? '0',
      remainingQuantity: json['remaining_quantity'] ?? '0',
      discountType: json['discount_type'] ?? '',
      discountValue: double.tryParse(json['discount_value'].toString()) ?? 0.0,
      currentPrice: double.tryParse(json['current_price'].toString()) ?? 0.0,
    );
  }
}
