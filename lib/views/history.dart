import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../activity.dart';
import '../manager.dart';

class HistoryTab extends StatefulWidget {
  final String userId;

  const HistoryTab({super.key, required this.userId});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<int> _userRankHistory = [];
  List<UserActivity> _activities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for changes from the provider
    Provider.of<RankingManager>(context).addListener(_handleDataChange);
  }

  void _handleDataChange() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final rankingManager = Provider.of<RankingManager>(
        context,
        listen: false,
      );

      // Fetch user rank history
      _userRankHistory = await rankingManager.getUserRankHistory(
        widget.userId,
        days: 7,
      );

      // Fetch user activities
      _activities = await rankingManager.getUserActivities(
        widget.userId,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activities.isEmpty && _userRankHistory.isEmpty) {
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
      itemCount: _activities.length + 1, // +1 for rank history section
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildRankHistorySection();
        }

        final activity = _activities[index - 1];
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
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    Provider.of<RankingManager>(
      context,
      listen: false,
    ).removeListener(_handleDataChange);
    super.dispose();
  }
}
