// lib/data/models/user_model.dart
class driverModel {
  final String name;
  final String email;
  final double discount;
  final double rating;
  final int experience;
  final String image;
  final double pricePerKm;
  final String phone;

  driverModel({
    required this.name,
    required this.email,
    required this.discount,
    required this.rating,
    required this.image,
    required this.experience,
    required this.pricePerKm,
    required this.phone,
  });

  factory driverModel.fromJson(Map<String, dynamic> json) {
    return driverModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      image: json['image']?? ' ',
      discount: (json['discount'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      phone: json['phone'],
      experience: json['experience'] ?? 0,
      pricePerKm: (json['pricePerKm'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'discount': discount,
    'rating': rating,
    'experience': experience,
    'pricePerKm': pricePerKm,
  };
}