import 'user_activity.dart';
import 'daily_rating.dart';
import 'user_stats.dart';

abstract class RemoteDelegate {
  Future<void> initialize();

  Future<void> saveUser(UserStats user);

  Future<UserStats?> fetchUser(String userId);

  Stream<UserStats> listenToUserStats(String userId);

  Future<void> logUserActivity(String userId, UserActivity activity);

  Future<List<UserActivity>> fetchUserActivities(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<List<UserStats>> listenToRankings({int limit = 10});

  Future<void> saveRankingSnapshot(DailyRanking ranking);

  Future<List<DailyRanking>> fetchRankingHistory({int days = 7});
}
