class PassportHolder {
  final int? id;
  final String passportNumber;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? countryOfResidence;
  final String? addressInRwanda;
  final String? homeAddress;
  final String? phone;
  final String? email;
  final String? occupation;
  final String? maritalStatus;
  final DateTime? passportIssueDate;
  final DateTime? passportExpiryDate;
  final String? issuingCountry;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PassportHolder({
    this.id,
    required this.passportNumber,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    this.nationality,
    this.countryOfResidence,
    this.addressInRwanda,
    this.homeAddress,
    this.phone,
    this.email,
    this.occupation,
    this.maritalStatus,
    this.passportIssueDate,
    this.passportExpiryDate,
    this.issuingCountry,
    this.createdAt,
    this.updatedAt,
  });

  factory PassportHolder.fromJson(Map<String, dynamic> json) {
    return PassportHolder(
      id: json['id'],
      passportNumber: json['passport_number'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      nationality: json['nationality'],
      countryOfResidence: json['country_of_residence'],
      addressInRwanda: json['address_in_rwanda'],
      homeAddress: json['home_address'],
      phone: json['phone'],
      email: json['email'],
      occupation: json['occupation'],
      maritalStatus: json['marital_status'],
      passportIssueDate: json['passport_issue_date'] != null 
          ? DateTime.parse(json['passport_issue_date']) 
          : null,
      passportExpiryDate: json['passport_expiry_date'] != null 
          ? DateTime.parse(json['passport_expiry_date']) 
          : null,
      issuingCountry: json['issuing_country'],
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
      'passport_number': passportNumber,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'nationality': nationality,
      'country_of_residence': countryOfResidence,
      'address_in_rwanda': addressInRwanda,
      'home_address': homeAddress,
      'phone': phone,
      'email': email,
      'occupation': occupation,
      'marital_status': maritalStatus,
      'passport_issue_date': passportIssueDate?.toIso8601String().split('T')[0],
      'passport_expiry_date': passportExpiryDate?.toIso8601String().split('T')[0],
      'issuing_country': issuingCountry,
    };
  }
}
