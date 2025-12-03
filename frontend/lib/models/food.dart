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
  final Map<String, dynamic>? nutrition;
  final bool isHealthy;
  final int healthScore;

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
    this.nutrition,
    this.isHealthy = false,
    this.healthScore = 50,
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
      nutrition: json['nutrition'] != null ? Map<String, dynamic>.from(json['nutrition']) : null,
      isHealthy: json['isHealthy'] ?? false,
      healthScore: json['healthScore'] ?? 50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'preparationTime': preparationTime,
      'popularity': popularity,
      'tags': tags,
      'nutrition': nutrition,
      'isHealthy': isHealthy,
      'healthScore': healthScore,
    };
  }
}
