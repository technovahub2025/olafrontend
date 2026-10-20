class UserModel {
  String id;
  String name;
  String email;
  String phone;
  String profileImage;
  DateTime createdAt;
  bool isActive;
  int totalRides;
  double totalSpent;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.createdAt,
    required this.isActive,
    required this.totalRides,
    required this.totalSpent,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profileImage: json['profileImage']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      totalRides: (json['totalRides'] is int) ? json['totalRides'] : int.tryParse(json['totalRides']?.toString() ?? '0') ?? 0,
      totalSpent: (json['totalSpent'] is num) ? json['totalSpent'].toDouble() : double.tryParse(json['totalSpent']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'totalRides': totalRides,
      'totalSpent': totalSpent,
    };
  }
}
