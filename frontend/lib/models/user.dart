class User {
  final String id;
  final String? name;
  final String email;
  final Map<String, dynamic>? dietaryGoals;

  User({
    required this.id,
    this.name,
    required this.email,
    this.dietaryGoals,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'], // can be null
      email: json['email'] ?? '',
      dietaryGoals: json['dietaryGoals'] != null 
          ? Map<String, dynamic>.from(json['dietaryGoals']) 
          : null,
    );
  }
}
