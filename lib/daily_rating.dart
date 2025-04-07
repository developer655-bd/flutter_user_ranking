import 'user_stats.dart';

class DailyRanking {
  final DateTime date;
  final List<UserStats> userRankings;

  DailyRanking({required this.date, required this.userRankings});

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'userRankings': userRankings.map((stats) => stats.toJson()).toList(),
    };
  }

  factory DailyRanking.fromJson(Map<String, dynamic> json) {
    return DailyRanking(
      date: DateTime.parse(json['date']),
      userRankings:
          (json['userRankings'] as List)
              .map((statsJson) => UserStats.fromJson(statsJson))
              .toList(),
    );
  }
}
