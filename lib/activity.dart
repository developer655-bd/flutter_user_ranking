class UserActivity {
  final String activityType;
  final int pointsEarned;
  final DateTime completedAt;

  UserActivity({
    required this.activityType,
    required this.pointsEarned,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'activityType': activityType,
      'pointsEarned': pointsEarned,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      activityType: json['activityType'],
      pointsEarned: json['pointsEarned'],
      completedAt: DateTime.parse(json['completedAt']),
    );
  }
}
