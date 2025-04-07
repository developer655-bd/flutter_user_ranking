import 'package:flutter/foundation.dart';

import '../logics/user_activity.dart';
import '../logics/user_stats.dart';

abstract class RankingDelegate extends ChangeNotifier {
  bool isConnected = true;
  UserStats? currentUserStats;

  RankingDelegate();

  Future<void> refreshData();

  Future<void> syncPendingChanges();

  void notifyDataChanged();

  Future<List<UserStats>> getTopUsers({int limit = 10});

  Future<UserStats?> getUserStats(String userId);

  Future<List<int>> getUserRankHistory(String userId, {int days = 7});

  Future<List<UserActivity>> getUserActivities(
    String userId, {
    required DateTime startDate,
  });

  Future<void> logActivity(String userId, UserActivity activity);

  Future<void> updateStreak(String userId);

  Future<void> registerUser(
    String userId,
    String username,
    String profileImageUrl,
  );

  Future<void> recordDailyRank(String userId, int rank);
}
