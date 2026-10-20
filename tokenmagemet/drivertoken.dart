import 'dart:convert';
import 'dart:convert' show base64Url;
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // ===============================
  // SAVE TOKEN
  // ===============================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // ===============================
  // SAVE USER DATA
  // ===============================
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, json.encode(userData));
  }

  // ===============================
  // GET TOKEN
  // ===============================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ===============================
  // CLEAR SESSION / LOGOUT
  // ===============================
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print('DEBUG: SessionManager - Starting session cleanup...');
      
      // Get current values before clearing (for debugging)
      final currentToken = prefs.getString(_tokenKey);
      final currentUserData = prefs.getString(_userDataKey);
      print('DEBUG: SessionManager - Current token: $currentToken');
      print('DEBUG: SessionManager - Current user data: $currentUserData');
      
      // Remove all authentication-related data
      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);
      
      // Verify removal
      final tokenAfter = prefs.getString(_tokenKey);
      final userDataAfter = prefs.getString(_userDataKey);
      print('DEBUG: SessionManager - Token after removal: $tokenAfter');
      print('DEBUG: SessionManager - User data after removal: $userDataAfter');
      
      // Additional cleanup - remove any other auth-related keys if they exist
      final keys = prefs.getKeys();
      final authKeys = keys.where((key) => 
        key.contains('auth') || 
        key.contains('token') || 
        key.contains('user') ||
        key.contains('login')
      ).toList();
      
      if (authKeys.isNotEmpty) {
        print('DEBUG: SessionManager - Additional auth keys found: $authKeys');
        for (final key in authKeys) {
          await prefs.remove(key);
          print('DEBUG: SessionManager - Removed additional key: $key');
        }
      }
      
      print('DEBUG: SessionManager - Session cleanup completed successfully');
    } catch (e) {
      print('DEBUG: SessionManager - Error during session cleanup: $e');
      rethrow;
    }
  }

  // ===============================
  // CHECK IF LOGGED IN
  // ===============================
  // Returns true only if token exists and userId & role are valid
  static Future<bool> isLoggedIn() async {
    final data = await getUserFromToken();
    return data != null && data['id'] != null && data['role'] != null;
  }

  // ===============================
  // GET USER DATA FROM STORED DATA
  // ===============================
  static Future<Map<String, dynamic>?> getUserFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    
    if (userDataString == null || userDataString.isEmpty) {
      print('SessionManager: No user data found');
      return null;
    }

    try {
      final Map<String, dynamic> userData = json.decode(userDataString);
      
      final String? id =
          userData['id']?.toString() ??
          userData['_id']?.toString() ??
          userData['userId']?.toString();

      final String? role = userData['role']?.toString();

      print('SessionManager: ID=$id ROLE=$role');

      return {
        'id': id,
        'role': role,
        'userData': userData,
      };
    } catch (e) {
      print('SessionManager: User data decode error: $e');
      return null;
    }
  }

  // ===============================
  // OPTIONAL: GET ONLY USER ID
  // ===============================
  static Future<String?> getUserIdFromToken() async {
    final data = await getUserFromToken();
    return data?['id'];
  }

  // ===============================
  // OPTIONAL: GET ONLY ROLE
  // ===============================
  static Future<String?> getRoleFromToken() async {
    final data = await getUserFromToken();
    return data?['role'];
  }
}
