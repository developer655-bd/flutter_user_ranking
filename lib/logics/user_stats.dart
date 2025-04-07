class UserStats {
  final String? _userId;
  final String? _username;
  final String? _profileImageUrl;
  final int? _totalPoints;
  final int? _streak;
  final int? _lessonsCompleted;
  final int? _wordsLearned;
  final int? _rank;
  final DateTime? _lastUpdated;

  String get userId => _userId ?? '';

  String get username => _username ?? '';

  String get profileImageUrl => _profileImageUrl ?? '';

  int get totalPoints => _totalPoints ?? 0;

  int get streak => _streak ?? 0;

  int get lessonsCompleted => _lessonsCompleted ?? 0;

  int get wordsLearned => _wordsLearned ?? 0;

  int get rank => _rank ?? 0;

  DateTime get lastUpdated => _lastUpdated ?? DateTime.now();

  const UserStats({
    required String? userId,
    required String? username,
    required String? profileImageUrl,
    required int? totalPoints,
    required int? streak,
    required int? lessonsCompleted,
    required int? wordsLearned,
    required int? rank,
    required DateTime? lastUpdated,
  }) : _userId = userId,
       _username = username,
       _profileImageUrl = profileImageUrl,
       _totalPoints = totalPoints,
       _streak = streak,
       _lessonsCompleted = lessonsCompleted,
       _wordsLearned = wordsLearned,
       _rank = rank,
       _lastUpdated = lastUpdated;

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
      userId: _userId,
      username: username ?? _username,
      profileImageUrl: profileImageUrl ?? _profileImageUrl,
      totalPoints: totalPoints ?? _totalPoints,
      streak: streak ?? _streak,
      lessonsCompleted: lessonsCompleted ?? _lessonsCompleted,
      wordsLearned: wordsLearned ?? _wordsLearned,
      rank: rank ?? _rank,
      lastUpdated: lastUpdated ?? _lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': _userId,
      'username': _username,
      'profileImageUrl': _profileImageUrl,
      'totalPoints': _totalPoints,
      'streak': _streak,
      'lessonsCompleted': _lessonsCompleted,
      'wordsLearned': _wordsLearned,
      'rank': _rank,
      'lastUpdated': _lastUpdated?.toIso8601String(),
    };
  }

  factory UserStats.from(Map<String, dynamic> json) {
    final uid = json['userId'];
    final username = json['username'];
    final profileImageUrl = json['profileImageUrl'];
    final totalPoints = json['totalPoints'];
    final streak = json['streak'];
    final lessonsCompleted = json['lessonsCompleted'];
    final wordsLearned = json['wordsLearned'];
    final rank = json['rank'];
    final lastUpdated = json['lastUpdated'];
    return UserStats(
      userId: uid is String ? uid : null,
      username: username is String ? username : null,
      profileImageUrl: profileImageUrl is String ? profileImageUrl : null,
      totalPoints: totalPoints is num ? totalPoints.toInt() : null,
      streak: streak is num ? streak.toInt() : null,
      lessonsCompleted:
          lessonsCompleted is num ? lessonsCompleted.toInt() : null,
      wordsLearned: wordsLearned is num ? wordsLearned.toInt() : null,
      rank: rank is num ? rank.toInt() : null,
      lastUpdated:
          lastUpdated is String ? DateTime.tryParse(lastUpdated) : null,
    );
  }
}
