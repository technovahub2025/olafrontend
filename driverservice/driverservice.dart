import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/data/drivermodel.dart';
import 'package:taxiuuse/tokenmagemet/drivertoken.dart';

class ProfileService {
  // 🔴 Replace with your machine's local IP if testing on mobile
  static const String baseUrl = 'https://ola-7ii1.onrender.com';

  // ===============================
  // GET ALL USERS
  // ===============================
  Future<List<UserModel>> getAllUsers() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/role'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> dataList = responseData['data'];
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
