class Category {
  final int subCategoryId;       // subcategory ID
  final int categoryId;          // main category ID
  final String subCategoryName;  // subcategory name
  final String categoryName;    // main category name
  final String productImage;    // main category image
  final String imagePath;        // image URL or path

  Category({
    required this.subCategoryId,
    required this.categoryId,
    required this.subCategoryName,
    required this.categoryName,
    required this.imagePath,
    required this.productImage
  });

  // Helper method to safely parse integers
  static int parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      subCategoryId: parseIntSafe(json['cat_id']),
      categoryId: parseIntSafe(json['category_id']),
      subCategoryName: json['sub_category_name'] ?? '',
      categoryName: json['category_name'] ?? '',
      imagePath: json['image'] ?? '',
        productImage:json['product_image']?? ''
    );
  }
}
