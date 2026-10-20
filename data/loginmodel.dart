class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
    this.error,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'] ?? json['accessToken'],
      user: json['user'] ?? json['data'],
      error: json['error'],
    );
  }
}