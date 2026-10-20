import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/drivermodel/loginmodel.dart';
import 'package:taxiuuse/tokenmagemet/drivertoken.dart';

class LoginService {
  static const String _baseUrl = 'https://ola-7ii1.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 30);

 
  Future<LoginResponse> login(LoginRequest loginRequest) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/driverlogin'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(loginRequest.toJson()),
      ).timeout(_timeout);

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
      
        final token = responseData['token'] ?? responseData['accessToken'];
        print('DEBUG: Login token received: $token');
        
        if (token != null) {
          // Store token locally
          await SessionManager.saveToken(token);
          print('DEBUG: Token saved successfully');
        }

        // Store user data from login response
        final userData = responseData['user'] ?? responseData['data'];
        if (userData != null) {
          await SessionManager.saveUserData(userData);
        }

        return LoginResponse(
          success: true,
          message: responseData['message'] ?? 'Login successful!',
          token: token,
          user: userData,
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
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'An unexpected error occurred',
        error: 'UNKNOWN_ERROR',
      );
    }
  }

  
}