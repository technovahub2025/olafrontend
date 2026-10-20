import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/data/bookingmodel.dart';
import 'package:taxiuuse/core/config.dart';
import 'package:taxiuuse/tokenmagemet/tokenstorage.dart';

class BookingService {
  static String get baseUrl => '${AppConfig.apiBaseUrl}/api';
  static String get adminBaseUrl => '${AppConfig.apiBaseUrl}/api/admin';
  static final RegExp _objectIdRegex = RegExp(r'^[a-fA-F0-9]{24}$');
  static final RegExp _objectIdInTextRegex = RegExp(r'[a-fA-F0-9]{24}');

  Future<Map<String, String>> _getHeaders() async {
    final token = await SessionManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String? _extractUserIdFromToken(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;

    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decodedPayload = utf8.decode(base64Url.decode(normalized));
      final payloadJson = json.decode(decodedPayload);
      if (payloadJson is Map<String, dynamic>) {
        final tokenUserId = _extractUserIdFromMap(payloadJson);
        if (tokenUserId != null && tokenUserId.trim().isNotEmpty) {
          return tokenUserId;
        }
      }
    } catch (_) {
      // Ignore malformed token payload.
    }
    return null;
  }

  String? _extractUserIdFromMap(Map<String, dynamic> map) {
    final oid = map[r'$oid'] ?? map['oid'];
    final oidNormalized = _normalizeObjectId(oid);
    if (oidNormalized != null && oidNormalized.isNotEmpty) {
      return oidNormalized;
    }

    final direct = map['_id'] ?? map['id'] ?? map['userId'] ?? map['user'];
    final directNormalized = _normalizeObjectId(direct);
    if (directNormalized != null && directNormalized.isNotEmpty) {
      return directNormalized;
    }

    for (final key in ['user', 'data', 'profile', 'account']) {
      final nested = map[key];
      if (nested is Map<String, dynamic>) {
        final nestedId = _extractUserIdFromMap(nested);
        if (nestedId != null && nestedId.trim().isNotEmpty) {
          return nestedId;
        }
      }
      if (nested is List) {
        for (final item in nested) {
          final listId = _normalizeObjectId(item);
          if (listId != null && listId.isNotEmpty) {
            return listId;
          }
        }
      }
    }
    return null;
  }

  String? _normalizeObjectId(dynamic value) {
    if (value == null) return null;

    if (value is Map<String, dynamic>) {
      return _extractUserIdFromMap(value);
    }

    final text = value.toString().trim();
    if (text.isEmpty) return null;
    if (_objectIdRegex.hasMatch(text)) return text;

    final match = _objectIdInTextRegex.firstMatch(text);
    return match?.group(0);
  }

  /* ===============================
      CREATE BOOKING
  =============================== */
  Future<BookingModel> createBooking({
    required String pickupLocation,
    required String dropoffLocation,
    required Map<String, double> pickupCoordinates,
    required Map<String, double> dropoffCoordinates,
    double? price,
    required String customerName,
    required String customerPhone,
    String? driverId,
    String? driverName,
  }) async {
    final headers = await _getHeaders();
    final token = await SessionManager.getToken();
    String? tokenUserId = _extractUserIdFromToken(token);
    tokenUserId = _normalizeObjectId(tokenUserId);

    if (tokenUserId == null || tokenUserId.trim().isEmpty) {
      tokenUserId = _normalizeObjectId(await SessionManager.getUserId());
    }

    if (tokenUserId == null || tokenUserId.trim().isEmpty) {
      final userDataJson = await SessionManager.getUserData();
      if (userDataJson != null && userDataJson.trim().isNotEmpty) {
        try {
          final decoded = json.decode(userDataJson);
          if (decoded is Map<String, dynamic>) {
            tokenUserId = _extractUserIdFromMap(decoded);
          } else {
            tokenUserId = _normalizeObjectId(decoded);
          }
        } catch (_) {
          // Ignore malformed local user data.
        }
      }
    }
    final normalizedPickup = pickupLocation.trim();
    final normalizedDropoff = dropoffLocation.trim();
    final normalizedName = customerName.trim();
    final normalizedPhone = customerPhone.trim();
    final effectiveUserId = tokenUserId?.trim() ?? '';

    if (normalizedPickup.isEmpty ||
        normalizedDropoff.isEmpty ||
        normalizedName.isEmpty ||
        normalizedPhone.isEmpty) {
      throw Exception(
        'Missing required booking data (pickup/drop/name/phone).',
      );
    }

    if (!_objectIdRegex.hasMatch(effectiveUserId)) {
      throw Exception(
        'Invalid user id for booking. Please login again.',
      );
    }

    if (price == null || price <= 0) {
      throw Exception('Invalid price for booking.');
    }

    final payload = {
      "userId": effectiveUserId,
      "pickupLocation": normalizedPickup,
      "dropoffLocation": normalizedDropoff,
      "customerName": normalizedName,
      "customerPhone": normalizedPhone,
      "pickupCoordinates": pickupCoordinates,
      "dropoffCoordinates": dropoffCoordinates,
      "price": price,
      "distance": 0,
      "estimatedTime": 0,
      "notes": "",
      "paymentMethod": "cash",
    };

    if (driverId != null && driverId.trim().isNotEmpty) {
      payload["driverId"] = driverId.trim();
      payload["assignedDriverId"] = driverId.trim();
      payload["driver"] = driverId.trim();
    }
    if (driverName != null && driverName.trim().isNotEmpty) {
      payload["driverName"] = driverName.trim();
      payload["assignedDriverName"] = driverName.trim();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/booking/create'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final createdBooking = BookingModel.fromJson(jsonDecode(response.body));

      if (createdBooking.driverId?.isNotEmpty ?? false) {
        return createdBooking;
      }

      if (driverId != null && driverId.trim().isNotEmpty) {
        final bookingId = createdBooking.id?.trim() ?? '';
        if (bookingId.isNotEmpty) {
          try {
            final assignResponse = await http.put(
              Uri.parse('$adminBaseUrl/bookings/$bookingId/assign'),
              headers: headers,
              body: jsonEncode({
                'driverId': driverId.trim(),
                'assignedDriverId': driverId.trim(),
                'driver': driverId.trim(),
                'driverName': driverName?.trim(),
                'assignedDriverName': driverName?.trim(),
                'assignedAt': DateTime.now().toIso8601String(),
                'status': 'assigned',
              }),
            );

            print('DEBUG: Assign response status: ${assignResponse.statusCode}');
            print('DEBUG: Assign response body: ${assignResponse.body}');

            final refreshed = await http.get(
              Uri.parse('$baseUrl/booking/$bookingId'),
              headers: headers,
            );

            if (refreshed.statusCode == 200) {
              return BookingModel.fromJson(jsonDecode(refreshed.body));
            }
          } catch (_) {
            // Fall back to the created booking if assignment refresh fails.
          }
        }
      }

      return createdBooking;
    } else {
      throw Exception(response.body);
    }
  }

  /* ===============================
      GET ALL BOOKINGS
  =============================== */
  Future<List<BookingModel>> getAllBookings() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/bookings'),
      headers: headers,
    );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    
    final List bookingsJson =
        decoded is Map ? decoded['bookings'] : decoded;

    return bookingsJson
        .map((e) => BookingModel.fromJson(e))
        .toList();
  } else {
    throw Exception("Failed to load bookings");
  }
}

/* ===============================
    GET ALL BOOKING DATA (DASHBOARD)
================================ */
Future<Map<String, dynamic>> getAllBookingData() async {
  try {
    // 1️⃣ Get all bookings
    final allBookings = await getAllBookings();

    // 2️⃣ Filter by status
    final pendingBookings =
        allBookings.where((b) => b.status == 'pending').toList();

    final assignedBookings =
        allBookings.where((b) => b.status == 'assigned').toList();

    final ongoingBookings =
        allBookings.where((b) => b.status == 'ongoing').toList();

    final completedBookings =
        allBookings.where((b) => b.status == 'completed').toList();

    final cancelledBookings =
        allBookings.where((b) => b.status == 'cancelled').toList();

    // 3️⃣ Today’s bookings
    final today = DateTime.now();
    final todayBookings = allBookings.where((b) {
      final bookedLocal = b.bookedDate.toLocal();
      return bookedLocal.year == today.year &&
          bookedLocal.month == today.month &&
          bookedLocal.day == today.day;
    }).toList();

    // 4️⃣ Return dashboard-style data
    return {
      "allBookings": allBookings,
      "pendingBookings": pendingBookings,
      "assignedBookings": assignedBookings,
      "ongoingBookings": ongoingBookings,
      "completedBookings": completedBookings,
      "cancelledBookings": cancelledBookings,
      "todayBookings": todayBookings,

      // counts
      "totalCount": allBookings.length,
      "pendingCount": pendingBookings.length,
      "assignedCount": assignedBookings.length,
      "ongoingCount": ongoingBookings.length,
      "completedCount": completedBookings.length,
      "cancelledCount": cancelledBookings.length,
      "todayCount": todayBookings.length,
    };
  } catch (e) {
    throw Exception("Failed to load booking dashboard data: $e");
  }
}

  /* ===============================
      GET BOOKING BY ID
  =============================== */
  Future<BookingModel> getBookingById(String bookingId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/booking/$bookingId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return BookingModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Booking not found");
    }
  }

  /* ===============================
      GET USER BOOKINGS
  =============================== */
  Future<List<BookingModel>> getUserBookings(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/booking/user/$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => BookingModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load user bookings");
    }
  }

  /* ===============================
      GET DRIVER BOOKINGS
  =============================== */
  Future<List<BookingModel>> getDriverBookings(String driverId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/booking/driver/$driverId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => BookingModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load driver bookings");
    }
  }

  /* ===============================
      UPDATE BOOKING STATUS
  =============================== */
  Future<BookingModel> updateBookingStatus(
      String bookingId, String status) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/booking/status/$bookingId'),
      headers: headers,
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode == 200) {
      return BookingModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to update status");
    }
  }

  /* ===============================
      CANCEL BOOKING
  =============================== */
  Future<void> cancelBooking(String bookingId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/booking/cancel/$bookingId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to cancel booking");
    }
  }

  /* ===============================
      PROCESS PAYMENT
  =============================== */
  Future<Map<String, dynamic>> processPayment({
    required String name,
    required String email,
    required String phone,
    required String paymentMethod,
    required String bookingId,
    required double amount,
    String? pickupAddress,
    String? dropAddress,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/payment'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'paymentMethod': paymentMethod,
        'bookingId': bookingId,
        'amount': amount,
        'pickupAddress': pickupAddress,
        'dropAddress': dropAddress,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to process payment: ${response.body}");
    }
  }

 

}
