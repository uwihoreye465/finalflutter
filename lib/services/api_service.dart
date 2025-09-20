import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/criminal_record.dart';
import '../models/victim.dart';
import '../models/user.dart';
import '../models/notification.dart';
import '../models/arrested_criminal.dart';
import '../models/rwandan_citizen.dart';
import '../models/passport_holder.dart';
import '../utils/constants.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;
  static const String apiVersion = AppConstants.apiVersion;
  
  static String _url(String path) {
    return '$baseUrl$apiVersion$path';
  }

  // Test API connectivity
  static Future<bool> testApiConnection() async {
    try {
      debugPrint('Testing API connection to: $baseUrl$apiVersion');
      
      // Try multiple endpoints to test connectivity
      final endpoints = ['/health', '/auth/login', '/criminal-records'];
      
      for (String endpoint in endpoints) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl$apiVersion$endpoint'),
            headers: {'Content-Type': 'application/json'},
          );
          debugPrint('Health check response for $endpoint: ${response.statusCode} - ${response.body}');
          if (response.statusCode == 200 || response.statusCode == 401 || response.statusCode == 404) {
            // Any of these status codes means the server is reachable
            return true;
          }
        } catch (e) {
          debugPrint('Failed to reach $endpoint: $e');
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('API connection test failed: $e');
      return false;
    }
  }
  
  static Future<Map<String, String>> _getJsonHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Authentication
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('Attempting login for email: $email');
      debugPrint('API URL: ${_url('/auth/login')}');
      
      final requestBody = jsonEncode({'email': email, 'password': password});
      debugPrint('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse(_url('/auth/login')),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response headers: ${response.headers}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle the actual API response structure from Postman
        if (data['success'] == true) {
          // The API returns data in data.user and data.tokens structure
          if (data['data'] != null && data['data']['tokens'] != null) {
            return {
              'success': true,
              'user': data['data']['user'],
              'token': data['data']['tokens']['accessToken'],
              'refreshToken': data['data']['tokens']['refreshToken'],
            };
          } else {
            throw Exception(data['message'] ?? 'Login failed: Invalid response structure');
          }
        } else {
          throw Exception(data['message'] ?? 'Login failed: Invalid credentials');
        }
      } else if (response.statusCode == 401) {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? 'Invalid email or password';
        if (message.contains('approval') || message.contains('approve')) {
          throw Exception('Your account is pending admin approval. Please wait for approval.');
        }
        throw Exception(message);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid input data');
      } else if (response.statusCode == 500) {
        throw Exception('Server error: Please try again later');
      } else {
        final errorBody = response.body;
        try {
          final errorData = jsonDecode(errorBody);
          throw Exception(errorData['message'] ?? 'Login failed');
        } catch (e) {
          throw Exception('Login failed: $errorBody');
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('HandshakeException')) {
        throw Exception('Network error: Please check your internet connection');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout: Please try again');
      } else {
        throw Exception(e.toString());
      }
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse(_url('/auth/register')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Criminal Records
  static Future<CriminalRecord?> searchCriminalRecord(String idNumber) async {
    try {
      // Public endpoint: send no headers to avoid CORS preflight on web
      final response = await http.get(
        Uri.parse(_url('/criminal-records/search/$idNumber')),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Search response: $data'); // Debug log
        
        // Check if the response indicates a criminal record was found
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'];
          
          // Check if person has crimes
          if (responseData['hasCrimes'] == true && 
              responseData['criminalRecords'] != null && 
              responseData['criminalRecords'].isNotEmpty) {
            
            // Get the first criminal record
            final criminalData = responseData['criminalRecords'][0];
            debugPrint('Criminal data found: $criminalData');
            
            // Only return criminal record if it has required fields
            if (criminalData['first_name'] != null && 
                criminalData['last_name'] != null && 
                criminalData['crime_type'] != null) {
              return CriminalRecord.fromJson(criminalData);
            }
          }
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint('Search failed with status: ${response.statusCode}, body: ${response.body}');
        throw Exception('Search failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Search error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getCriminalRecords({
    int page = 1,
    int limit = 10,
    String? search,
    String? idType,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      String url = _url('/criminal-records?page=$page&limit=$limit');
      
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      if (idType != null && idType.isNotEmpty) {
        url += '&id_type=$idType';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch criminal records: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> addCriminalRecord(CriminalRecord record) async {
    try {
      final headers = await _getJsonHeaders();
      final response = await http.post(
        Uri.parse(_url('/criminal-records')),
        headers: headers,
        body: jsonEncode(record.toJson(includeId: false, forCreation: true)),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add criminal record: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Victims
  static Future<Map<String, dynamic>> getVictims({
    int page = 1,
    int limit = 10,
    String? search,
    String? idType,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      String url = _url('/victims?page=$page&limit=$limit');
      
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      if (idType != null && idType.isNotEmpty) {
        url += '&id_type=$idType';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch victims: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> addVictim(Victim victim) async {
    try {
      final headers = await _getJsonHeaders();
      final response = await http.post(
        Uri.parse(_url('/victims')),
        headers: headers,
        body: jsonEncode(victim.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add victim: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Statistics
  static Future<Map<String, dynamic>> getCriminalStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/criminal-records/statistics')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getVictimStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/victims/statistics')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch victim statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Users Management (Admin)
  static Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/users?page=$page&limit=$limit')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch users: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> approveUser(int userId, bool approve) async {
    try {
      final headers = await _getJsonHeaders();
      final response = await http.put(
        Uri.parse(_url('/users/$userId/approval')),
        headers: headers,
        body: jsonEncode({'approval': approve.toString()}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update user approval: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Criminal Records - Additional endpoints
  static Future<CriminalRecord?> getCriminalRecordById(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/criminal-records/$id')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return CriminalRecord.fromJson(data['data']);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch criminal record: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateCriminalRecord(int id, CriminalRecord record) async {
    try {
      final headers = await _getJsonHeaders();
      final response = await http.put(
        Uri.parse(_url('/criminal-records/$id')),
        headers: headers,
        body: jsonEncode(record.toJson(includeId: false)),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update criminal record: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> deleteCriminalRecord(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse(_url('/criminal-records/$id')),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getRecentCriminalRecords() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/criminal-records/recent')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch recent criminal records: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Victims - Additional endpoints
  static Future<Victim?> getVictimById(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/victims/$id')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Victim.fromJson(data['data']);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch victim: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateVictim(int id, Victim victim) async {
    try {
      final headers = await _getJsonHeaders();
      final response = await http.put(
        Uri.parse(_url('/victims/$id')),
        headers: headers,
        body: jsonEncode(victim.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update victim: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> deleteVictim(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse(_url('/victims/$id')),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getRecentVictims() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/victims/recent')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch recent victims: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Arrested Criminals
  static Future<Map<String, dynamic>> getArrestedCriminals({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/arrested?page=$page&limit=$limit')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch arrested criminals: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> addArrestedCriminal(ArrestedCriminal arrested) async {
    try {
      final headers = await _getJsonHeaders();
      final response = await http.post(
        Uri.parse(_url('/arrested')),
        headers: headers,
        body: jsonEncode(arrested.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add arrested criminal: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateArrestedCriminal(int id, ArrestedCriminal arrested) async {
    try {
      final headers = await _getJsonHeaders();
      final response = await http.put(
        Uri.parse(_url('/arrested/$id')),
        headers: headers,
        body: jsonEncode(arrested.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update arrested criminal: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> deleteArrestedCriminal(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse(_url('/arrested/$id')),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getArrestedStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/arrested/statistics')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch arrested statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Notifications
  static Future<Map<String, dynamic>> sendNotification(Map<String, dynamic> notificationData) async {
    try {
      final headers = await _getJsonHeaders();
      final response = await http.post(
        Uri.parse(_url('/notifications')),
        headers: headers,
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/notifications?page=$page&limit=$limit')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch notifications: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<NotificationModel?> getNotificationById(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/notifications/$id')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return NotificationModel.fromJson(data['data']);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch notification: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> deleteNotification(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse(_url('/notifications/$id')),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getNotificationStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/notifications/stats/rib-statistics')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch notification statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // User Management - Additional endpoints
  static Future<Map<String, dynamic>> getPendingUsers() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/users/pending')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch pending users: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }


  static Future<Map<String, dynamic>> updateUserRole(int userId, String role) async {
    try {
      final headers = await _getJsonHeaders();
      final response = await http.put(
        Uri.parse(_url('/users/$userId')),
        headers: headers,
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update user role: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> deleteUser(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse(_url('/users/$id')),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Authentication - Additional endpoints
  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await http.get(
        Uri.parse(_url('/auth/verify-email/$token')),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Email verification failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(_url('/auth/forgot-password')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Forgot password failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await _getJsonHeaders();
      final response = await http.post(
        Uri.parse(_url('/auth/change-password')),
        headers: headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Change password failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // NIDA Data Lookup Endpoints - Updated to use correct API endpoints
  static Future<RwandanCitizen?> searchRwandanCitizen(String idNumber) async {
    try {
      // Use the criminal records search endpoint which returns person data
      final response = await http.get(
        Uri.parse(_url('/criminal-records/search/$idNumber')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'];
          
          // Check if person exists and has citizen data
          if (responseData['person'] != null && responseData['personType'] == 'citizen') {
            return RwandanCitizen.fromJson(responseData['person']);
          }
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Search failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<PassportHolder?> searchPassportHolder(String passportNumber) async {
    try {
      // Use the criminal records search endpoint which returns person data
      final response = await http.get(
        Uri.parse(_url('/criminal-records/search/$passportNumber')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'];
          
          // Check if person exists and has passport data
          if (responseData['person'] != null && responseData['personType'] == 'passport') {
            return PassportHolder.fromJson(responseData['person']);
          }
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Search failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Universal person search that checks both citizens and passport holders
  static Future<Map<String, dynamic>?> searchPersonData(String idNumber) async {
    try {
      // Use the criminal records search endpoint which returns person data
      final response = await http.get(
        Uri.parse(_url('/criminal-records/search/$idNumber')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'];
          
          // Check if person exists
          if (responseData['person'] != null) {
            final personType = responseData['personType'] ?? 'citizen';
            if (personType == 'passport') {
              return {
                'type': 'passport',
                'data': PassportHolder.fromJson(responseData['person']),
              };
            } else {
              return {
                'type': 'citizen',
                'data': RwandanCitizen.fromJson(responseData['person']),
              };
            }
          }
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Search failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }


  // Image Upload for Arrested Criminals
  static Future<String> uploadImage(File imageFile) async {
    try {
      final headers = await _getAuthHeaders();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(_url('/upload/image')),
      );
      
      request.headers.addAll(headers);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseData);
        return data['imageUrl']; // Return the uploaded image URL
      } else {
        throw Exception('Image upload failed: $responseData');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get notifications (admin)
  static Future<Map<String, dynamic>> getNotificationsAdmin() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/notifications')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting notifications: $e');
    }
  }

  // Create notification
  static Future<Map<String, dynamic>> createNotification(Map<String, dynamic> notificationData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse(_url('/notifications')),
        headers: headers,
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  // Update notification
  static Future<Map<String, dynamic>> updateNotification(int notificationId, Map<String, dynamic> notificationData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse(_url('/notifications/$notificationId')),
        headers: headers,
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating notification: $e');
    }
  }

  // Delete notification (admin)
  static Future<Map<String, dynamic>> deleteNotificationAdmin(int notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse(_url('/notifications/$notificationId')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  // Get users (admin)
  static Future<Map<String, dynamic>> getUsersAdmin() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/users')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting users: $e');
    }
  }

  // Create user
  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse(_url('/users')),
        headers: headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  // Update user
  static Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse(_url('/users/$userId')),
        headers: headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // Delete user (admin)
  static Future<Map<String, dynamic>> deleteUserAdmin(int userId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse(_url('/users/$userId')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Get criminal records statistics
  static Future<Map<String, dynamic>> getCriminalRecordsStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/criminal-records/statistics')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get criminal records statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting criminal records statistics: $e');
    }
  }

  // Get victims statistics
  static Future<Map<String, dynamic>> getVictimsStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/victims/statistics')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get victims statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting victims statistics: $e');
    }
  }

  // Get notifications statistics
  static Future<Map<String, dynamic>> getNotificationsStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/notifications/stats/rib-statistics')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get notifications statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting notifications statistics: $e');
    }
  }

  // Get arrested criminals statistics
  static Future<Map<String, dynamic>> getArrestedCriminalsStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(_url('/arrested/statistics')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get arrested criminals statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting arrested criminals statistics: $e');
    }
  }

  // Mark notification as read
  static Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse(_url('/notifications/$notificationId/read')),
        headers: headers,
        body: jsonEncode({'is_read': true}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

}