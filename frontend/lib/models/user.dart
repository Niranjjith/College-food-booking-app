class User {
  final String id;
  final String? name;
  final String email;

  User({
    required this.id,
    this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'], // can be null
      email: json['email'] ?? '',
    );
  }
}
