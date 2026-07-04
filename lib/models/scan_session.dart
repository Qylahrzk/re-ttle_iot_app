class ScanSession {
  final String id;
  final String userId;
  final String binId;
  final String? location;
  final int bottleCount;
  final int pointsEarned;
  final double co2SavedKg;
  final String status;
  final DateTime createdAt;

  ScanSession({
    required this.id,
    required this.userId,
    required this.binId,
    this.location,
    this.bottleCount = 1,
    this.pointsEarned = 10,
    this.co2SavedKg = 0.2,
    this.status = 'completed',
    required this.createdAt,
  });

  factory ScanSession.fromJson(Map<String, dynamic> json) {
    return ScanSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      binId: json['bin_id'] as String,
      location: json['location'] as String?,
      bottleCount: json['bottle_count'] as int? ?? 1,
      pointsEarned: json['points_earned'] as int? ?? 10,
      co2SavedKg: json['co2_saved_kg'] != null 
          ? double.parse(json['co2_saved_kg'].toString()) 
          : 0.2,
      status: json['status'] as String? ?? 'completed',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bin_id': binId,
      'location': location,
      'bottle_count': bottleCount,
      'points_earned': pointsEarned,
      'co2_saved_kg': co2SavedKg,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
