class BookingModel {
  String id;
  String userId;
  String userName;
  String userPhone;
  String pickupAddress;
  String dropoffAddress;
  String driverId;
  String driverName;
  String driverPhone;
  String status; // pending, assigned, completed, cancelled
  DateTime createdAt;
  DateTime? assignedAt;
  DateTime? completedAt;
  double fare;
  String paymentStatus;
  String? notes;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.status,
    required this.createdAt,
    this.assignedAt,
    this.completedAt,
    required this.fare,
    required this.paymentStatus,
    this.notes,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userPhone: json['userPhone']?.toString() ?? '',
      pickupAddress: json['pickupAddress']?.toString() ?? '',
      dropoffAddress: json['dropoffAddress']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      driverName: json['driverName']?.toString() ?? '',
      driverPhone: json['driverPhone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      assignedAt: json['assignedAt'] != null ? DateTime.tryParse(json['assignedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
      fare: (json['fare'] is num) ? json['fare'].toDouble() : double.tryParse(json['fare']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'fare': fare,
      'paymentStatus': paymentStatus,
      'notes': notes,
    };
  }
}
