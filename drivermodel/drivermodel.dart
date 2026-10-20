class UserModel {
  final String? id;
  final String? name;
  final String? phone;
  final String? role;
  final String? image;
  final int? experience;
  final double rating;
  final double? price;
  final bool isOnline;

  UserModel({
    this.id,
    this.name,
    this.phone,
    this.role,
    this.image,
    this.experience,
    this.rating = 0,
    this.price,
    this.isOnline = false, // 🔹 default OFFLINE
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      image: json['image']?.toString(),
      experience: json['experience'] is int
          ? json['experience'] as int
          : int.tryParse(json['experience']?.toString() ?? '0') ?? 0,
      rating: json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : 0,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      isOnline: json['isOnline'] ?? false,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? image,
    int? experience,
    double? rating,
    double? price,
    bool? isOnline,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      image: image ?? this.image,
      experience: experience ?? this.experience,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
