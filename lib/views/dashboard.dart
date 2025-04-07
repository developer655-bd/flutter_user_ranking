import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../activity.dart';
import '../manager.dart';
import 'history.dart';
import 'leadership.dart';
import 'profile.dart';

class RankingDashboard extends StatefulWidget {
  const RankingDashboard({super.key});

  @override
  State<RankingDashboard> createState() => _RankingDashboardState();
}

class _RankingDashboardState extends State<RankingDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUserId = 'user123';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    final rankingManager = Provider.of<RankingManager>(context, listen: false);

    try {
      // Add some demo activities if this is first run
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('demo_activities_added') ?? false)) {
        await _addDemoActivities(rankingManager);
        prefs.setBool('demo_activities_added', true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error initializing data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDemoActivities(RankingManager rankingManager) async {
    // Add some sample activities to show the functionality
    final activities = [
      UserActivity(
        activityType: 'lesson',
        pointsEarned: 50,
        completedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      UserActivity(
        activityType: 'vocabulary',
        pointsEarned: 25,
        completedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      UserActivity(
        activityType: 'quiz',
        pointsEarned: 75,
        completedAt: DateTime.now(),
      ),
    ];

    for (final activity in activities) {
      await rankingManager.logActivity(currentUserId, activity);
    }

    // Simulate another user for competition
    await rankingManager.registerUser(
      'user456',
      'Jane Doe',
      'https://placekitten.com/200/201',
    );

    await rankingManager.logActivity(
      'user456',
      UserActivity(
        activityType: 'lesson',
        pointsEarned: 100,
        completedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _addActivity() async {
    final rankingManager = Provider.of<RankingManager>(context, listen: false);
    final activityTypes = ['lesson', 'vocabulary', 'quiz', 'practice'];

    // Show dialog to select activity type
    final selectedType = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Add Activity'),
            children:
                activityTypes
                    .map(
                      (type) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, type),
                        child: Text(type.toUpperCase()),
                      ),
                    )
                    .toList(),
          ),
    );

    if (selectedType != null) {
      // Generate random points based on activity type
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      final points =
          selectedType == 'lesson'
              ? 50 + random
              : selectedType == 'quiz'
              ? 75 + random
              : 25 + random;

      final activity = UserActivity(
        activityType: selectedType,
        pointsEarned: points,
        completedAt: DateTime.now(),
      );

      try {
        await rankingManager.logActivity(currentUserId, activity);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $selectedType activity (+$points points)'),
          ),
        );
        // Notify all tabs that data has changed
        rankingManager.notifyDataChanged();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding activity: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HelloEnglish Rankings'),
        actions: [
          Consumer<RankingManager>(
            builder: (context, rankingManager, child) {
              return IconButton(
                icon: Icon(
                  rankingManager.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: rankingManager.isConnected ? Colors.green : Colors.red,
                ),
                onPressed:
                    rankingManager.isConnected
                        ? () => rankingManager.syncPendingChanges()
                        : null,
                tooltip:
                    rankingManager.isConnected
                        ? 'Online - Tap to sync'
                        : 'Offline',
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'LEADERBOARD'),
            Tab(text: 'YOUR PROFILE'),
            Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  LeaderboardTab(userId: currentUserId),
                  ProfileTab(userId: currentUserId),
                  HistoryTab(userId: currentUserId),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addActivity,
        tooltip: 'Add Activity',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
