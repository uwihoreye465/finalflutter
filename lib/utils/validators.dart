class Validators {
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneRegex = RegExp(r'^\+?[\d\s-()]{10,}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  static String? validateIdNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ID number is required';
    }
    
    // Check if it's a 16-digit Rwandan ID or passport format
    final rwandanIdRegex = RegExp(r'^\d{16}$');
    final passportRegex = RegExp(r'^[A-Za-z0-9]{6,12}$');
    
    if (!rwandanIdRegex.hasMatch(value.trim()) && !passportRegex.hasMatch(value.trim())) {
      return 'Please enter a valid ID number or passport';
    }
    
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}