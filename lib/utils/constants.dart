
import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = 'https://tracking-criminal.onrender.com';
  static const String apiVersion = '/api/v1';
    static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  // ID Types
  static const List<String> idTypes = [
    'indangamuntu_yumunyarwanda',
    'indangamuntu_yumunyamahanga', 
    'indangampunzi',
    'passport'
  ];
  
  // Gender Options
  static const List<String> genderOptions = ['Male', 'Female'];
  
  // Marital Status Options
  static const List<String> maritalStatusOptions = [
    'Single', 'Married', 'Widower', 'Divorce'
  ];
  
  // Rwanda Provinces
  static const List<String> provinces = [
    'Kigali City', 'Eastern Province', 'Western Province', 
    'Northern Province', 'Southern Province'
  ];
}

class AppColors {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color textColor = Color(0xFF374151);
}