class OrderDetailModel {
  final String id;
  final String orderId;
  final String? productId; // Nullable as per legacy data or if product deleted
  final String itemName;
  final String brand;
  final String unitSize;
  final String imageUrl;
  final double price;
  final int qty;
  final DateTime createdAt;

  OrderDetailModel({
    required this.id,
    required this.orderId,
    this.productId,
    required this.itemName,
    required this.brand,
    required this.unitSize,
    required this.imageUrl,
    required this.price,
    required this.qty,
    required this.createdAt,
  });

  factory OrderDetailModel.fromMap(Map<String, dynamic> map) {
    return OrderDetailModel(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      productId: map['product_id']?.toString(),
      itemName: map['item_name'] ?? '',
      brand: map['brand'] ?? '',
      unitSize: map['unit_size'] ?? '',
      imageUrl: map['image_url'] ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      qty: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
