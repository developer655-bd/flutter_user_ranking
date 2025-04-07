// widgets/profile_tab.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../manager.dart';
import '../user_stats.dart';

class ProfileTab extends StatefulWidget {
  final String userId;

  const ProfileTab({super.key, required this.userId});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserStats? _currentStats;
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

      // Fetch current user stats
      _currentStats = await rankingManager.getUserStats(widget.userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentStats == null) {
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
              _currentStats!.profileImageUrl,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentStats!.username,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Rank #${_currentStats!.rank}',
            style: const TextStyle(fontSize: 18, color: Colors.blue),
          ),
          const SizedBox(height: 24),
          _buildStatCard(
            'Total Points',
            '${_currentStats!.totalPoints}',
            Icons.score,
            Colors.orange,
          ),
          _buildStatCard(
            'Current Streak',
            '${_currentStats!.streak} days',
            Icons.local_fire_department,
            Colors.red,
          ),
          _buildStatCard(
            'Lessons Completed',
            '${_currentStats!.lessonsCompleted}',
            Icons.book,
            Colors.green,
          ),
          _buildStatCard(
            'Words Learned',
            '${_currentStats!.wordsLearned}',
            Icons.translate,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final rankingManager = Provider.of<RankingManager>(
                context,
                listen: false,
              );
              await rankingManager.updateStreak(widget.userId);
              await _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Streak updated!')),
                );
              }
            },
            icon: const Icon(Icons.update),
            label: const Text('Update Streak'),
          ),
          const SizedBox(height: 8),
          Text(
            'Last Updated: ${DateFormat('MMM d, yyyy h:mm a').format(_currentStats!.lastUpdated)}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
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
