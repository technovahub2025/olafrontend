class UserModel {
  final String? id;
  final String name;
  final String email;
 
  final String password;
  

  UserModel({
    this.id,
    required this.name,
    required this.email,
   
    required this.password,
  
  });

  // Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
     
      'password': password,
     
    };
  }

  // Create from JSON for API response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
    
      password: json['password'] ?? '',
     
    );
  }
}

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      error: json['error'],
    );
  }
}