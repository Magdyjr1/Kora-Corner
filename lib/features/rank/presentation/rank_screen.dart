import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/persistent_bottom_nav_bar.dart';

class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      body: SafeArea(
        child: Column(
          children: [
            // Title Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Text(
                'الترتيب',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brightGold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Leaderboard Content
            Expanded(
              child: _LeaderboardList(currentUserId: 'user4'),
            ),
            const PersistentBottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final String currentUserId;

  const _LeaderboardList({required this.currentUserId});

  // Mock leaderboard data
  final List<Map<String, dynamic>> _leaderboardData = const [
    {'rank': 1, 'username': 'علي', 'points': 8450, 'id': 'user1'},
    {'rank': 2, 'username': 'مجدي', 'points': 7820, 'id': 'user2'},
    {'rank': 3, 'username': 'عوني', 'points': 6950, 'id': 'user3'},
    {'rank': 4, 'username': 'Ahmed ', 'points': 1250, 'id': 'user4'},
    {'rank': 5, 'username': 'مؤمن', 'points': 1180, 'id': 'user5'},
    {'rank': 6, 'username': 'ابوتريكة', 'points': 980, 'id': 'user6'},
    {'rank': 7, 'username': 'ارتيتا', 'points': 850, 'id': 'user7'},
    {'rank': 8, 'username': 'كريم', 'points': 720, 'id': 'user8'},
    {'rank': 9, 'username': 'عمر', 'points': 650, 'id': 'user9'},
    {'rank': 10, 'username': 'شيكابالا', 'points': 580, 'id': 'user10'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _leaderboardData.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final player = _leaderboardData[index];
        final isCurrentUser = player['id'] == currentUserId;
        return _LeaderboardRow(
          rank: player['rank'],
          username: player['username'],
          points: player['points'],
          isCurrentUser: isCurrentUser,
        );
      },
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String username;
  final int points;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.rank,
    required this.username,
    required this.points,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTopThree = rank <= 3;
    final Color backgroundColor = isCurrentUser
        ? AppColors.gameOnGreen.withOpacity(0.1)
        : ((rank % 2 == 0) ? AppColors.darkPitch : AppColors.darkCardSecondary);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.gameOnGreen, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank Column
          SizedBox(
            width: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (isTopThree)
                  Icon(
                    _getRankIcon(rank),
                    color: _getRankColor(rank),
                    size: 28,
                  )
                else
                  Text(
                    '$rank',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightGrey,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Username Column
          Expanded(
            child: Text(
              username,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                color: isCurrentUser ? AppColors.gameOnGreen : AppColors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Points Column
          Text(
            '${_formatPoints(points)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTopThree ? AppColors.brightGold : AppColors.lightGrey,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.looks_one_rounded;
      case 2:
        return Icons.looks_two_rounded;
      case 3:
        return Icons.looks_3_rounded;
      default:
        return Icons.circle;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade300; // Gold for 1st
      case 2:
        return Colors.grey.shade300; // Silver for 2nd
      case 3:
        return Colors.brown.shade300; // Bronze for 3rd
      default:
        return AppColors.lightGrey;
    }
  }

  String _formatPoints(int points) {
    if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    return points.toString();
  }
}

