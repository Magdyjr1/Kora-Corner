import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/challenge_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';

class Top10Screen extends ConsumerWidget {
  const Top10Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(top10Provider);
    final notifier = ref.read(top10Provider.notifier);

    // Loading state
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkPitch,
        appBar: AppBar(
          title: const Text('Top 10'),
          backgroundColor: AppColors.darkPitch,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/categories'),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.gameOnGreen,
          ),
        ),
      );
    }

    // Error state
    if (state.error != null) {
      return Scaffold(
        backgroundColor: AppColors.darkPitch,
        appBar: AppBar(
          title: const Text('Top 10'),
          backgroundColor: AppColors.darkPitch,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/categories'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading question',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => notifier.refreshQuestion(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      appBar: AppBar(
        title: const Text('Top 10'),
        backgroundColor: AppColors.darkPitch,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/categories'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => notifier.refreshQuestion(),
            tooltip: 'New Question',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.resetSelection(),
            tooltip: 'Reset Selection',
          ),
        ],
      ),
      body: ResponsiveContainer(
        child: ResponsivePadding(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: Responsive.getSpacing(context)),
                _buildTeamContainers(context, state, notifier),
                SizedBox(height: Responsive.getSpacing(context)),
                _buildQuestionContainer(context, state.currentQuestion),
                SizedBox(height: Responsive.getSpacing(context) * 2),
                _buildPlayerList(context, state, notifier),
                SizedBox(height: Responsive.getSpacing(context) * 2),
                _buildSelectedCount(context, state),
                SizedBox(height: Responsive.getSpacing(context) * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamContainers(BuildContext context, Top10State state, Top10Notifier notifier) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (state.activeTeam != 1) notifier.switchTeam();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.getSpacing(context) * 0.75,
              ),
              decoration: BoxDecoration(
                color: state.activeTeam == 1
                    ? AppColors.gameOnGreen.withOpacity(0.2)
                    : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.activeTeam == 1
                      ? AppColors.gameOnGreen
                      : AppColors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  ResponsiveText(
                    'Team 1',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ResponsiveText(
                    '${state.team1Score} pts',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.gameOnGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: Responsive.getSpacing(context)),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (state.activeTeam != 2) notifier.switchTeam();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.getSpacing(context) * 0.75,
              ),
              decoration: BoxDecoration(
                color: state.activeTeam == 2
                    ? AppColors.gameOnGreen.withOpacity(0.2)
                    : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.activeTeam == 2
                      ? AppColors.gameOnGreen
                      : AppColors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  ResponsiveText(
                    'Team 2',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ResponsiveText(
                    '${state.team2Score} pts',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.gameOnGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionContainer(BuildContext context, String question) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.getSpacing(context) * 1.25),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gameOnGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.quiz,
                color: AppColors.gameOnGreen,
                size: Responsive.getSpacing(context) * 1.5,
              ),
              SizedBox(width: Responsive.getSpacing(context) * 0.5),
              ResponsiveText(
                'Question',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gameOnGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.getSpacing(context)),
          ResponsiveText(
            question,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(BuildContext context, Top10State state, Top10Notifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: List.generate(state.players.length, (index) {
          final isSelected = state.selectedPlayers.length > index
              ? state.selectedPlayers[index]
              : false;
          return _buildPlayerItem(
            context,
            index + 1,
            state.players[index],
            isSelected,
                () => notifier.togglePlayer(index),
          );
        }),
      ),
    );
  }

  Widget _buildPlayerItem(
      BuildContext context,
      int rank,
      String playerName,
      bool isSelected,
      VoidCallback onTap,
      ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(Responsive.getSpacing(context)),
            child: Row(
              children: [
                // Rank Circle
                Container(
                  width: Responsive.getAvatarSize(context),
                  height: Responsive.getAvatarSize(context),
                  decoration: BoxDecoration(
                    color: AppColors.brightGold,
                    borderRadius: BorderRadius.circular(
                        Responsive.getAvatarSize(context) / 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brightGold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ResponsiveText(
                      '$rank',
                      style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.getSpacing(context)),
                // Player Name
                Expanded(
                  child: ResponsiveText(
                    playerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: Responsive.getSpacing(context)),
                // Check Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: Responsive.getAvatarSize(context),
                  height: Responsive.getAvatarSize(context),
                  decoration: BoxDecoration(
                    color:
                    isSelected ? AppColors.gameOnGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                        Responsive.getAvatarSize(context) / 2),
                    border: Border.all(
                      color: AppColors.gameOnGreen,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                    Icons.check,
                    color: AppColors.black,
                    size: Responsive.getSpacing(context) * 1.25,
                  )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCount(BuildContext context, Top10State state) {
    final selectedCount =
        state.selectedPlayers.where((selected) => selected).length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.getSpacing(context) * 1.25),
      decoration: BoxDecoration(
        color: selectedCount > 0
            ? AppColors.gameOnGreen.withOpacity(0.1)
            : const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedCount > 0
              ? AppColors.gameOnGreen
              : AppColors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: selectedCount > 0 ? AppColors.gameOnGreen : AppColors.grey,
            size: Responsive.getSpacing(context) * 1.5,
          ),
          SizedBox(width: Responsive.getSpacing(context) * 0.5),
          ResponsiveText(
            'Selected: $selectedCount / ${state.players.length} players',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: selectedCount > 0
                  ? AppColors.gameOnGreen
                  : AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}