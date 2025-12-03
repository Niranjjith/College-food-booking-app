class Food {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isAvailable;
  final int preparationTime;
  final int popularity;
  final List<String> tags;

  Food({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.isAvailable,
    this.preparationTime = 15,
    this.popularity = 0,
    this.tags = const [],
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      category: json['category'] ?? 'General',
      imageUrl: json['imageUrl'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      preparationTime: json['preparationTime'] ?? 15,
      popularity: json['popularity'] ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    );
  }
}
