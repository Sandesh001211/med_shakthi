import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
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

  BannerModel({
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

  // Factory constructor from Firestore
  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      supplierId: data['supplierId'] ?? '',
      category: data['category'] ?? 'Medicines',
      active: data['active'] ?? false,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      supplierName: data['supplierName'],
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'supplierId': supplierId,
      'category': category,
      'active': active,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'supplierName': supplierName,
    };
  }

  // Copy with method
  BannerModel copyWith({
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
    return BannerModel(
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
