import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/data/drivermodel.dart';
import 'package:taxiuuse/data/registermodel.dart' hide UserModel;

class RegisterService {
  static const String _baseUrl = 'https://ola-7ii1.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 30);

  Future<ApiResponse> register(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(user),
      ).timeout(_timeout);

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Registration successful!',
          data: responseData['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Registration failed',
          error: responseData['error'] ?? 'Unknown error',
        );
      }
    } on http.ClientException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.message}',
        error: 'NETWORK_ERROR',
      );
    } on FormatException {
      return ApiResponse(
        success: false,
        message: 'Invalid server response',
        error: 'FORMAT_ERROR',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'An unexpected error occurred',
        error: 'UNKNOWN_ERROR',
      );
    }
  }
}

