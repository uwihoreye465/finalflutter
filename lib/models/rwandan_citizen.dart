class RwandanCitizen {
  final int? id;
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
  final String? phone;
  final String? email;
  final String? occupation;
  final String? maritalStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RwandanCitizen({
    this.id,
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
    this.phone,
    this.email,
    this.occupation,
    this.maritalStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory RwandanCitizen.fromJson(Map<String, dynamic> json) {
    return RwandanCitizen(
      id: json['id'],
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
      phone: json['phone'],
      email: json['email'],
      occupation: json['occupation'],
      maritalStatus: json['marital_status'],
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
      'id': id,
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
      'phone': phone,
      'email': email,
      'occupation': occupation,
      'marital_status': maritalStatus,
    };
  }
}
