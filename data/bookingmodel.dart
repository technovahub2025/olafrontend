class BookingModel {
  final String? id;
  final String? driverId;
  final String? assignedDriverId;
  final String userName;
  final String? userEmail;
  final String userPhone;
  final String pickupAddress;
  final String dropAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final DateTime bookedDate;
  final String status;
  final String? driverName;
  final String? driverPhone;
  final double? price;

  BookingModel({
    this.id,
    this.driverId,
    this.assignedDriverId,
    required this.userName,
    this.userEmail,
    required this.userPhone,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.bookedDate,
    this.status = 'confirmed',
    this.driverName,
    this.driverPhone,
    this.price,
  });

  static DateTime _parseBookedDate(dynamic rawDate) {
    if (rawDate == null) return DateTime.now();
    final parsed = DateTime.tryParse(rawDate.toString());
    if (parsed == null) return DateTime.now();
    return parsed.toLocal();
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    String getString(List<String> keys) {
      for (final key in keys) {
        if (json[key] != null && json[key].toString().isNotEmpty) {
          return json[key].toString();
        }
      }
      return '';
    }

    double getCoord(String mainKey, String nestedKey, [List<String>? aliases]) {
      if (json[mainKey] != null) {
        return double.tryParse(json[mainKey].toString()) ?? 0.0;
      }

      if (aliases != null) {
        for (final alias in aliases) {
          if (json[alias] != null) {
            return double.tryParse(json[alias].toString()) ?? 0.0;
          }
        }
      }

      if (mainKey.toLowerCase().contains('pickup')) {
        final coords = json['pickupCoordinates'];

        if (coords is Map) {
          if (mainKey.endsWith('Lat')) {
            return double.tryParse(
                    (coords['lat'] ?? coords['latitude'])?.toString() ?? '') ??
                0.0;
          }
          if (mainKey.endsWith('Lng')) {
            return double.tryParse(
                    (coords['lng'] ?? coords['longitude'])?.toString() ?? '') ??
                0.0;
          }
        }
      }

      if (mainKey.toLowerCase().contains('drop')) {
        final coords = json['dropoffCoordinates'] ?? json['dropCoordinates'];

        if (coords is Map) {
          if (mainKey.endsWith('Lat')) {
            return double.tryParse(
                    (coords['lat'] ?? coords['latitude'])?.toString() ?? '') ??
                0.0;
          }
          if (mainKey.endsWith('Lng')) {
            return double.tryParse(
                    (coords['lng'] ?? coords['longitude'])?.toString() ?? '') ??
                0.0;
          }
        }
      }

      return 0.0;
    }

    double? _getPrice(Map<String, dynamic> json) {
      for (final key in ['price', 'fare', 'amount']) {
        final value = json[key];
        if (value != null) {
          return double.tryParse(value.toString());
        }
      }
      return null;
    }

    return BookingModel(
      id: json['_id']?.toString(),
      driverId: json['driverId']?.toString() ??
          json['driver']?['_id']?.toString() ??
          json['driver']?.toString(),
      assignedDriverId: json['assignedDriverId']?.toString() ??
          json['assigned_driver_id']?.toString() ??
          json['assignedDriver']?['_id']?.toString(),
      userName: getString(['userName', 'customerName', 'name']),
      userEmail: getString(['userEmail', 'customerEmail', 'email']).isEmpty
          ? null
          : getString(['userEmail', 'customerEmail', 'email']),
      userPhone: getString(['userPhone', 'customerPhone', 'phone']),
      pickupAddress: getString(['pickupAddress', 'pickupLocation', 'pickup']),
      dropAddress: getString(['dropAddress', 'dropoffLocation', 'drop']),
      pickupLat: getCoord('pickupLat', 'lat'),
      pickupLng: getCoord('pickupLng', 'lng'),
      dropLat: getCoord('dropLat', 'lat'),
      dropLng: getCoord('dropLng', 'lng'),
      bookedDate: _parseBookedDate(json['bookedDate']),
      status: json['status']?.toString() ?? 'confirmed',
      driverName: getString(['driverName', 'driver']),
      driverPhone: getString(['driverPhone']),
      price: _getPrice(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (driverId != null) 'driverId': driverId,
      if (assignedDriverId != null) 'assignedDriverId': assignedDriverId,
      'userName': userName,
      if (userEmail != null) 'userEmail': userEmail,
      'userPhone': userPhone,
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'bookedDate': bookedDate.toIso8601String(),
      'status': status,
      if (driverName != null) 'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      if (price != null) 'price': price,
    };
  }

  BookingModel copyWith({
    String? id,
    String? driverId,
    String? assignedDriverId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? pickupAddress,
    String? dropAddress,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    DateTime? bookedDate,
    String? status,
    String? driverName,
    String? driverPhone,
    double? price,
  }) {
    return BookingModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropAddress: dropAddress ?? this.dropAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      bookedDate: bookedDate ?? this.bookedDate,
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      price: price ?? this.price,
    );
  }
}
