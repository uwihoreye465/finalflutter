class NotificationModel {
  final int? notId;
  final String nearRib;
  final String fullname;
  final String address;
  final String phone;
  final String message;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime? createdAt;
  final bool isRead;

  NotificationModel({
    this.notId,
    required this.nearRib,
    required this.fullname,
    required this.address,
    required this.phone,
    required this.message,
    this.latitude,
    this.longitude,
    this.locationName,
    this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notId: json['not_id'],
      nearRib: json['near_rib'] ?? '',
      fullname: json['fullname'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      message: json['message'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      locationName: json['location_name'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'not_id': notId,
      'near_rib': nearRib,
      'fullname': fullname,
      'address': address,
      'phone': phone,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'created_at': createdAt?.toIso8601String(),
      'is_read': isRead,
    };
  }
}