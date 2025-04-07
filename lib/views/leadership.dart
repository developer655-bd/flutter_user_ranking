import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../logics/manager.dart';
import '../logics/user_stats.dart';


class LeaderboardTab extends StatefulWidget {
  final String userId;

  const LeaderboardTab({
    super.key,
    required this.userId,
  });

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  List<UserStats> _topUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      _topUsers = await rankingManager.getTopUsers(limit: 10);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboard: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    final rankingManager = Provider.of<RankingManager>(
      context,
      listen: false,
    );
    await rankingManager.refreshData();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                  if (user.userId == widget.userId)
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

  @override
  void dispose() {
    // Remove listener when widget is disposed
    Provider.of<RankingManager>(context, listen: false)
        .removeListener(_handleDataChange);
    super.dispose();
  }
}