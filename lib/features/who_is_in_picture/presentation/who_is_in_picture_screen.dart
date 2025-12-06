import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/challenge_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../widgets/manual_scoring_panel.dart';
import '../../../ads/banner_ad_widget.dart';
import '../../../ads/ads_manager.dart';

class WhoIsInPictureScreen extends ConsumerWidget {
  const WhoIsInPictureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pictureChallengeProvider);
    final notifier = ref.read(pictureChallengeProvider.notifier);
    final metrics = _LayoutMetrics.resolve(context);

    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      appBar: AppBar(
        title: const Text('Who Is In The Picture'),
        backgroundColor: AppColors.darkPitch,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/categories'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.resetChallenge(),
            tooltip: 'Reset Challenge',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ResponsiveContainer(
                child: ResponsivePadding(
                  child: state.error != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: metrics.sectionSpacing),
                Text(
                  'حدث خطأ في تحميل البيانات',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: metrics.compactSpacing),
                Text(
                  state.error!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: metrics.sectionSpacing * 1.5),
                ElevatedButton(
                  onPressed: () => notifier.resetChallenge(),
                  child: Text('إعادة المحاولة'),
                ),
              ],
            ),
          )
              : state.isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: AppColors.gameOnGreen,
            ),
          )
              : !state.categorySelected
              ? _buildCategorySelection(context, notifier, metrics)
              : LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: metrics.sectionSpacing),
                      const ManualScoringPanel(),
                      SizedBox(height: metrics.sectionSpacing),
                      _buildProgressIndicator(context, state, metrics),
                      SizedBox(height: metrics.sectionSpacing),
                      _buildImageContainer(context, state, metrics),
                      SizedBox(height: metrics.sectionSpacing * 1.3),
                      _buildRevealButton(context, state, notifier, metrics),
                      SizedBox(height: metrics.spacing),
                      if (state.namesRevealed) ...[
                        _buildPlayerNameContainer(context, state, metrics),
                        SizedBox(height: metrics.sectionSpacing),
                      ],
                      _buildNavigationButtons(context, state, notifier, metrics),
                      SizedBox(height: metrics.sectionSpacing),
                    ],
                  ),
                ),
              );
            },
          ),
                ),
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelection(
      BuildContext context,
      PictureChallengeNotifier notifier,
      _LayoutMetrics metrics,
      ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category,
            size: 80,
            color: AppColors.brightGold,
          ),
          SizedBox(height: metrics.sectionSpacing),
          ResponsiveText(
            'اختر فئة اللاعبين',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: metrics.sectionSpacing * 1.5),
          _buildCategoryButton(
            context,
            'محلي',
            Icons.home,
                () => notifier.selectCategory('محلي'),
            metrics,
          ),
          SizedBox(height: metrics.spacing),
          _buildCategoryButton(
            context,
            'أجنبي',
            Icons.public,
                () => notifier.selectCategory('أجنبي'),
            metrics,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
      BuildContext context,
      String label,
      IconData icon,
      VoidCallback onPressed,
      _LayoutMetrics metrics,
      ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * metrics.buttonWidthFactor,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gameOnGreen,
          foregroundColor: AppColors.black,
          padding:
          EdgeInsets.symmetric(vertical: metrics.buttonPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppColors.gameOnGreen.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            SizedBox(width: metrics.spacing),
            ResponsiveText(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
      BuildContext context,
      PictureChallengeState state,
      _LayoutMetrics metrics,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWrap = constraints.maxWidth < 380;
        final children = <Widget>[
          Icon(
            Icons.person,
            color: AppColors.brightGold,
            size: 20,
          ),
          SizedBox(width: metrics.compactSpacing * 0.5),
          ResponsiveText(
            'اللاعب ${state.currentIndex + 1} من ${state.players.length}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: metrics.spacing),
          Icon(
            Icons.category,
            color: AppColors.gameOnGreen,
            size: 20,
          ),
          SizedBox(width: metrics.compactSpacing * 0.5),
          ResponsiveText(
            state.selectedCategory,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.gameOnGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ];

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.cardPadding,
            vertical: metrics.compactSpacing,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brightGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: useWrap
              ? Wrap(
            spacing: metrics.compactSpacing,
            runSpacing: metrics.compactSpacing * 0.75,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        );
      },
    );
  }

  Widget _buildImageContainer(
      BuildContext context, PictureChallengeState state, _LayoutMetrics metrics) {
    final currentPlayer = state.currentPlayer;

    return Container(
      width: double.infinity,
      height: metrics.imageHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // صورة اللاعب من Supabase
            if (currentPlayer?.url != null && currentPlayer!.url.isNotEmpty)
              Image.network(
                currentPlayer.url,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(context);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gameOnGreen,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              )
            else
              _buildPlaceholder(context),
            // Overlay مع السؤال
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(metrics.spacing),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: ResponsiveText(
                  'من هو اللاعب في الصورة؟',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gameOnGreen.withOpacity(0.3),
            AppColors.brightGold.withOpacity(0.3),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.sports_soccer,
          size: 80,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildRevealButton(
      BuildContext context,
      PictureChallengeState state,
      PictureChallengeNotifier notifier,
      _LayoutMetrics metrics,
      ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => notifier.toggleNamesReveal(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gameOnGreen,
          foregroundColor: AppColors.black,
          padding: EdgeInsets.symmetric(
              vertical: metrics.buttonPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppColors.gameOnGreen.withOpacity(0.3),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: metrics.compactSpacing * 0.5,
          children: [
            Icon(
              state.namesRevealed ? Icons.visibility_off : Icons.visibility,
              size: metrics.spacing * 1.2,
            ),
            ResponsiveText(
              state.namesRevealed ? 'إخفاء الاسم' : 'إظهار الاسم',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerNameContainer(
      BuildContext context,
      PictureChallengeState state,
      _LayoutMetrics metrics,
      ) {
    final currentPlayer = state.currentPlayer;
    if (currentPlayer == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: metrics.buttonPadding,
        horizontal: metrics.cardPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brightGold.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final icon = Icon(
            Icons.person_search,
            color: AppColors.brightGold,
            size: metrics.nameIconSize,
          );
          final text = ResponsiveText(
            currentPlayer.playerName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.brightGold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          );

          if (isCompact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                SizedBox(height: metrics.compactSpacing),
                text,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(width: metrics.spacing),
              Flexible(child: text),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context,
      PictureChallengeState state,
      PictureChallengeNotifier notifier,
      _LayoutMetrics metrics,
      ) {
    return Row(
      children: [
        // زر السابق
        Expanded(
          child: ElevatedButton(
            onPressed: state.currentIndex > 0
                ? () => notifier.previousPlayer()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.grey,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.grey.withOpacity(0.3),
              padding: EdgeInsets.symmetric(
                  vertical: metrics.buttonPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, size: 20),
                SizedBox(width: metrics.compactSpacing * 0.5),
                ResponsiveText(
                  'السابق',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: metrics.spacing),
        // زر التالي أو تجديد
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: state.isLastPlayer
                ? () => notifier.refreshPlayers()
                : () {
                    notifier.nextPlayer();
                    // Track image viewed for interstitial ad (shows after every 11 images)
                    AdsManager.instance.trackImageViewed();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: state.isLastPlayer
                  ? AppColors.brightGold
                  : AppColors.gameOnGreen,
              foregroundColor: AppColors.black,
              padding: EdgeInsets.symmetric(
                  vertical: metrics.buttonPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveText(
                  state.isLastPlayer ? 'لعبة جديدة' : 'التالي',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: metrics.compactSpacing * 0.5),
                Icon(
                  state.isLastPlayer ? Icons.refresh : Icons.arrow_forward,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


}

class _LayoutMetrics {
  _LayoutMetrics({
    required this.spacing,
    required this.sectionSpacing,
    required this.compactSpacing,
    required this.buttonPadding,
    required this.cardPadding,
    required this.imageHeight,
    required this.buttonWidthFactor,
    required this.nameIconSize,
  });

  factory _LayoutMetrics.resolve(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final spacing = Responsive.getSpacing(context);
    final isTablet = size.width >= 600;
    final isDesktop = size.width >= 1024;

    return _LayoutMetrics(
      spacing: spacing,
      sectionSpacing: spacing * (isTablet ? 1.4 : 1.2),
      compactSpacing: spacing * 0.75,
      buttonPadding: spacing * (isTablet ? 1.05 : 0.9),
      cardPadding: spacing * (isTablet ? 1.25 : 1),
      imageHeight: size.height * (isTablet ? 0.42 : 0.36),
      buttonWidthFactor: isDesktop ? 0.35 : (isTablet ? 0.55 : 0.8),
      nameIconSize: spacing * (isTablet ? 2.2 : 1.8),
    );
  }

  final double spacing;
  final double sectionSpacing;
  final double compactSpacing;
  final double buttonPadding;
  final double cardPadding;
  final double imageHeight;
  final double buttonWidthFactor;
  final double nameIconSize;
}