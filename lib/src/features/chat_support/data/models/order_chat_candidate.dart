/// Represents an order that MAY or MAY NOT be eligible for chat
/// This is a computed domain model, not a direct DB table mapping
class OrderChatCandidate {
  // ----- Order identity -----
  final String orderId;
  final String orderGroupId;
  final DateTime createdAt;

  // ----- Supplier resolution -----
  final String? supplierId;
  final String? supplierCode;

  // ----- Chat eligibility -----
  final bool canChat;
  final String? disableReason;

  OrderChatCandidate({
    required this.orderId,
    required this.orderGroupId,
    required this.createdAt,
    required this.supplierId,
    required this.supplierCode,
    required this.canChat,
    this.disableReason,
  });
}
