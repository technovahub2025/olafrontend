import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/data/drivermodel.dart';
import 'package:taxiuuse/tokenmagemet/tokenstorage.dart';

class ProfileService {
  final String baseUrl = 'https://ola-7ii1.onrender.com/api/admin/role'; // Fixed: added /api
  
  Future<List<UserModel>> getAllUsers() async {
    try {
      final token = await SessionManager.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl'), // Added role query parameter
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print("token: $token");
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> dataList = responseData['data']; // This is correct
          return dataList.map((item) => UserModel.fromJson(item)).toList();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
}