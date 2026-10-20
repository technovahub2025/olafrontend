import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/adminmodel/profilemodel.dart';

import 'package:url_launcher/url_launcher.dart';
class ProfileService {
  static const String baseUrl = "https://ola-7ii1.onrender.com/api/admin";




static Future<void> sendSms(String phone, String name) async {
  final message = "Hello ${name}, this is your login credential 🚖\nPhone: ${phone}";
  final Uri smsUri = Uri.parse(
    "sms:$phone?body=${Uri.encodeComponent(message)}",
  );

  if (await canLaunchUrl(smsUri)) {
    await launchUrl(smsUri);
  } else {
    throw "Cannot open SMS app";
  }
}

  // 🔹 GET ALL DRIVERS (filtered by role 'driver')
  static Future<List<profilemodel>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/getall'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List list = decoded['data'];

      // Filter only users with role 'driver'
      return list
          .map((e) => profilemodel.fromJson(e))
          .where((user) => user.role == "driver")
          .toList();
    } else {
      throw Exception("Failed to fetch drivers");
    }
  }


  // 🔹 ADD DRIVER
 static Future<void> addUser(Map<String, dynamic> userData) async {
  final response = await http.post(
    Uri.parse('$baseUrl/addprofile'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "name": userData['name'],
      "phone": userData['phone'],
      "price": userData['price'],
      "rating": userData['rating'],
      "role": userData['role'],
      "email": "driver${DateTime.now().millisecondsSinceEpoch}@gmail.com",
      "password": "12345678",
      "experience": userData['experience'],
      "image": userData['image'],
      "captcha": "2345"
    }),
  );

  if (response.statusCode == 201) {
    // ✅ Send SMS after success
    await sendSms(
      userData['phone'],
      userData['name'],
    );
  } else {
    final error = json.decode(response.body);
    throw Exception(error['message']);
  }
}

  // 🔹 UPDATE DRIVER
  static Future<void> updateUser(
    String id,
    Map<String, dynamic> userData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/editprofile/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "name": userData['name'],
        "phone": userData['phone'],
        "price": userData['price'],
        "rating": userData['rating'],
                "role":userData['role'],
        "experience": userData['experience'],
        "image": userData['image'],
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message']);
    }
  }

  // 🔹 DELETE DRIVER
  static Future<void> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/deleteprofile/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message']);
    }
  }
}
