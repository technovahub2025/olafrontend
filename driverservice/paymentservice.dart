import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/tokenmagemet/drivertoken.dart';

class PaymentService {
  static const String _baseUrl = 'https://ola-7ii1.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 30);

  // Process payment for a completed booking
  static Future<Map<String, dynamic>> processPayment(
    String bookingId, 
    String paymentMethod, // 'cash', 'card', 'wallet'
    {double? amount}
  ) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      print('DEBUG: Processing payment - Booking ID: $bookingId');
      print('DEBUG: Processing payment - Method: $paymentMethod');

      final response = await http.post(
        Uri.parse('$_baseUrl/booking/payment/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'paymentMethod': paymentMethod,
          'amount': amount,
          'status': 'paid',
        }),
      ).timeout(_timeout);

      print('DEBUG: Payment response status: ${response.statusCode}');
      print('DEBUG: Payment response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Payment processed successfully',
          'data': responseData['data'] ?? {},
        };
      } else {
        throw Exception('Payment failed: ${responseData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('DEBUG: Payment error: $e');
      throw Exception('Error processing payment: $e');
    }
  }

  // Get payment status for a booking
  static Future<Map<String, dynamic>> getPaymentStatus(String bookingId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/booking/payment/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'paymentStatus': responseData['paymentStatus'] ?? 'pending',
          'paymentMethod': responseData['paymentMethod'] ?? 'cash',
          'amount': responseData['amount'] ?? 0,
        };
      } else {
        throw Exception('Failed to get payment status: ${responseData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error getting payment status: $e');
    }
  }
}
