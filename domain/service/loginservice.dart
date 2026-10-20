
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/core/config.dart';
import 'package:taxiuuse/data/loginmodel.dart';



class AuthService {
  final String _baseUrl = AppConfig.apiBaseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  // Register method (from previous)
  Future<LoginResponse> register(LoginRequest user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(user.toJson()),
      ).timeout(_timeout);

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return LoginResponse(
          success: true,
          message: responseData['message'] ?? 'Registration successful!',
          
        );
      } else {
        return LoginResponse(
          success: false,
          message: responseData['message'] ?? 'Registration failed',
          error: responseData['error'] ?? 'Unknown error',
        );
      }
    } on http.ClientException catch (e) {
      return LoginResponse(
        success: false,
        message: 'Network error: ${e.message}',
        error: 'NETWORK_ERROR',
      );
    } on FormatException {
      return LoginResponse(
        success: false,
        message: 'Invalid server response',
        error: 'FORMAT_ERROR',
      );
    } on TimeoutException {
      return LoginResponse(
        success: false,
        message: 'Request timed out. Please try again.',
        error: 'TIMEOUT_ERROR',
      );
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'An unexpected error occurred',
        error: 'UNKNOWN_ERROR',
      );
    }
  }

  // Login method
  Future<LoginResponse> login(LoginRequest loginRequest) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(loginRequest.toJson()),
      ).timeout(_timeout);

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
       
        final token = responseData['token'] ?? responseData['accessToken'];
        if (token != null) {
          
        }

        return LoginResponse(
          success: true,
          message: responseData['message'] ?? 'Login successful!',
          token: token,
          user: responseData['user'] ?? responseData['data'],
        );
      } else {
        return LoginResponse(
          success: false,
          message: responseData['message'] ?? 'Login failed',
          error: responseData['error'] ?? 'Invalid credentials',
        );
      }
    } on http.ClientException catch (e) {
      return LoginResponse(
        success: false,
        message: 'Network error: ${e.message}',
        error: 'NETWORK_ERROR',
      );
    } on FormatException {
      return LoginResponse(
        success: false,
        message: 'Invalid server response',
        error: 'FORMAT_ERROR',
      );
    } on TimeoutException {
      return LoginResponse(
        success: false,
        message: 'Request timed out. Please try again.',
        error: 'TIMEOUT_ERROR',
      );
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'An unexpected error occurred',
        error: 'UNKNOWN_ERROR',
      );
    }
  }

  Future<LoginResponse> forgotPassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/auth/updatepassword'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      ).timeout(_timeout);

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return LoginResponse(
          success: true,
          message: responseData['message'] ?? 'Password updated successfully',
        );
      } else {
        return LoginResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to update password',
          error: responseData['error'] ?? 'Unknown error',
        );
      }
    } on http.ClientException catch (e) {
      return LoginResponse(
        success: false,
        message: 'Network error: ${e.message}',
        error: 'NETWORK_ERROR',
      );
    } on FormatException {
      return LoginResponse(
        success: false,
        message: 'Invalid server response',
        error: 'FORMAT_ERROR',
      );
    } on TimeoutException {
      return LoginResponse(
        success: false,
        message: 'Request timed out. Please try again.',
        error: 'TIMEOUT_ERROR',
      );
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'An unexpected error occurred',
        error: 'UNKNOWN_ERROR',
      );
    }
  }
}
