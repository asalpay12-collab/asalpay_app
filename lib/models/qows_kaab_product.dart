/// QOWS KAAB Product Model
class QowsKaabProduct {
  final int? id;
  final String? name;
  final String? description;
  final double? price;
  final String? imageUrl;
  final int? stock;
  final Map<String, dynamic>? metadata;
  final String? imagePath;
  final int? productId;
  final String? categoryName;
  final String? unitName;
  final String? unitSymbol;

  QowsKaabProduct({
    this.id,
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.stock,
    this.metadata,
    this.imagePath,
    this.productId,
    this.categoryName,
    this.unitName,
    this.unitSymbol,
  });

  factory QowsKaabProduct.fromJson(Map<String, dynamic> json) {
    return QowsKaabProduct(
      id: (json['product_id'] ?? json['id']) != null
          ? int.tryParse((json['product_id'] ?? json['id']).toString())
          : null,
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: (json['unit_price'] ?? json['price']) != null
          ? double.tryParse((json['unit_price'] ?? json['price']).toString())
          : null,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      stock: int.tryParse(json['stock'].toString()),
      metadata: json['metadata'] is Map 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
      imagePath: json['image_path'] as String? ?? json['imagePath'] as String?,
      productId: int.tryParse(json['product_id'].toString()) ?? 
                 int.tryParse(json['id'].toString()),
      categoryName:
          json['category_name'] as String? ?? json['categoryName'] as String?,
      unitName: json['unit_name'] as String? ?? json['unitName'] as String?,
      unitSymbol: json['unit_symbol'] as String? ?? json['unitSymbol'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'stock': stock,
      'metadata': metadata,
      'image_path': imagePath,
      'product_id': productId ?? id,
      'category_name': categoryName,
      'unit_name': unitName,
      'unit_symbol': unitSymbol,
    };
  }
}
