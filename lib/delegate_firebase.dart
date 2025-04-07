import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'activity.dart';
import 'daily_rating.dart';
import 'delegate.dart';
import 'user_stats.dart';

class FirebaseRemoteDelegate implements RemoteDelegate {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _activitiesRef = FirebaseDatabase.instance.ref(
    'activities',
  );
  final DatabaseReference _rankingsRef = FirebaseDatabase.instance.ref(
    'rankings',
  );

  @override
  Future<void> initialize() async {
    // Ensure database connection is established
    try {
      await FirebaseDatabase.instance.ref().child('info/connected').get();
    } catch (e) {
      print('Failed to connect to Firebase: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveUser(UserStats user) async {
    try {
      await _usersRef.child(user.userId).set(user.toJson());
    } catch (e) {
      print('Failed to save user: $e');
      rethrow;
    }
  }

  @override
  Future<UserStats?> fetchUser(String userId) async {
    try {
      final snapshot = await _usersRef.child(userId).get();

      if (snapshot.exists) {
        return UserStats.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }

      return null;
    } catch (e) {
      print('Failed to fetch user: $e');
      rethrow;
    }
  }

  @override
  Stream<UserStats> listenToUserStats(String userId) {
    return _usersRef.child(userId).onValue.map((event) {
      if (event.snapshot.exists) {
        return UserStats.fromJson(
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      }

      throw Exception('User not found');
    });
  }

  @override
  Future<void> logUserActivity(String userId, UserActivity activity) async {
    try {
      final activityRef = _activitiesRef
          .child(userId)
          .child(activity.completedAt.toIso8601String().replaceAll(':', '_'));

      await activityRef.set(activity.toJson());
    } catch (e) {
      print('Failed to log activity: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserActivity>> fetchUserActivities(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _activitiesRef.child(userId);

      if (startDate != null) {
        query = query.orderByKey().startAt(
          startDate.toIso8601String().replaceAll(':', '_'),
        );
      }

      if (endDate != null) {
        query = query.orderByKey().endAt(
          endDate.toIso8601String().replaceAll(':', '_'),
        );
      }

      final snapshot = await query.get();

      if (snapshot.exists) {
        final activities = <UserActivity>[];
        Map<dynamic, dynamic> data = snapshot.value as Map;

        data.forEach((key, value) {
          activities.add(
            UserActivity.fromJson(Map<String, dynamic>.from(value)),
          );
        });

        activities.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        return activities;
      }

      return [];
    } catch (e) {
      print('Failed to fetch activities: $e');
      rethrow;
    }
  }

  @override
  Stream<List<UserStats>> listenToRankings({int limit = 10}) {
    return _usersRef.orderByChild('totalPoints').limitToLast(limit).onValue.map(
      (event) {
        if (event.snapshot.exists) {
          final users = <UserStats>[];
          Map<dynamic, dynamic> data = event.snapshot.value as Map;

          data.forEach((key, value) {
            users.add(UserStats.fromJson(Map<String, dynamic>.from(value)));
          });

          users.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

          // Update ranks if needed
          for (int i = 0; i < users.length; i++) {
            if (users[i].rank != i + 1) {
              final updated = users[i].copyWith(rank: i + 1);
              users[i] = updated;

              // Save the updated rank
              _usersRef.child(updated.userId).update({'rank': i + 1});
            }
          }

          return users;
        }

        return <UserStats>[];
      },
    );
  }

  @override
  Future<void> saveRankingSnapshot(DailyRanking ranking) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(ranking.date);
      await _rankingsRef.child(dateStr).set(ranking.toJson());
    } catch (e) {
      print('Failed to save ranking snapshot: $e');
      rethrow;
    }
  }

  @override
  Future<List<DailyRanking>> fetchRankingHistory({int days = 7}) async {
    try {
      final rankings = <DailyRanking>[];

      for (int i = 0; i < days; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        final snapshot = await _rankingsRef.child(dateStr).get();

        if (snapshot.exists) {
          rankings.add(
            DailyRanking.fromJson(
              Map<String, dynamic>.from(snapshot.value as Map),
            ),
          );
        } else {
          rankings.add(DailyRanking(date: date, userRankings: []));
        }
      }

      return rankings;
    } catch (e) {
      print('Failed to fetch ranking history: $e');
      rethrow;
    }
  }
}
