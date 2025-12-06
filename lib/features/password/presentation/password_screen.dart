import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/password_provider.dart';

class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({super.key});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final List<bool> _revealedBoxes = List.generate(8, (_) => false);

  void _resetGrid() {
    setState(() {
      _revealedBoxes.fillRange(0, 8, false);
    });
    ref.refresh(passwordProvider);
  }

  void _toggleBox(int index) {
    if (!_revealedBoxes[index]) {
      setState(() {
        _revealedBoxes[index] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(passwordProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      appBar: AppBar(
        title: const Text('تحدي الباسورد'),
        backgroundColor: AppColors.darkPitch,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/categories'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight * 0.9,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInstructions(),
                const SizedBox(height: 24),
                playersAsync.when(
                  data: (players) => _buildGrid(players),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.gameOnGreen),
                  ),
                  error: (err, _) => Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error,
                            color: Colors.red, size: 60),
                        const SizedBox(height: 10),
                        const Text('فشل تحميل اللاعبين',
                            style: TextStyle(color: Colors.white)),
                        Text('$err',
                            style:
                            const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => ref.refresh(passwordProvider),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildNewPlayersButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gameOnGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock,
            color: AppColors.gameOnGreen,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'تحدي الباسورد',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.gameOnGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على المربعات لتكشف أسماء اللاعبين. حاول تخمن الباسورد من خلال التعرف على النمط!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.lightGrey,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Player> players) {
    final crossAxisCount =
    MediaQuery.of(context).size.width > 600 ? 4 : 2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.brightGold.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: players.length,
        itemBuilder: (context, index) {
          return _buildGridBox(players[index], index);
        },
      ),
    );
  }

  Widget _buildGridBox(Player player, int index) {
    final isRevealed = _revealedBoxes[index];
    return GestureDetector(
      onTap: () => _toggleBox(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isRevealed
              ? AppColors.cardGradient
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.brightGold,
              AppColors.brightGold.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRevealed
                ? AppColors.grey.withOpacity(0.3)
                : AppColors.brightGold,
            width: 2,
          ),
        ),
        child: Center(
          child: isRevealed
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                color: AppColors.gameOnGreen,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                player.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gameOnGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
              : Text(
            '${index + 1}',
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewPlayersButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _resetGrid,
        icon: const Icon(Icons.refresh),
        label: const Text(
          'لاعبين جدد',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gameOnGreen,
          foregroundColor: AppColors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}