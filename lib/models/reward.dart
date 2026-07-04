class Reward {
  final String id;
  final String title;
  final String? description;
  final String category;
  final int pointsRequired;
  final int? stock;
  final String? imageEmoji;
  final bool featured;
  final String? expiresAt;
  final DateTime createdAt;

  Reward({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.pointsRequired,
    this.stock,
    this.imageEmoji,
    this.featured = false,
    this.expiresAt,
    required this.createdAt,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      pointsRequired: json['points_required'] as int,
      stock: json['stock'] as int?,
      imageEmoji: json['image_emoji'] as String?,
      featured: json['featured'] as bool? ?? false,
      expiresAt: json['expires_at'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'points_required': pointsRequired,
      'stock': stock,
      'image_emoji': imageEmoji,
      'featured': featured,
      'expires_at': expiresAt,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
