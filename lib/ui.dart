import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity.dart';
import 'manager.dart';
import 'user_stats.dart';

class RankingDashboard extends StatefulWidget {
  const RankingDashboard({super.key});

  @override
  State<RankingDashboard> createState() => _RankingDashboardState();
}

class _RankingDashboardState extends State<RankingDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUserId = 'user123';
  List<UserStats> _topUsers = [];
  List<int> _userRankHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final rankingManager = Provider.of<RankingManager>(
      context,
      listen: false,
    );

    try {
      // Fetch top users
      _topUsers = await rankingManager.getTopUsers(limit: 10);

      // Fetch user rank history
      _userRankHistory = await rankingManager.getUserRankHistory(
        currentUserId,
        days: 7,
      );

      // Add some demo activities if this is first run
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('demo_activities_added') ?? false)) {
        await _addDemoActivities(rankingManager);
        prefs.setBool('demo_activities_added', true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDemoActivities(
    RankingManager rankingManager,
  ) async {
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

  Future<void> _refreshData() async {
    final rankingManager = Provider.of<RankingManager>(
      context,
      listen: false,
    );
    await rankingManager.refreshData();
    await _loadData();
  }

  Future<void> _addActivity() async {
    final rankingManager = Provider.of<RankingManager>(
      context,
      listen: false,
    );
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
        await _loadData();
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
                  _buildLeaderboardTab(),
                  _buildProfileTab(),
                  _buildHistoryTab(),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addActivity,
        tooltip: 'Add Activity',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _topUsers.length,
        itemBuilder: (context, index) {
          final user = _topUsers[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: user.rank <= 3 ? Colors.amber : Colors.blue,
                child: Text('${user.rank}'),
              ),
              title: Row(
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.profileImageUrl,
                      width: 40,
                      height: 40,
                      placeholder:
                          (context, url) => const CircularProgressIndicator(),
                      errorWidget:
                          (context, url, error) => const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(user.username),
                  if (user.userId == currentUserId)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.star, color: Colors.amber, size: 18),
                    ),
                ],
              ),
              subtitle: Text('🔥 ${user.streak} day streak'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${user.totalPoints} pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('${user.wordsLearned} words'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileTab() {
    return Consumer<RankingManager>(
      builder: (context, rankingManager, child) {
        final currentStats = rankingManager.currentUserStats;

        if (currentStats == null) {
          return const Center(child: Text('User not found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: CachedNetworkImageProvider(
                  currentStats.profileImageUrl,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentStats.username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rank #${currentStats.rank}',
                style: const TextStyle(fontSize: 18, color: Colors.blue),
              ),
              const SizedBox(height: 24),
              _buildStatCard(
                'Total Points',
                '${currentStats.totalPoints}',
                Icons.score,
                Colors.orange,
              ),
              _buildStatCard(
                'Current Streak',
                '${currentStats.streak} days',
                Icons.local_fire_department,
                Colors.red,
              ),
              _buildStatCard(
                'Lessons Completed',
                '${currentStats.lessonsCompleted}',
                Icons.book,
                Colors.green,
              ),
              _buildStatCard(
                'Words Learned',
                '${currentStats.wordsLearned}',
                Icons.translate,
                Colors.purple,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await rankingManager.updateStreak(currentUserId);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Streak updated!')),
                  );
                },
                icon: const Icon(Icons.update),
                label: const Text('Update Streak'),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: ${DateFormat('MMM d, yyyy h:mm a').format(currentStats.lastUpdated)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<UserActivity>>(
      future: Provider.of<RankingManager>(
        context,
        listen: false,
      ).getUserActivities(
        currentUserId,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No activities found in the last 7 days'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: activities.length + 1, // +1 for rank history section
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildRankHistorySection();
            }

            final activity = activities[index - 1];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: _getActivityIcon(activity.activityType),
                title: Text(activity.activityType.toUpperCase()),
                subtitle: Text(
                  DateFormat('MMM d, yyyy h:mm a').format(activity.completedAt),
                ),
                trailing: Text(
                  '+${activity.pointsEarned} pts',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRankHistorySection() {
    if (_userRankHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rank History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                children: List.generate(_userRankHistory.length, (index) {
                  final rank = _userRankHistory[index];
                  final date = DateTime.now().subtract(
                    Duration(days: _userRankHistory.length - 1 - index),
                  );

                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          rank == -1 ? '-' : '#$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: rank <= 3 ? Colors.green : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 50,
                          width: 8,
                          decoration: BoxDecoration(
                            color:
                                rank == -1
                                    ? Colors.grey
                                    : rank <= 3
                                    ? Colors.green
                                    : Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('E').format(date),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'lesson':
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.book, color: Colors.white),
        );
      case 'quiz':
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.quiz, color: Colors.white),
        );
      case 'vocabulary':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.translate, color: Colors.white),
        );
      case 'practice':
        return const CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(Icons.psychology, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.star, color: Colors.white),
        );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
