import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import 'ThreeInOneScreen.dart';

class ThreeInOneSetupScreen extends StatefulWidget {
  const ThreeInOneSetupScreen({super.key});

  @override
  State<ThreeInOneSetupScreen> createState() => _ThreeInOneSetupScreenState();
}

class _ThreeInOneSetupScreenState extends State<ThreeInOneSetupScreen> {
  final List<TextEditingController> _playerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  
  final List<FocusNode> _focusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];

  @override
  void dispose() {
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    bool allPlayersNamed = _playerControllers.every(
          (controller) => controller.text.trim().isNotEmpty,
    );

    if (!allPlayersNamed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter all player names'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThreeInOneScreen(
          playerNames: _playerControllers.map((c) => c.text.trim()).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      appBar: AppBar(
        title: const Text('3 في 1'),
        backgroundColor: AppColors.darkPitch,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ResponsiveContainer(
        child: ResponsivePadding(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: Responsive.getSpacing(context)),
                _buildPlayerContainers(),
                SizedBox(height: Responsive.getSpacing(context) * 2),
                _buildGameRulesContainer(),
                SizedBox(height: Responsive.getSpacing(context) * 2),
                _buildStartGameButton(),
                SizedBox(height: Responsive.getSpacing(context) * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerContainers() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: Responsive.getSpacing(context)),
          child: _buildPlayerContainer(index + 1),
        );
      }),
    );
  }

  Widget _buildPlayerContainer(int playerNumber) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.getSpacing(context) * 1.25),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'أدخل اسم اللاعب $playerNumber',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: Responsive.getSpacing(context)),
          TextFormField(
            controller: _playerControllers[playerNumber - 1],
            focusNode: _focusNodes[playerNumber - 1],
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.gameOnGreen,
                  width: 2,
                ),
              ),
              hintText: 'Player $playerNumber Name',
              hintStyle: const TextStyle(
                color: AppColors.grey,
                fontSize: 14,
              ),
              contentPadding: EdgeInsets.all(Responsive.getSpacing(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameRulesContainer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.getSpacing(context) * 1.25),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brightGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rule,
                color: AppColors.brightGold,
                size: Responsive.getSpacing(context) * 1.5,
              ),
              SizedBox(width: Responsive.getSpacing(context) * 0.5),
              ResponsiveText(
                'Game Rules',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brightGold,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.getSpacing(context)),
          ResponsiveText(
            '• Each player gets 3 chances to answer questions correctly\n'
            '• Correct answers earn points based on difficulty\n'
            '• Wrong answers result in penalty points\n'
            '• The player with the highest score wins',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.lightGrey,
              height: 1.5,
            ),
          ),
          SizedBox(height: Responsive.getSpacing(context)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Responsive.getSpacing(context)),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF3030).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Penalty Rules:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF3030),
                  ),
                ),
                SizedBox(height: Responsive.getSpacing(context) * 0.5),
                _buildPenaltyRule('Red Card', '-3 points'),
                _buildPenaltyRule('Yellow Card', '-1 point'),
                _buildPenaltyRule('Wrong Answer', '-2 points'),
                _buildPenaltyRule('Time Out', '-1 point'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyRule(String penalty, String points) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.getSpacing(context) * 0.25),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: const Color(0xFFFF3030),
            size: Responsive.getSpacing(context) * 0.75,
          ),
          SizedBox(width: Responsive.getSpacing(context) * 0.5),
          ResponsiveText(
            '$penalty = $points',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFFF3030),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartGameButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gameOnGreen,
          foregroundColor: AppColors.black,
          padding: EdgeInsets.symmetric(vertical: Responsive.getSpacing(context) * 1.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppColors.gameOnGreen.withOpacity(0.3),
        ),
        child: ResponsiveText(
          'ابدأ اللعب',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
