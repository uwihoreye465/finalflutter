// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';

class AuthService with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      final token = prefs.getString('token');
      
      if (userData != null && token != null) {
        _user = User.fromJson(jsonDecode(userData));
        _token = token;
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);
      debugPrint('Auth service received response: $response');
      
      if (response['success'] == true || response['token'] != null) {
        _user = User.fromJson(response['user'] ?? response);
        _token = response['token'];
        _isAuthenticated = true;
        
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        await prefs.setString('token', _token!);
        
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Auth service error: $e');
      throw Exception('Login error: ${e.toString()}');
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    try {
      final response = await ApiService.register(userData);
      
      if (response['success'] == true) {
        // Registration successful, but user needs to verify email
        // You can handle this as needed
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('token');
      
      _user = null;
      _token = null;
      _isAuthenticated = false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
}