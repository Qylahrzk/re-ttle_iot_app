class Reward {
  final String id;
  final String name;
  final String? description;
  final int pointsRequired;
  final String? imageEmoji;
  final String? imageUrl;
  final bool featured;
  final DateTime createdAt;

  // Backward-compatible title property
  String get title => name;

  // Dynamic category mapping based on reward name
  String get category => determineCategory(name);

  Reward({
    required this.id,
    required this.name,
    this.description,
    required this.pointsRequired,
    this.imageEmoji,
    this.imageUrl,
    this.featured = false,
    required this.createdAt,
  });

  static String determineCategory(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('coffee') ||
        lowerName.contains('cafe') ||
        lowerName.contains('meal') ||
        lowerName.contains('food') ||
        lowerName.contains('drink') ||
        lowerName.contains('tea')) {
      return 'Food';
    }
    if (lowerName.contains('print') ||
        lowerName.contains('campus') ||
        lowerName.contains('library')) {
      return 'Campus';
    }
    if (lowerName.contains('grab') ||
        lowerName.contains('ride') ||
        lowerName.contains('taxi') ||
        lowerName.contains('transport')) {
      return 'Transportation';
    }
    if (lowerName.contains('plant') ||
        lowerName.contains('tree') ||
        lowerName.contains('bottle') ||
        lowerName.contains('eco')) {
      return 'Eco Products';
    }
    if (lowerName.contains('movie') ||
        lowerName.contains('ticket') ||
        lowerName.contains('lifestyle') ||
        lowerName.contains('tgv')) {
      return 'Lifestyle';
    }
    return 'Shopping';
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      description: json['description'] as String?,
      pointsRequired: json['points_required'] as int? ?? 100,
      imageEmoji: json['image_emoji'] as String?,
      imageUrl: json['image_url'] as String?,
      featured: json['featured'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points_required': pointsRequired,
      'image_emoji': imageEmoji,
      'image_url': imageUrl,
      'featured': featured,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
