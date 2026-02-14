/// Banner Model for Supabase
/// 
/// This model works with Supabase PostgreSQL database
/// instead of Firebase Firestore
library;

class SupabaseBannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String supplierId;
  final String category; // Medicines, Devices, Health, Vitamins
  final bool active;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final String? supplierName;

  SupabaseBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.supplierId,
    required this.category,
    required this.active,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.supplierName,
  });

  // Check if banner is currently valid
  bool get isValid {
    final now = DateTime.now();
    return active && 
           now.isAfter(startDate) && 
           now.isBefore(endDate);
  }

  // Factory constructor from Supabase JSON
  factory SupabaseBannerModel.fromJson(Map<String, dynamic> json) {
    return SupabaseBannerModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? '',
      supplierId: json['supplier_id'] ?? '',
      category: json['category'] ?? 'Medicines',
      active: json['active'] ?? false,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      createdAt: DateTime.parse(json['created_at']),
      supplierName: json['supplier_name'],
    );
  }

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'supplier_id': supplierId,
      'category': category,
      'active': active,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'supplier_name': supplierName,
    };
  }

  // Copy with method
  SupabaseBannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? supplierId,
    String? category,
    bool? active,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    String? supplierName,
  }) {
    return SupabaseBannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      supplierId: supplierId ?? this.supplierId,
      category: category ?? this.category,
      active: active ?? this.active,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      supplierName: supplierName ?? this.supplierName,
    );
  }
}
