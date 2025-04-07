import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'user_activity.dart';
import 'user_stats.dart';

class RankingManager extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isConnected = true;
  UserStats? currentUserStats;

  // Constructor that initializes connectivity monitoring
  RankingManager() {
    _initConnectivity();
    _listenToConnectivityChanges();
  }

  // Initialize connectivity status
  Future<void> _initConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      isConnected = connectivityResult != ConnectivityResult.none;
      notifyListeners();
    } catch (e) {
      debugPrint('Could not check connectivity status: $e');
    }
  }

  // Listen for connectivity changes
  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((result) {
      isConnected = result.first != ConnectivityResult.none;
      notifyListeners();
    });
  }

  // Method to refresh data
  Future<void> refreshData() async {
    // Check connectivity before attempting refresh
    if (!isConnected) return;

    // If there's a current user, refresh their stats
    if (currentUserStats?.userId != null) {
      await getUserStats(currentUserStats!.userId!);
    }

    notifyListeners();
  }

  // Method to sync pending changes (useful when coming back online)
  Future<void> syncPendingChanges() async {
    if (!isConnected) return;

    // This would typically handle any cached updates that need to be pushed
    // For a real implementation, you might use Firestore persistence or a local database
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners();
  }

  // Notify all listeners that data has changed
  void notifyDataChanged() {
    notifyListeners();
  }

  Future<List<UserStats>> getTopUsers({int limit = 10}) async {
    try {
      return _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get()
          .then((snapshot) {
            if (snapshot.docs.isEmpty) {
              return [];
            }
            int index = 0;
            return snapshot.docs.map((e) {
              index++;
              return UserStats.from(e.data()).copyWith(rank: index);
            }).toList();
          });
    } catch (e) {
      debugPrint('Error fetching top users: $e');
      return [];
    }
  }

  // Get stats for a specific user
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;

      // Get the user's rank by querying users with more points
      final rankSnapshot =
          await _firestore
              .collection('users')
              .where('totalPoints', isGreaterThan: data['totalPoints'] ?? 0)
              // .where('totalPoints', isLessThan: data['totalPoints'] ?? 0)
              .count()
              .get();

      final rank = (rankSnapshot.count ?? 0) + 1; // +1 because ranks start at 1

      currentUserStats = UserStats(
        userId: userId,
        username: data['username'] ?? 'Anonymous',
        rank: rank,
        totalPoints: data['totalPoints'] ?? 0,
        streak: data['streak'] ?? 0,
        wordsLearned: data['wordsLearned'] ?? 0,
        lessonsCompleted: data['lessonsCompleted'] ?? 0,
        profileImageUrl:
            data['profileImageUrl'] ?? 'https://placekitten.com/200/200',
        lastUpdated:
            (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      notifyListeners();
      return currentUserStats;
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
      return null;
    }
  }

  // Get user rank history
  Future<List<int>> getUserRankHistory(String userId, {int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days - 1));

      // Query the rank_history subcollection
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('rank_history')
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(startDate.year, startDate.month, startDate.day),
                ),
              )
              .orderBy('date', descending: false)
              .get();

      // Create a map to hold each day's rank
      Map<String, int> ranksByDay = {};

      // Format date as string for map key
      String formatDate(DateTime date) =>
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Fill in ranks from Firestore
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        ranksByDay[formatDate(date)] = data['rank'] ?? 0;
      }

      // Generate the complete list for all days
      List<int> result = [];
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: days - 1 - i));
        final dateKey = formatDate(date);
        result.add(ranksByDay[dateKey] ?? 0); // Use 0 if no data for that day
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching rank history: $e');
      return List.generate(days, (index) => 0);
    }
  }

  // Get user activities
  Future<List<UserActivity>> getUserActivities(
    String userId, {
    required DateTime startDate,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('activities')
              .where(
                'completedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .orderBy('completedAt', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserActivity(
          activityType: data['activityType'] ?? 'unknown',
          pointsEarned: data['pointsEarned'] ?? 0,
          completedAt:
              (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user activities: $e');
      return [];
    }
  }

  // Log a new activity
  Future<void> logActivity(String userId, UserActivity activity) async {
    try {
      // Add the activity to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .add({
            'activityType': activity.activityType,
            'pointsEarned': activity.pointsEarned,
            'completedAt': Timestamp.fromDate(activity.completedAt),
          });

      // Update the user's stats
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User does not exist!');
        }

        final userData = userDoc.data() as Map<String, dynamic>;

        // Update the total points
        final newTotalPoints =
            (userData['totalPoints'] ?? 0) + activity.pointsEarned;

        // Update relevant stats based on activity type
        if (activity.activityType == 'lesson') {
          final newLessonsCompleted = (userData['lessonsCompleted'] ?? 0) + 1;
          transaction.update(userRef, {
            'totalPoints': newTotalPoints,
            'lessonsCompleted': newLessonsCompleted,
            'lastUpdated': Timestamp.now(),
          });
        } else if (activity.activityType == 'vocabulary') {
          final newWordsLearned =
              (userData['wordsLearned'] ?? 0) +
              (activity.pointsEarned ~/ 5); // Assuming 5 points per word
          transaction.update(userRef, {
            'totalPoints': newTotalPoints,
            'wordsLearned': newWordsLearned,
            'lastUpdated': Timestamp.now(),
          });
        } else {
          transaction.update(userRef, {
            'totalPoints': newTotalPoints,
            'lastUpdated': Timestamp.now(),
          });
        }
      });

      // Update local cache if this is the current user
      if (currentUserStats != null && userId == currentUserStats!.userId) {
        currentUserStats = currentUserStats!.copyWith(
          totalPoints: currentUserStats!.totalPoints + activity.pointsEarned,
          lastUpdated: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error logging activity: $e');
      rethrow; // Propagate the error so the UI can handle it
    }
  }

  // Update user streak
  Future<void> updateStreak(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User does not exist!');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final currentStreak = userData['streak'] ?? 0;

        transaction.update(userRef, {
          'streak': currentStreak + 1,
          'lastUpdated': Timestamp.now(),
        });
      });

      // Update the current user stats in memory
      if (currentUserStats != null && userId == currentUserStats!.userId) {
        currentUserStats = currentUserStats!.copyWith(
          streak: currentUserStats!.streak + 1,
          lastUpdated: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating streak: $e');
      rethrow;
    }
  }

  // Register a user
  Future<void> registerUser(
    String userId,
    String username,
    String profileImageUrl,
  ) async {
    try {
      // Check if user already exists
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        // User already exists, might want to throw an error or handle differently
        return;
      }

      // Create the user document
      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'totalPoints': 0,
        'streak': 0,
        'wordsLearned': 0,
        'lessonsCompleted': 0,
        'lastUpdated': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });

      // Create initial rank history entry
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('rank_history')
          .add({
            'date': Timestamp.fromDate(DateTime.now()),
            'rank': 0, // New user starts at rank 0
          });

      notifyListeners();
    } catch (e) {
      debugPrint('Error registering user: $e');
      rethrow;
    }
  }

  // Store the user's daily rank in history
  Future<void> recordDailyRank(String userId, int rank) async {
    try {
      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);

      // Check if we already recorded today's rank
      final existingRecord =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('rank_history')
              .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
              .limit(1)
              .get();

      if (existingRecord.docs.isNotEmpty) {
        // Update existing record
        await existingRecord.docs.first.reference.update({'rank': rank});
      } else {
        // Create new record
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('rank_history')
            .add({'date': Timestamp.fromDate(dateOnly), 'rank': rank});
      }
    } catch (e) {
      debugPrint('Error recording daily rank: $e');
    }
  }
}
