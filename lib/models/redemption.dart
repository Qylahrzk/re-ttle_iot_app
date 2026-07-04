class Redemption {
  final String id;
  final String userId;
  final String rewardId;
  final int pointsSpent;
  final String code;
  final String status;
  final DateTime createdAt;

  Redemption({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.pointsSpent,
    required this.code,
    this.status = 'active',
    required this.createdAt,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    return Redemption(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      rewardId: json['reward_id'] as String,
      pointsSpent: json['points_spent'] as int,
      code: json['code'] as String,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'reward_id': rewardId,
      'points_spent': pointsSpent,
      'code': code,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
