import 'dart:async';

import 'package:flutter/foundation.dart';

import 'activity.dart';
import 'connectivity_manager.dart';
import 'daily_rating.dart';
import 'delegate.dart';
import 'delegate_firebase.dart';
import 'user_stats.dart';

class RankingManager extends ValueNotifier<Map<String, UserStats>> {
  final RemoteDelegate _remoteDelegate;
  final ConnectivityManager _connectivityManager;

  final Map<String, List<UserActivity>> _pendingActivities = {};
  final Map<String, UserStats> _pendingUserUpdates = {};

  String? _currentUserId;
  StreamSubscription? _currentUserSubscription;
  StreamSubscription? _connectivitySubscription;

  RankingManager({
    RemoteDelegate? remoteDelegate,
    ConnectivityManager? connectivityManager,
  }) : _remoteDelegate = remoteDelegate ?? FirebaseRemoteDelegate(),
       _connectivityManager = connectivityManager ?? ConnectivityManager(),
       super({}) {
    _setupConnectivityListener();
  }

  bool get isConnected => _connectivityManager.isConnected;

  Stream<bool> get onConnectivityChanged =>
      _connectivityManager.onConnectivityChanged;

  set currentUserId(String userId) {
    _currentUserSubscription?.cancel();
    _currentUserId = userId;

    if (_connectivityManager.isConnected) {
      _currentUserSubscription = _remoteDelegate
          .listenToUserStats(userId)
          .listen((userStats) {
            final updatedValue = Map<String, UserStats>.from(value);
            updatedValue[userId] = userStats;
            value = updatedValue;
          });
    }
  }

  UserStats? get currentUserStats {
    if (_currentUserId == null) return null;
    return value[_currentUserId];
  }

  Future<void> initialize() async {
    try {
      await _remoteDelegate.initialize();

      if (_connectivityManager.isConnected) {
        await _fetchInitialData();
      }
    } catch (e) {
      print('Failed to initialize ranking manager: $e');
      rethrow;
    }
  }

  Future<void> registerUser(
    String userId,
    String username,
    String profileImageUrl,
  ) async {
    final updatedValue = Map<String, UserStats>.from(value);

    UserStats newUserStats;
    if (updatedValue.containsKey(userId)) {
      final existing = updatedValue[userId]!;
      newUserStats = existing.copyWith(
        username: username,
        profileImageUrl: profileImageUrl,
        lastUpdated: DateTime.now(),
      );
    } else {
      newUserStats = UserStats(
        userId: userId,
        username: username,
        profileImageUrl: profileImageUrl,
        totalPoints: 0,
        streak: 0,
        lessonsCompleted: 0,
        wordsLearned: 0,
        rank: updatedValue.length + 1,
        lastUpdated: DateTime.now(),
      );
    }

    updatedValue[userId] = newUserStats;
    value = updatedValue;

    if (_connectivityManager.isConnected) {
      try {
        await _remoteDelegate.saveUser(newUserStats);
        _pendingUserUpdates.remove(userId);
      } catch (e) {
        print('Failed to register user remotely: $e');
        _pendingUserUpdates[userId] = newUserStats;
      }
    } else {
      _pendingUserUpdates[userId] = newUserStats;
    }

    _recalculateRanks();
  }

  Future<void> logActivity(String userId, UserActivity activity) async {
    final updatedValue = Map<String, UserStats>.from(value);

    if (!updatedValue.containsKey(userId)) {
      throw Exception('User $userId not found. Please register user first.');
    }

    final currentStats = updatedValue[userId]!;

    int newLessonsCompleted = currentStats.lessonsCompleted;
    int newWordsLearned = currentStats.wordsLearned;

    if (activity.activityType == 'lesson') {
      newLessonsCompleted++;
    } else if (activity.activityType == 'vocabulary') {
      newWordsLearned += (activity.pointsEarned ~/ 5);
    }

    final updatedStats = currentStats.copyWith(
      totalPoints: currentStats.totalPoints + activity.pointsEarned,
      lessonsCompleted: newLessonsCompleted,
      wordsLearned: newWordsLearned,
      lastUpdated: DateTime.now(),
    );

    updatedValue[userId] = updatedStats;
    value = updatedValue;

    if (_connectivityManager.isConnected) {
      try {
        await Future.wait([
          _remoteDelegate.saveUser(updatedStats),
          _remoteDelegate.logUserActivity(userId, activity),
        ]);
      } catch (e) {
        print('Failed to log activity remotely: $e');
        _addPendingActivity(userId, activity);
        _pendingUserUpdates[userId] = updatedStats;
      }
    } else {
      _addPendingActivity(userId, activity);
      _pendingUserUpdates[userId] = updatedStats;
    }

    _recalculateRanks();
  }

  Future<void> updateStreak(
    String userId, {
    bool incrementStreak = true,
  }) async {
    final updatedValue = Map<String, UserStats>.from(value);

    if (!updatedValue.containsKey(userId)) {
      throw Exception('User $userId not found');
    }

    final currentStats = updatedValue[userId]!;

    final newStreak = incrementStreak ? currentStats.streak + 1 : 0;
    final updatedStats = currentStats.copyWith(
      streak: newStreak,
      lastUpdated: DateTime.now(),
    );

    updatedValue[userId] = updatedStats;
    value = updatedValue;

    if (_connectivityManager.isConnected) {
      try {
        await _remoteDelegate.saveUser(updatedStats);
        _pendingUserUpdates.remove(userId);
      } catch (e) {
        print('Failed to update streak remotely: $e');
        _pendingUserUpdates[userId] = updatedStats;
      }
    } else {
      _pendingUserUpdates[userId] = updatedStats;
    }
  }

  Future<UserStats?> getUserStats(String userId) async {
    if (value.containsKey(userId)) {
      return value[userId];
    }

    if (_connectivityManager.isConnected) {
      try {
        final remoteStats = await _remoteDelegate.fetchUser(userId);
        if (remoteStats != null) {
          final updatedValue = Map<String, UserStats>.from(value);
          updatedValue[userId] = remoteStats;
          value = updatedValue;
        }
        return remoteStats;
      } catch (e) {
        print('Failed to fetch user stats remotely: $e');
        return null;
      }
    }

    return null;
  }

  Future<List<UserStats>> getTopUsers({int limit = 10}) async {
    final localUsers = value.values.toList();

    localUsers.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    if (_connectivityManager.isConnected) {
      try {
        final rankingsStream = _remoteDelegate.listenToRankings(limit: limit);
        return await rankingsStream.first;
      } catch (e) {
        print('Failed to fetch top users remotely: $e');
      }
    }

    return localUsers.take(limit).toList();
  }

  List<UserStats> getUsersByStreak({int minStreak = 1, int limit = 10}) {
    final users =
        value.values.where((user) => user.streak >= minStreak).toList();

    users.sort((a, b) => b.streak.compareTo(a.streak));

    return users.take(limit).toList();
  }

  Future<void> saveRankingSnapshot() async {
    final today = DateTime.now();

    final dailyRanking = DailyRanking(
      date: today,
      userRankings: value.values.toList(),
    );

    if (_connectivityManager.isConnected) {
      try {
        await _remoteDelegate.saveRankingSnapshot(dailyRanking);
      } catch (e) {
        print('Failed to save ranking snapshot remotely: $e');
      }
    }
  }

  Future<List<int>> getUserRankHistory(String userId, {int days = 7}) async {
    final result = <int>[];

    if (_connectivityManager.isConnected) {
      try {
        final history = await _remoteDelegate.fetchRankingHistory(days: days);

        for (int i = days - 1; i >= 0; i--) {
          final targetDate = DateTime.now().subtract(Duration(days: i));
          final targetDayHistory = history.firstWhere(
            (snapshot) => _isSameDay(snapshot.date, targetDate),
            orElse: () => DailyRanking(date: targetDate, userRankings: []),
          );

          final userRank =
              targetDayHistory.userRankings
                  .firstWhere(
                    (stats) => stats.userId == userId,
                    orElse:
                        () => UserStats(
                          userId: userId,
                          username: '',
                          profileImageUrl: '',
                          totalPoints: 0,
                          streak: 0,
                          lessonsCompleted: 0,
                          wordsLearned: 0,
                          rank: -1,
                          lastUpdated: targetDate,
                        ),
                  )
                  .rank;

          result.add(userRank);
        }

        return result;
      } catch (e) {
        print('Failed to fetch ranking history remotely: $e');
      }
    }

    return List.generate(days, (index) => -1);
  }

  Future<List<UserActivity>> getUserActivities(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_connectivityManager.isConnected) {
      try {
        return await _remoteDelegate.fetchUserActivities(
          userId,
          startDate: startDate,
          endDate: endDate,
        );
      } catch (e) {
        print('Failed to fetch user activities remotely: $e');
      }
    }

    return [];
  }

  Future<void> syncPendingChanges() async {
    if (!_connectivityManager.isConnected) {
      return;
    }

    final pendingUsers = Map<String, UserStats>.from(_pendingUserUpdates);
    for (final entry in pendingUsers.entries) {
      try {
        await _remoteDelegate.saveUser(entry.value);
        _pendingUserUpdates.remove(entry.key);
      } catch (e) {
        print('Failed to sync pending user update for ${entry.key}: $e');
      }
    }

    final pendingActivities = Map<String, List<UserActivity>>.from(
      _pendingActivities,
    );
    for (final entry in pendingActivities.entries) {
      final userId = entry.key;
      final activities = List<UserActivity>.from(entry.value);

      for (final activity in activities) {
        try {
          await _remoteDelegate.logUserActivity(userId, activity);
          _pendingActivities[userId]?.remove(activity);
          if (_pendingActivities[userId]?.isEmpty ?? false) {
            _pendingActivities.remove(userId);
          }
        } catch (e) {
          print('Failed to sync pending activity for $userId: $e');
        }
      }
    }
  }

  Future<void> refreshData() async {
    if (!_connectivityManager.isConnected) {
      throw Exception('Cannot refresh data: offline');
    }

    await _fetchInitialData();
  }

  /// Handle device going online
  Future<void> _handleOnlineStatus() async {
    print('Device is online, syncing pending changes...');
    await syncPendingChanges();
    await _fetchInitialData();

    // Resubscribe to current user updates if needed
    if (_currentUserId != null && _currentUserSubscription == null) {
      _currentUserSubscription = _remoteDelegate
          .listenToUserStats(_currentUserId!)
          .listen((userStats) {
            final updatedValue = Map<String, UserStats>.from(value);
            updatedValue[_currentUserId!] = userStats;
            value = updatedValue;
          });
    }
  }

  /// Handle device going offline
  void _handleOfflineStatus() {
    print('Device is offline, operating in local mode');
    // Cancel subscriptions when offline
    _currentUserSubscription?.cancel();
    _currentUserSubscription = null;
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivityManager.onConnectivityChanged
        .listen((isConnected) {
          if (isConnected) {
            _handleOnlineStatus();
          }
        });
  }

  Future<void> _fetchInitialData() async {
    try {
      // Fetch top users
      final topRankingsStream = _remoteDelegate.listenToRankings(limit: 20);
      final topUsers = await topRankingsStream.first;

      final updatedValue = Map<String, UserStats>.from(value);
      for (final user in topUsers) {
        updatedValue[user.userId] = user;
      }

      value = updatedValue;
    } catch (e) {
      print('Failed to fetch initial data: $e');
      rethrow;
    }
  }

  void _recalculateRanks() {
    final users = value.values.toList();
    users.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    final updatedValue = Map<String, UserStats>.from(value);
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      if (user.rank != i + 1) {
        updatedValue[user.userId] = user.copyWith(rank: i + 1);
      }
    }

    value = updatedValue;
  }

  void _addPendingActivity(String userId, UserActivity activity) {
    if (!_pendingActivities.containsKey(userId)) {
      _pendingActivities[userId] = [];
    }
    _pendingActivities[userId]!.add(activity);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void dispose() {
    _currentUserSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
