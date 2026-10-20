class User {
 
  final String name;
  final String email;
  // final String? token;
  final String password;

  User({

    required this.name,
    required this.email,
    required this.password,
    // this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
     
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      // token: json['token'] ?? json['accessToken'],
    );
  }

  Map<String, dynamic> toJson() => {

    'name': name,
    'email': email,
    'password': password,
    // 'token': token,
  };
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}