// model/profilemodel.dart
class profilemodel {
  String id;
  String name;
  String image;
  int price;
  String phone;
  String experience;
 String ?role;
  double rating;

  profilemodel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
  required this.role,
    required this.phone,
    required this.experience,
    required this.rating,
  });

  // Copy constructor
  profilemodel copyWith({
    String? id,
    String? name,
    String? image,
    int? price,
    String? phone,
    String? experience,
  
    double? rating,
  }) {
    return profilemodel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
     role: role,
      phone: phone ?? this.phone,
      experience: experience ?? this.experience,
      rating: rating ?? this.rating,
    );
  }

  factory profilemodel.fromJson(Map<String, dynamic> json) {
    return profilemodel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      role: json['role']?.toString(),
      price: (json['price'] is int)
          ? json['price']
          : int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      phone: json['phone']?.toString() ?? '',
      experience: json['experience']?.toString() ?? '',
      rating: (json['rating'] is num)
          ? json['rating'].toDouble()
          : double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
   'role':role,
      'image': image,
      'price': price,
      'phone': phone,
      'experience': experience,
      'rating': rating,
    };
  }
}