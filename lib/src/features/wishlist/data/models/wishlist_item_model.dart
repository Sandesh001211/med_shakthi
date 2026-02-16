class WishlistItem {
  final String id;
  final String name;
  final double price;
  final String image;

  final String? supplierName;
  final String? supplierCode;
  final String? supplierId;

  WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.supplierName,
    this.supplierCode,
    this.supplierId,
  });

  // Convert from Map (Database)
  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    // Handle join with products -> suppliers
    final product = map['products'] as Map<String, dynamic>?;
    final supplier = product?['suppliers'] as Map<String, dynamic>?;

    return WishlistItem(
      id: map['product_id'] ?? map['id'] ?? '',
      // Prioritize product join, fallback to wishlist snapshot
      name: product?['name'] ?? map['name'] ?? 'Unknown Product',
      price:
          (product?['price'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          0.0,
      image: product?['image_url'] ?? map['image'] ?? '',
      // Supplier info comes only from join
      supplierName: supplier?['name'],
      supplierCode: supplier?['supplier_code'],
      supplierId: supplier?['id'],
    );
  }

  // Convert to Map (Database)
  Map<String, dynamic> toMap(String userId) {
    return {
      'user_id': userId,
      'product_id': id,
      'name': name,
      'price': price,
      'image': image,
    };
  }
}
