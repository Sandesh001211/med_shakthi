class PaymentMethodModel {
  final String id;
  final String name; // e.g., "UPI", "Bank Transfer", "Credit Card"
  final String type; // e.g., "upi", "bank_transfer", "card"
  final Map<String, dynamic>
  details; // Dynamic fields like upi_id, bank_account_no, etc.
  final bool isActive;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.type,
    required this.details,
    this.isActive = true,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      details: json['details'] as Map<String, dynamic>,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'details': details,
      'is_active': isActive,
    };
  }
}
