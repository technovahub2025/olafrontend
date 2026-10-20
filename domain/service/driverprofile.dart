// lib/data/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/data/driverprofilemodel.dart';
import 'package:taxiuuse/tokenmagemet/tokenstorage.dart';

class ApiService {
  static const String baseUrl = 'https://ola-7ii1.onrender.com/api/admin/getall';
  static final http.Client client = http.Client();

  Future<List<driverModel>> getAllUsers() async {
    try {
      
      final token = await SessionManager.getToken();

      final response = await client.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print("Token:${token}");
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => driverModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Token expired');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }
}
