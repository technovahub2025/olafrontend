

import 'package:taxiuuse/adminmodel/authmodel.dart';

class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final String? token;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'] ?? json['accessToken'] ?? json['authToken'],
    );
  }

  // Helper method for successful responses
  static AuthResponse successResponse({
    required String message,
    User? user,
    String? token,
  }) {
    return AuthResponse(
      success: true,
      message: message,
      user: user,
      token: token,
    );
  }

  // Helper method for error responses
  static AuthResponse errorResponse(String message) {
    return AuthResponse(
      success: false,
      message: message,
    );
  }
}