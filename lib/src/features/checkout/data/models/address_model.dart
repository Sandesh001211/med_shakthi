class AddressModel {
  final String id;
  final String userId;
  final String title;
  final String? remarks;
  final String fullAddress;
  final double lat;
  final double lng;
  final bool isSelected;

  AddressModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.fullAddress,
    required this.lat,
    required this.lng,
    this.remarks,
    this.isSelected = false,
  });

  AddressModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? fullAddress,
    double? lat,
    double? lng,
    String? remarks,
    bool? isSelected,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      fullAddress: fullAddress ?? this.fullAddress,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      remarks: remarks ?? this.remarks,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'full_address': fullAddress,
      'lat': lat,
      'lng': lng,
      'remarks': remarks,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? 'Home',
      fullAddress: map['full_address'] ?? map['address'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      remarks: map['remarks'],
      isSelected: false,
    );
  }

  @override
  String toString() {
    return 'AddressModel(id: $id, title: $title, fullAddress: $fullAddress, remarks: $remarks)';
  }
}
