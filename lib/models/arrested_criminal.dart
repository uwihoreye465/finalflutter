class ArrestedCriminal {
  final int? arrestId;
  final String fullname;
  final String? imageUrl;
  final String crimeType;
  final DateTime dateArrested;
  final String? arrestLocation;
  final String? idType;
  final String? idNumber;
  final int? criminalRecordId;
  final int? arrestingOfficerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ArrestedCriminal({
    this.arrestId,
    required this.fullname,
    this.imageUrl,
    required this.crimeType,
    required this.dateArrested,
    this.arrestLocation,
    this.idType,
    this.idNumber,
    this.criminalRecordId,
    this.arrestingOfficerId,
    this.createdAt,
    this.updatedAt,
  });

  factory ArrestedCriminal.fromJson(Map<String, dynamic> json) {
    return ArrestedCriminal(
      arrestId: json['arrest_id'],
      fullname: json['fullname'] ?? '',
      imageUrl: json['image_url'],
      crimeType: json['crime_type'] ?? '',
      dateArrested: json['date_arrested'] != null 
          ? DateTime.parse(json['date_arrested']) 
          : DateTime.now(),
      arrestLocation: json['arrest_location'],
      idType: json['id_type'],
      idNumber: json['id_number'],
      criminalRecordId: json['criminal_record_id'],
      arrestingOfficerId: json['arresting_officer_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'arrest_id': arrestId,
      'fullname': fullname,
      'image_url': imageUrl,
      'crime_type': crimeType,
      'date_arrested': dateArrested.toIso8601String().split('T')[0],
      'arrest_location': arrestLocation,
      'id_type': idType,
      'id_number': idNumber,
      'criminal_record_id': criminalRecordId,
      'arresting_officer_id': arrestingOfficerId,
    };
  }
}
