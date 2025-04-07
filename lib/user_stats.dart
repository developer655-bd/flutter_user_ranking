class UserStats {
  final String userId;
  final String username;
  final String profileImageUrl;
  final int totalPoints;
  final int streak;
  final int lessonsCompleted;
  final int wordsLearned;
  final int rank;
  final DateTime lastUpdated;

  UserStats({
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.totalPoints,
    required this.streak,
    required this.lessonsCompleted,
    required this.wordsLearned,
    required this.rank,
    required this.lastUpdated,
  });

  UserStats copyWith({
    String? username,
    String? profileImageUrl,
    int? totalPoints,
    int? streak,
    int? lessonsCompleted,
    int? wordsLearned,
    int? rank,
    DateTime? lastUpdated,
  }) {
    return UserStats(
      userId: userId,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      streak: streak ?? this.streak,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      wordsLearned: wordsLearned ?? this.wordsLearned,
      rank: rank ?? this.rank,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'totalPoints': totalPoints,
      'streak': streak,
      'lessonsCompleted': lessonsCompleted,
      'wordsLearned': wordsLearned,
      'rank': rank,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['userId'],
      username: json['username'],
      profileImageUrl: json['profileImageUrl'],
      totalPoints: json['totalPoints'],
      streak: json['streak'],
      lessonsCompleted: json['lessonsCompleted'],
      wordsLearned: json['wordsLearned'],
      rank: json['rank'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
