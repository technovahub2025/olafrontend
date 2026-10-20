// models/user_model.dart
class profilemodel {
  String id;
  String name;
  String image;
  String pricePerKm;
  String discount;
  String experience;
  String rating;

  profilemodel({
    required this.id,
    required this.name,
    required this.image,
    required this.pricePerKm,
    required this.discount,
    required this.experience,
    required this.rating,
  });

  factory profilemodel.fromJson(Map<String, dynamic> json) {
    return profilemodel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      pricePerKm: json['pricePerKm']?.toString() ?? '',
      discount: json['discount']?.toString() ?? '',
      experience: json['experience']?.toString() ?? '',
      rating: json['rating']?.toString() ?? '',
    );
  }
}
