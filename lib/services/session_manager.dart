import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'auth_service.dart';

class SessionManager with ChangeNotifier {
  static const String _sessionKey = 'user_session';
  static const String _lastActivityKey = 'last_activity';
  static const int _sessionTimeoutMinutes = 30; // 30 minutes timeout
  
  Timer? _sessionTimer;
  DateTime? _lastActivity;
  bool _isSessionActive = false;
  
  bool get isSessionActive => _isSessionActive;
  DateTime? get lastActivity => _lastActivity;
  
  SessionManager() {
    _initializeSession();
  }
  
  Future<void> _initializeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_sessionKey);
      final lastActivityStr = prefs.getString(_lastActivityKey);
      
      if (sessionData != null && lastActivityStr != null) {
        _lastActivity = DateTime.parse(lastActivityStr);
        final now = DateTime.now();
        final difference = now.difference(_lastActivity!);
        
        // Check if session is still valid
        if (difference.inMinutes < _sessionTimeoutMinutes) {
          _isSessionActive = true;
          _startSessionTimer();
          debugPrint('Session restored - valid for ${_sessionTimeoutMinutes - difference.inMinutes} more minutes');
        } else {
          debugPrint('Session expired - clearing data');
          await clearSession();
        }
      }
    } catch (e) {
      debugPrint('Error initializing session: $e');
      await clearSession();
    }
  }
  
  Future<void> startSession(AuthService authService) async {
    try {
      if (authService.isAuthenticated) {
        _lastActivity = DateTime.now();
        _isSessionActive = true;
        
        // Save session data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionKey, jsonEncode({
          'user_id': authService.user?.userId,
          'email': authService.user?.email,
          'role': authService.user?.role,
          'started_at': _lastActivity!.toIso8601String(),
        }));
        await prefs.setString(_lastActivityKey, _lastActivity!.toIso8601String());
        
        _startSessionTimer();
        notifyListeners();
        debugPrint('Session started for user: ${authService.user?.email}');
      }
    } catch (e) {
      debugPrint('Error starting session: $e');
    }
  }
  
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkSessionValidity();
    });
  }
  
  Future<void> _checkSessionValidity() async {
    if (_lastActivity == null) return;
    
    final now = DateTime.now();
    final difference = now.difference(_lastActivity!);
    
    if (difference.inMinutes >= _sessionTimeoutMinutes) {
      debugPrint('Session timeout - clearing session');
      await clearSession();
    }
  }
  
  Future<void> updateActivity() async {
    if (!_isSessionActive) return;
    
    _lastActivity = DateTime.now();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastActivityKey, _lastActivity!.toIso8601String());
      debugPrint('Session activity updated');
    } catch (e) {
      debugPrint('Error updating session activity: $e');
    }
  }
  
  Future<void> clearSession() async {
    try {
      _sessionTimer?.cancel();
      _sessionTimer = null;
      _isSessionActive = false;
      _lastActivity = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_lastActivityKey);
      
      notifyListeners();
      debugPrint('Session cleared');
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }
  
  Future<void> extendSession() async {
    if (_isSessionActive) {
      await updateActivity();
      debugPrint('Session extended');
    }
  }
  
  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
