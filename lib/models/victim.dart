class Victim {
  final int? vicId;
  final int? citizenId;
  final int? passportHolderId;
  final String idType;
  final String idNumber;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime? dateOfBirth;
  final String? province;
  final String? district;
  final String? sector;
  final String? cell;
  final String? village;
  final String? country;
  final String? addressNow;
  final String? phone;
  final String? victimEmail;
  final String? maritalStatus;
  final String? sinnerIdentification;
  final String crimeType;
  final Map<String, dynamic>? evidence;
  final DateTime? dateCommitted;
  final int? criminalId;
  final DateTime? createdAt;
  final int? registeredBy;

  Victim({
    this.vicId,
    this.citizenId,
    this.passportHolderId,
    required this.idType,
    required this.idNumber,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    this.province,
    this.district,
    this.sector,
    this.cell,
    this.village,
    this.country,
    this.addressNow,
    this.phone,
    this.victimEmail,
    this.maritalStatus,
    this.sinnerIdentification,
    required this.crimeType,
    this.evidence,
    this.dateCommitted,
    this.criminalId,
    this.createdAt,
    this.registeredBy,
  });

  factory Victim.fromJson(Map<String, dynamic> json) {
    return Victim(
      vicId: json['vic_id'],
      citizenId: json['citizen_id'],
      passportHolderId: json['passport_holder_id'],
      idType: json['id_type'] ?? '',
      idNumber: json['id_number'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      province: json['province'],
      district: json['district'],
      sector: json['sector'],
      cell: json['cell'],
      village: json['village'],
      country: json['country'],
      addressNow: json['address_now'],
      phone: json['phone'],
      victimEmail: json['victim_email'],
      maritalStatus: json['marital_status'],
      sinnerIdentification: json['sinner_identification'],
      crimeType: json['crime_type'] ?? '',
      evidence: json['evidence'] != null ? Map<String, dynamic>.from(json['evidence']) : null,
      dateCommitted: json['date_committed'] != null 
          ? DateTime.parse(json['date_committed']) 
          : null,
      criminalId: json['criminal_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      registeredBy: json['registered_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vic_id': vicId,
      'citizen_id': citizenId,
      'passport_holder_id': passportHolderId,
      'id_type': idType,
      'id_number': idNumber,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'province': province,
      'district': district,
      'sector': sector,
      'cell': cell,
      'village': village,
      'country': country,
      'address_now': addressNow,
      'phone': phone,
      'victim_email': victimEmail,
      'marital_status': maritalStatus,
      'sinner_identification': sinnerIdentification,
      'crime_type': crimeType,
      'evidence': evidence ?? {
        'description': '',
        'files': [],
        'uploadedAt': DateTime.now().toIso8601String(),
      },
      'date_committed': dateCommitted?.toIso8601String().split('T')[0],
      'criminal_id': criminalId,
      'registered_by': registeredBy,
    };
  }
}