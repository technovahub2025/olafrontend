import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/tokenmagemet/drivertoken.dart';

class DriverProfileService {
  static const String _baseUrl = 'https://ola-7ii1.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 30);

  // Get driver profile
  static Future<DriverProfile> getProfile() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/driver/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return DriverProfile.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to load profile: ${responseData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  // Update driver profile
  static Future<DriverProfile> updateProfile({
    String? name,
    String? phone,
    String? vehicleNumber,
    String? profileImagePath,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final Map<String, String> fields = {};
      if (name != null) fields['name'] = name;
      if (phone != null) fields['phone'] = phone;
      if (vehicleNumber != null) fields['vehicleNumber'] = vehicleNumber;

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/driver/profile'),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add image if provided
      if (profileImagePath != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profileImage', profileImagePath),
        );
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return DriverProfile.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to update profile: ${responseData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}

class DriverProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String vehicleNumber;
  final String? profileImage;
  final bool isOnline;
  final DateTime lastSeen;

  DriverProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleNumber,
    this.profileImage,
    required this.isOnline,
    required this.lastSeen,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      isOnline: json['isOnline'] ?? false,
      lastSeen: DateTime.tryParse(json['lastSeen'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleNumber': vehicleNumber,
      'profileImage': profileImage,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }
}
