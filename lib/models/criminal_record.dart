class CriminalRecord {
  final int? criId;
  final int? citizenId;
  final int? passportHolderId;
  final String idType;
  final String idNumber;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime? dateOfBirth;
  final String? maritalStatus;
  final String? country;
  final String? province;
  final String? district;
  final String? sector;
  final String? cell;
  final String? village;
  final String? addressNow;
  final String? phone;
  final String crimeType;
  final String? description;
  final DateTime? dateCommitted;
  final int? vicId;
  final DateTime? createdAt;
  final int? registeredBy;

  CriminalRecord({
    this.criId,
    this.citizenId,
    this.passportHolderId,
    required this.idType,
    required this.idNumber,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    this.maritalStatus,
    this.country,
    this.province,
    this.district,
    this.sector,
    this.cell,
    this.village,
    this.addressNow,
    this.phone,
    required this.crimeType,
    this.description,
    this.dateCommitted,
    this.vicId,
    this.createdAt,
    this.registeredBy,
  });

  factory CriminalRecord.fromJson(Map<String, dynamic> json) {
    return CriminalRecord(
      criId: json['cri_id'],
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
      maritalStatus: json['marital_status'],
      country: json['country'],
      province: json['province'],
      district: json['district'],
      sector: json['sector'],
      cell: json['cell'],
      village: json['village'],
      addressNow: json['address_now'],
      phone: json['phone'],
      crimeType: json['crime_type'] ?? '',
      description: json['description'],
      dateCommitted: json['date_committed'] != null 
          ? DateTime.parse(json['date_committed']) 
          : null,
      vicId: json['vic_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      registeredBy: json['registered_by'],
    );
  }

  Map<String, dynamic> toJson({bool includeId = true, bool forCreation = false}) {
    final Map<String, dynamic> json = {
      'id_type': idType,
      'id_number': idNumber,
      'address_now': addressNow,
      'phone': phone,
      'crime_type': crimeType,
      'description': description,
      'date_committed': dateCommitted?.toIso8601String().split('T')[0],
    };
    
    // Only include additional fields if not for creation
    if (!forCreation) {
      json['first_name'] = firstName;
      json['last_name'] = lastName;
      json['gender'] = gender;
      json['date_of_birth'] = dateOfBirth?.toIso8601String().split('T')[0];
      json['marital_status'] = maritalStatus;
      json['country'] = country;
      json['province'] = province;
      json['district'] = district;
      json['sector'] = sector;
      json['cell'] = cell;
      json['village'] = village;
      json['vic_id'] = vicId;
      json['registered_by'] = registeredBy;
    }
    
    // Only include the correct ID based on id_type
    if (idType == 'passport') {
      if (passportHolderId != null) {
        json['passport_holder_id'] = passportHolderId;
      }
      // Don't include citizen_id for passport holders
    } else {
      if (citizenId != null) {
        json['citizen_id'] = citizenId;
      }
      // Don't include passport_holder_id for citizens
    }
    
    if (includeId && criId != null) {
      json['cri_id'] = criId;
    }
    
    // Remove null values to prevent sending them to API
    json.removeWhere((key, value) => value == null);
    
    return json;
  }
}