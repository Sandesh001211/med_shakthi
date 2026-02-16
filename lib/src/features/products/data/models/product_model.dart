class Product {
  final String id; //  uuid string
  final String name;
  final String category;
  final double price;
  final double rating;
  final String image;

  // Supplier information
  final String? supplierName;
  final String? supplierCode;
  final String? supplierId;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.image,
    this.supplierName,
    this.supplierCode,
    this.supplierId,
  });

  // Supabase Map -> Product
  factory Product.fromMap(Map<String, dynamic> map) {
    // Handle nested supplier data from join
    final supplierData = map['suppliers'] as Map<String, dynamic>?;

    return Product(
      id: map['id'].toString(), //  UUID safe
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      image: map['image_url'] ?? '',
      supplierName: supplierData?['name'] as String?,
      supplierCode: supplierData?['supplier_code'] as String?,
      supplierId: supplierData?['id'] as String?,
    );
  }

  // Alias for fromMap to support standard JSON decoding
  factory Product.fromJson(Map<String, dynamic> json) => Product.fromMap(json);

  //  Product -> Map (Insert/Update)
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "category": category,
      "price": price,
      "rating": rating,
      "image_url": image,
      // Note: supplier fields are read-only from DB, not sent in inserts
    };
  }
}
