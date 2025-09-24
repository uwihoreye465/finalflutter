class User {
  final int? userId;
  final String sector;
  final String fullname;
  final String position;
  final String email;
  final String? password;
  final String role;
  final String? verificationToken;
  final bool isVerified;
  final bool isApproved;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final DateTime? sessionExpiry;
  final DateTime? lastLogout;
  final String? resetToken;
  final DateTime? resetTokenExpiry;

  User({
    this.userId,
    required this.sector,
    required this.fullname,
    required this.position,
    required this.email,
    this.password,
    required this.role,
    this.verificationToken,
    this.isVerified = false,
    this.isApproved = false,
    this.createdAt,
    this.lastLogin,
    this.sessionExpiry,
    this.lastLogout,
    this.resetToken,
    this.resetTokenExpiry,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? json['id'], // Handle both 'user_id' and 'id'
      sector: json['sector'] ?? '',
      fullname: json['fullname'] ?? '',
      position: json['position'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      role: json['role'] ?? 'staff',
      verificationToken: json['verification_token'],
      isVerified: json['is_verified'] ?? false,
      isApproved: json['is_approved'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      sessionExpiry: json['session_expiry'] != null 
          ? DateTime.parse(json['session_expiry']) 
          : null,
      lastLogout: json['last_logout'] != null 
          ? DateTime.parse(json['last_logout']) 
          : null,
      resetToken: json['reset_token'],
      resetTokenExpiry: json['reset_token_expiry'] != null 
          ? DateTime.parse(json['reset_token_expiry']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'sector': sector,
      'fullname': fullname,
      'position': position,
      'email': email,
      'password': password,
      'role': role,
      'verification_token': verificationToken,
      'is_verified': isVerified,
      'is_approved': isApproved,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'session_expiry': sessionExpiry?.toIso8601String(),
      'last_logout': lastLogout?.toIso8601String(),
      'reset_token': resetToken,
      'reset_token_expiry': resetTokenExpiry?.toIso8601String(),
    };
  }
}