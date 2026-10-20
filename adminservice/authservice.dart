import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/adminmodel/authmodel.dart';
import 'package:taxiuuse/adminmodel/response.dart';



class ApiService {
  static const String _baseUrl = 'https://ola-7ii1.onrender.com/api';
  static const Duration _timeoutDuration = Duration(seconds: 10);
  
  static Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(_timeoutDuration);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Handle different response structures
        if (data.containsKey('success')) {
          // Response already has success field
          return AuthResponse.fromJson(data);
        } else if (data.containsKey('token')) {
          // Response has token directly
          return AuthResponse(
            success: true,
            message: 'Login successful',
            token: data['token'],
            user: User.fromJson(data),
          );
        } else {
          return AuthResponse(
            success: false,
            message: 'Invalid response format',
          );
        }
      } else if (response.statusCode == 401) {
        return AuthResponse(
          success: false,
          message: 'Invalid email or password',
        );
      } else if (response.statusCode == 404) {
        return AuthResponse(
          success: false,
          message: 'User not found',
        );
      } else {
        return AuthResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      return AuthResponse(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // Example: Registration endpoint
  static Future<AuthResponse> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      ).timeout(_timeoutDuration);

      print('Registration Response Status: ${response.statusCode}');
      print('Registration Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Handle different response structures
        if (data.containsKey('success')) {
          // Response already has success field
          return AuthResponse.fromJson(data);
        } else if (data.containsKey('message') && data['message'] == 'User registered successfully') {
          // Response has success message but no success field
          return AuthResponse(
            success: true,
            message: data['message'],
            user: data['user'] != null ? User.fromJson(data['user']) : null,
          );
        } else {
          // Assume success if status code is good and no error message
          return AuthResponse(
            success: true,
            message: data['message'] ?? 'User registered successfully',
            user: data['user'] != null ? User.fromJson(data['user']) : null,
          );
        }
      } else {
        return AuthResponse(
          success: false,
          message: 'Registration failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Registration Error: $e');
      return AuthResponse(
        success: false,
        message: 'Connection failed: $e',
      );
    }
  }

  
}