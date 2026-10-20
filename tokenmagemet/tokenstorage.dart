import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionManager {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _profileDetailsKey = 'profile_details';
  static const String _registeredUserNameKey = 'registered_user_name';

  // Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Save User ID
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // Save User Data
  static Future<void> saveUserData(String userDataJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, userDataJson);
  }

  static Future<void> saveRegisteredUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registeredUserNameKey, name.trim());
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get User ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final directUserId = prefs.getString(_userIdKey);
    if (directUserId != null && directUserId.trim().isNotEmpty) {
      return directUserId;
    }

    // Fallback: derive user id from persisted user_data when user_id is missing.
    final userDataJson = prefs.getString(_userDataKey);
    if (userDataJson == null || userDataJson.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(userDataJson);
      if (decoded is Map<String, dynamic>) {
        final fallbackUserId = _extractUserId(decoded);
        if (fallbackUserId != null &&
            fallbackUserId.trim().isNotEmpty) {
          final normalized = fallbackUserId;
          await prefs.setString(_userIdKey, normalized);
          return normalized;
        }
      }
    } catch (_) {
      // Ignore malformed user_data and return null.
    }

    final token = prefs.getString(_tokenKey);
    final tokenUserId = _extractUserIdFromToken(token);
    if (tokenUserId != null && tokenUserId.trim().isNotEmpty) {
      await prefs.setString(_userIdKey, tokenUserId);
      return tokenUserId;
    }

    return null;
  }

  static String? _extractUserId(Map<String, dynamic> map) {
    final direct = map['_id'] ?? map['id'] ?? map['userId'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }

    const nestedKeys = ['user', 'data', 'profile', 'account'];
    for (final key in nestedKeys) {
      final nested = map[key];
      if (nested is Map<String, dynamic>) {
        final nestedId = _extractUserId(nested);
        if (nestedId != null && nestedId.trim().isNotEmpty) {
          return nestedId;
        }
      }
    }

    for (final value in map.values) {
      if (value is Map<String, dynamic>) {
        final nestedId = _extractUserId(value);
        if (nestedId != null && nestedId.trim().isNotEmpty) {
          return nestedId;
        }
      }
    }

    return null;
  }

  static String? _extractUserIdFromToken(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;

    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decodedPayload = utf8.decode(base64Url.decode(normalized));
      final payloadJson = json.decode(decodedPayload);
      if (payloadJson is Map<String, dynamic>) {
        final tokenId = payloadJson['sub'] ??
            payloadJson['userId'] ??
            payloadJson['id'] ??
            payloadJson['_id'];
        if (tokenId != null && tokenId.toString().trim().isNotEmpty) {
          return tokenId.toString();
        }
      }
    } catch (_) {
      // Ignore token parse errors.
    }
    return null;
  }

  // Get User Data
  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userDataKey);
  }

  static Future<void> saveProfileDetails(String profileDetailsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileDetailsKey, profileDetailsJson);
  }

  static Future<String?> getProfileDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileDetailsKey);
  }

  static Future<String?> getRegisteredUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString(_registeredUserNameKey);
    if (storedName == null || storedName.trim().isEmpty) {
      return null;
    }
    return storedName.trim();
  }

  // Logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check login
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
