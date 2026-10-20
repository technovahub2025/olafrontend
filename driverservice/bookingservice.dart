import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/tokenmagemet/drivertoken.dart';

class BookingService {
  static const String _baseUrl = 'https://ola-7ii1.onrender.com/api';
  static const List<String> _verifyCaptchaUrls = [
    'https://ola-7ii1.onrender.com/api/verifycaptcha',
   
  ];
  static const Duration _timeout = Duration(seconds: 30);

  // Verify OTP/captcha before driver proceeds with assigned ride.
  static Future<bool> verifyCaptcha({
    required String captcha,
  }) async {
    final otpValue = captcha.trim();
    if (otpValue.isEmpty) {
      throw Exception('Captcha/OTP is required');
    }
    final user = await SessionManager.getUserFromToken();
    final rawUser = user?['userData'] as Map<String, dynamic>?;
    final emailValue = rawUser?['email']?.toString().trim();

    Exception? lastError;

    for (final endpoint in _verifyCaptchaUrls) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'captcha': otpValue,
                if (emailValue != null && emailValue.isNotEmpty) 'email': emailValue,
              }),
            )
            .timeout(_timeout);

        print('DEBUG: Verify captcha - Endpoint: $endpoint');
        print('DEBUG: Verify captcha - Status: ${response.statusCode}');
        print('DEBUG: Verify captcha - Body: ${response.body}');

        final Map<String, dynamic>? responseData = response.body.isNotEmpty
            ? json.decode(response.body) as Map<String, dynamic>
            : null;

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final dynamic successField = responseData?['success'];
          if (successField == null || successField == true) {
            return true;
          }
          lastError = Exception(
            responseData?['message'] ?? 'Captcha verification failed',
          );
          continue;
        }

        lastError = Exception(
          responseData?['message'] ?? 'Captcha verification failed',
        );
      } catch (e) {
        lastError = Exception('Error verifying captcha: $e');
      }
    }

    throw lastError ?? Exception('Captcha verification failed');
  }

  // Get specific booking by ID
  static Future<Booking?> getBookingById(String bookingId) async {
    try {
      final token = await SessionManager.getToken();
      print('DEBUG: Retrieved token: $token');
      
      if (token == null || token.isEmpty) {
        print('DEBUG: No token found!');
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/booking/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('DEBUG: Full response: $responseData');
        
        
        return Booking.fromJson(responseData);
      } else {
        throw Exception('Failed to load booking:');
      }
    } catch (e) {
      throw Exception('Error fetching booking: $e');
    }
  }

  // Get driver's assigned bookings (for listing)
  static Future<List<Booking>> getDriverBookings() async {
    try {
      final token = await SessionManager.getToken();
      print('DEBUG: Retrieved token: $token');
      
      if (token == null || token.isEmpty) {
        print('DEBUG: No token found!');
        throw Exception('No auth token found');
      }

      // Get user data to extract driver ID
      final userData = await SessionManager.getUserFromToken();
      final driverId = userData?['id']?.toString();
      final rawUser = userData?['userData'] as Map<String, dynamic>?;
      final driverName = rawUser?['name']?.toString().trim() ?? '';
      
      print('DEBUG: Driver ID: $driverId');
      print('DEBUG: Driver name: $driverName');
      print('DEBUG: User data: $userData');
      
      if (driverId == null || driverId.isEmpty) {
        throw Exception('Driver ID not found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/booking/driver/$driverId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('DEBUG: Full response: $responseData');
        
        // Backend returns { success: true, bookings: [...] }
        final List<dynamic> dataList = responseData['bookings'] ?? [];
        print('DEBUG: Bookings count: ${dataList.length}');
        
        if (dataList.isEmpty) {
          print('DEBUG: No bookings found in response!');
          return [];
        }
        
      final bookings = dataList.map((item) {
        print('DEBUG: Parsing booking item: $item');
        final booking = Booking.fromJson(item);
        print('DEBUG: Parsed booking ID: "${booking.id}"');
        return booking;
      }).toList();

      print('DEBUG: Final bookings list: $bookings');
      return bookings;
      } else {
        throw Exception('Failed to load bookings: ${responseData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  // Update booking status
  static Future<bool> updateBookingStatus(
    String bookingId,
    String status, {
    String? bookingDriverId,
    String? bookingDriverName,
  }) async {
    try {
      print('DEBUG: Update status - Input bookingId: "$bookingId"');
      print('DEBUG: Update status - Input status: "$status"');
      
      if (bookingId.isEmpty) {
        print('DEBUG: Update status - Booking ID is empty!');
        throw Exception('Booking ID is empty');
      }
      
      final token = await SessionManager.getToken();
      print('DEBUG: Update status - Retrieved token: $token');
      
      if (token == null || token.isEmpty) {
        print('DEBUG: Update status - No token found!');
        throw Exception('No auth token found');
      }

      final userData = await SessionManager.getUserFromToken();
      final driverId = userData?['id']?.toString() ?? '';
      final rawUser = userData?['userData'] as Map<String, dynamic>?;
      final driverName = rawUser?['name']?.toString().trim() ?? '';

      if (driverId.isEmpty) {
        throw Exception('Driver ID not found in session');
      }

      final hasBookingDriver =
          (bookingDriverId != null && bookingDriverId.isNotEmpty) ||
              (bookingDriverName != null && bookingDriverName.trim().isNotEmpty);

      if (hasBookingDriver) {
        final matchesById =
            bookingDriverId != null && bookingDriverId.isNotEmpty && bookingDriverId == driverId;
        final matchesByName = bookingDriverName != null &&
            bookingDriverName.trim().isNotEmpty &&
            driverName.isNotEmpty &&
            bookingDriverName.trim().toLowerCase() == driverName.toLowerCase();

        if (!matchesById && !matchesByName) {
          throw Exception('This ride is booked for another driver');
        }
      }
      
      final url = '$_baseUrl/booking/status/$bookingId';
      print('DEBUG: Update status - URL: $url');
      print('DEBUG: Update status - Status: $status');
      print('DEBUG: Update status - Driver ID: $driverId');
      print('DEBUG: Update status - Booking Driver ID: $bookingDriverId');

      // Add completion timestamp if status is completed
      Map<String, dynamic> requestBody = {
        'status': status,
        'driverId': driverId,
      };
      if (bookingDriverId != null && bookingDriverId.isNotEmpty) {
        requestBody['bookingDriverId'] = bookingDriverId;
      }
      if (bookingDriverName != null && bookingDriverName.isNotEmpty) {
        requestBody['bookingDriverName'] = bookingDriverName;
      }
      if (status == 'completed') {
        requestBody['completedAt'] = DateTime.now().toIso8601String();
        print('DEBUG: Update status - Added completion timestamp');
      }

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(_timeout);

      print('DEBUG: Update status - Response status: ${response.statusCode}');
      print('DEBUG: Update status - Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        print('DEBUG: Update status - Status updated successfully');
        return true;
      } else {
        throw Exception('Failed to update booking: ${responseData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('DEBUG: Update status - Error: $e');
      throw Exception('Error updating booking: $e');
    }
  }
}

class Booking {
  final String id;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final String pickupLocation;
  final String dropoffLocation;
  final Map<String, dynamic>? pickupCoordinates;
  final Map<String, dynamic>? dropoffCoordinates;
  final String driverId;
  final String assignedDriverId;
  final String driverName;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.pickupCoordinates,
    this.dropoffCoordinates,
    required this.driverId,
    required this.assignedDriverId,
    required this.driverName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    print('DEBUG: Booking.fromJson - Raw JSON: $json');
    
    // MongoDB returns _id as an object, convert to string
    String id = '';
    if (json['_id'] != null) {
      if (json['_id'] is Map) {
        final idMap = json['_id'] as Map<String, dynamic>;
        id = idMap['oid']?.toString() ?? 
             idMap['_id']?.toString() ?? 
             idMap['id']?.toString() ?? '';
      } else {
        id = json['_id'].toString();
      }
    }
    if (id.isEmpty && json['id'] != null) {
      id = json['id'].toString();
      print('DEBUG: Booking.fromJson - Used fallback id: "$id"');
    }
    
    print('DEBUG: Booking.fromJson - Final ID: "$id"');
    
    // Handle Passenger / User Data
    String passengerName = json['customerName']?.toString() ?? 'Unknown User';
    String passengerPhone = json['customerPhone']?.toString() ?? '';
    String passengerId = json['userId']?.toString() ?? '';

    // If userId happens to be a Map (populated), we can extract from it, but customerName is reliable
    if (json['userId'] is Map) {
      final userMap = json['userId'] as Map<String, dynamic>;
      if (userMap['name'] != null) passengerName = userMap['name'].toString();
      if (userMap['phone'] != null) passengerPhone = userMap['phone'].toString();
      
      if (userMap['_id'] != null) {
         passengerId = userMap['_id'].toString();
      } else if (userMap['id'] != null) {
         passengerId = userMap['id'].toString();
      }
    } else if (json['passengerId'] != null) {
      passengerId = json['passengerId'].toString();
    }

    return Booking(
      id: id,
      passengerId: passengerId,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      pickupLocation: json['pickupLocation']?.toString() ?? '',
      dropoffLocation: json['dropoffLocation']?.toString() ?? '',
      pickupCoordinates: json['pickupCoordinates'] as Map<String, dynamic>?,
      dropoffCoordinates: json['dropoffCoordinates'] as Map<String, dynamic>?,
      driverId: json['driverId']?.toString() ?? '',
      assignedDriverId: json['assignedDriverId']?.toString() ??
          json['assigned_driver_id']?.toString() ??
          json['assignedDriver']?['_id']?.toString() ??
          '',
      driverName: json['driverName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      createdAt: _parseToLocalDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseToLocalDateTime(json['updatedAt']),
    );
  }

  static DateTime? _parseToLocalDateTime(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;
    return parsed.toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'driverId': driverId,
      'assignedDriverId': assignedDriverId,
      'driverName': driverName,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
