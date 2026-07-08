class Profile {
  final String id;
  final String? matricNumber;
  final String? fullName;
  final String? email;
  final String? faculty;
  final String? programme;
  final int semester;
  final String? avatarUrl;
  final int totalPoints;
  final int totalBottles;
  final double co2SavedKg;
  final int plasticDivertedG;
  final int streakDays;
  final String? lastScanDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.matricNumber,
    this.fullName,
    this.email,
    this.faculty,
    this.programme,
    this.semester = 1,
    this.avatarUrl,
    this.totalPoints = 0,
    this.totalBottles = 0,
    this.co2SavedKg = 0.0,
    this.plasticDivertedG = 0,
    this.streakDays = 0,
    this.lastScanDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      matricNumber: json['matric_number'] as String?,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      faculty: json['faculty'] as String?,
      programme: json['programme'] as String?,
      semester: json['semester'] is int
          ? json['semester'] as int
          : int.parse(json['semester']?.toString() ?? '1'),
      avatarUrl: json['avatar_url'] as String?,
      totalPoints: json['total_points'] as int? ?? 0,
      totalBottles: json['total_bottles'] as int? ?? 0,
      co2SavedKg: json['co2_saved_kg'] != null
          ? double.parse(json['co2_saved_kg'].toString())
          : 0.0,
      plasticDivertedG: json['plastic_diverted_g'] != null
          ? (double.parse(json['plastic_diverted_g'].toString())).round()
          : 0,
      streakDays: json['streak_days'] as int? ?? 0,
      lastScanDate: json['last_scan_date'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matric_number': matricNumber,
      'full_name': fullName,
      'email': email,
      'faculty': faculty,
      'programme': programme,
      'semester': semester,
      'avatar_url': avatarUrl,
      'total_points': totalPoints,
      'total_bottles': totalBottles,
      'co2_saved_kg': co2SavedKg,
      'plastic_diverted_g': plasticDivertedG,
      'streak_days': streakDays,
      'last_scan_date': lastScanDate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? matricNumber,
    String? fullName,
    String? email,
    String? faculty,
    String? programme,
    int? semester,
    String? avatarUrl,
    int? totalPoints,
    int? totalBottles,
    double? co2SavedKg,
    int? plasticDivertedG,
    int? streakDays,
    String? lastScanDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      matricNumber: matricNumber ?? this.matricNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      faculty: faculty ?? this.faculty,
      programme: programme ?? this.programme,
      semester: semester ?? this.semester,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      totalBottles: totalBottles ?? this.totalBottles,
      co2SavedKg: co2SavedKg ?? this.co2SavedKg,
      plasticDivertedG: plasticDivertedG ?? this.plasticDivertedG,
      streakDays: streakDays ?? this.streakDays,
      lastScanDate: lastScanDate ?? this.lastScanDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
