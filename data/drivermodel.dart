// User model with null safety + online status
class UserModel {
  final String? id;
  final String? name;
  final String? phone;
  final double? price;
  final double? rating;
  final String? image;
  final String? driver;
  final int? experience;
  final bool isOnline; // 🔴 ONLINE / OFFLINE
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    this.name,
    this.phone,
    this.price,
    this.rating,
    this.image,
    this.driver,
    this.experience,
    this.createdAt,
    this.updatedAt,
    this.isOnline = false, // default OFFLINE
  });

  // ===============================
  // JSON → MODEL
  // ===============================
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      driver: json['driver']?.toString(),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      rating: json['rating'] != null
          ? (json['rating'] is int
              ? (json['rating'] as int).toDouble()
              : (json['rating'] is num
                  ? (json['rating'] as num).toDouble()
                  : 0.0))
          : 0.0,
      image: json['image']?.toString(),
      experience: json['experience'] != null
          ? (json['experience'] is int
              ? json['experience'] as int
              : int.tryParse(json['experience'].toString()) ?? 0)
          : 0,
      isOnline: json['isOnline'] ?? false, // 🔴 backend value
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  // ===============================
  // COPY WITH (for socket updates)
  // ===============================
  UserModel copyWith({
    bool? isOnline,
  }) {
    return UserModel(
      id: id,
      name: name,
      phone: phone,
      price: price,
      rating: rating,
      image: image,
      driver: driver,
      experience: experience,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
