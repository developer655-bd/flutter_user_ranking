import 'package:cloud_firestore/cloud_firestore.dart';

import 'data.dart';

Future<void> seedTestData() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  // Add users
  final usersData = userJsonString;
  for (var userData in usersData) {
    final userDoc = firestore
        .collection('users')
        .doc(userData['userId'].toString());
    batch.set(userDoc, userData);
  }

  // Add activities
  final activitiesData = activitiesJsonString;
  activitiesData.forEach((userId, activities) {
    for (var activity in activities) {
      final activityDoc =
          firestore
              .collection('users')
              .doc(userId)
              .collection('activities')
              .doc(); // Auto-generate ID
      batch.set(activityDoc, activity);
    }
  });

  // Add rank history
  final rankHistoryData = rankHistoryJsonString;
  rankHistoryData.forEach((userId, history) {
    for (var entry in history) {
      final historyDoc =
          firestore
              .collection('users')
              .doc(userId)
              .collection('rank_history')
              .doc(); // Auto-generate ID
      batch.set(historyDoc, entry);
    }
  });

  await batch.commit();
}
