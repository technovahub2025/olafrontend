import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/data/bookingmodel.dart';
import 'package:taxiuuse/data/registermodel.dart';


class BookingService {
  static const String baseUrl = "https://ola-7ii1.onrender.com/api/admin";

  // Get all bookings
  static Future<List<BookingModel>> getAllBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List list = decoded['data'] ?? [];
      return list.map((e) => BookingModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch bookings");
    }
  }

  // Get bookings by status
  static Future<List<BookingModel>> getBookingsByStatus(String status) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/status/$status'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List list = decoded['data'] ?? [];
      return list.map((e) => BookingModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch bookings by status");
    }
  }

  // Update booking status
  static Future<void> updateBookingStatus(String bookingId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/status'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to update booking status');
    }
  }

  // Assign driver to booking
  static Future<void> assignDriver(String bookingId, String driverId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/assign'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'driverId': driverId,
        'assignedAt': DateTime.now().toIso8601String(),
        'status': 'assigned',
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to assign driver');
    }
  }

  // Get booking statistics
  static Future<Map<String, int>> getBookingStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/stats'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return {
        'total': decoded['total'] ?? 0,
        'pending': decoded['pending'] ?? 0,
        'assigned': decoded['assigned'] ?? 0,
        'completed': decoded['completed'] ?? 0,
        'cancelled': decoded['cancelled'] ?? 0,
      };
    } else {
      throw Exception("Failed to fetch booking statistics");
    }
  }

  // Get all users (filtered by role 'user')
  static Future<List<UserModel>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/getall'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List list = decoded['data'] ?? [];
      // Filter only users with role 'user'
      final usersList = list.where((user) => user['role'] == 'user').toList();
      return usersList.map((e) => UserModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch users");
    }
  }

  // Get user statistics
  static Future<Map<String, int>> getUserStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/stats'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return {
        'total': decoded['total'] ?? 0,
        'active': decoded['active'] ?? 0,
        'inactive': decoded['inactive'] ?? 0,
      };
    } else {
      throw Exception("Failed to fetch user statistics");
    }
  }

  // Get driver statistics
  static Future<Map<String, int>> getDriverStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/drivers/stats'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return {
        'total': decoded['total'] ?? 0,
        'active': decoded['active'] ?? 0,
        'inactive': decoded['inactive'] ?? 0,
      };
    } else {
      throw Exception("Failed to fetch driver statistics");
    }
  }
}
