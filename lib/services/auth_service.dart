// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';
import 'session_manager.dart';

class AuthService with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  SessionManager? _sessionManager;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthService() {
    loadUserFromStorage();
  }

  // Set session manager reference
  void setSessionManager(SessionManager sessionManager) {
    _sessionManager = sessionManager;
  }

  Future<void> loadUserFromStorage() async {
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
        // Handle different response structures
        if (response['data'] != null && response['data']['user'] != null) {
          // New API structure: {success: true, data: {user: {...}, tokens: {...}}}
          _user = User.fromJson(response['data']['user']);
          _token = response['data']['tokens']?['accessToken'] ?? response['data']['token'];
        } else if (response['user'] != null) {
          // Old API structure: {success: true, user: {...}, token: "..."}
          _user = User.fromJson(response['user']);
          _token = response['token'];
        } else if (response['data'] != null) {
          // Direct data structure: {success: true, data: {...}}
          _user = User.fromJson(response['data']);
          _token = response['token'];
        } else {
          // If no user object, create one from available data
          _user = User(
            userId: response['user_id'] ?? 0,
            fullname: response['fullname'] ?? 'User',
            email: email,
            role: response['role'] ?? 'user',
            sector: response['sector'] ?? '',
            position: response['position'] ?? '',
            isVerified: response['is_verified'] ?? false,
          );
          _token = response['token'];
        }
        
        _isAuthenticated = true;
        
        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        await prefs.setString('token', _token!);
        
        // Start session
        if (_sessionManager != null) {
          await _sessionManager!.startSession(this);
        }
        
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Login failed: Invalid credentials');
      }
    } catch (e) {
      debugPrint('Auth service error: $e');
      // Re-throw the original exception to preserve the specific error message
      rethrow;
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
      // Clear session
      if (_sessionManager != null) {
        await _sessionManager!.clearSession();
      }
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('token');
      await prefs.remove('refreshToken');
      
      // Clear instance state
      _user = null;
      _token = null;
      _isAuthenticated = false;
      _isLoading = false;
      
      notifyListeners();
    } catch (e) {
      // Even if there's an error, clear the state
      _user = null;
      _token = null;
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if token is valid and not expired
  Future<bool> isTokenValid() async {
    if (_token == null) return false;
    
    try {
      // You can add token validation logic here
      // For now, we'll just check if token exists and user is authenticated
      return _isAuthenticated && _user != null;
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }

  // Refresh user session
  Future<void> refreshSession() async {
    try {
      if (_token != null && _user != null) {
        // Validate current session
        final isValid = await isTokenValid();
        if (!isValid) {
          await logout();
        }
      }
    } catch (e) {
      debugPrint('Session refresh error: $e');
      await logout();
    }
  }
}