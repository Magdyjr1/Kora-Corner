import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';

class ManualScoringPanel extends StatefulWidget {
  const ManualScoringPanel({super.key});

  @override
  State<ManualScoringPanel> createState() => _ManualScoringPanelState();
}

class _ManualScoringPanelState extends State<ManualScoringPanel> {
  final TextEditingController _team1Controller = TextEditingController();
  final TextEditingController _team2Controller = TextEditingController();
  final FocusNode _team1Focus = FocusNode();
  final FocusNode _team2Focus = FocusNode();

  @override
  void initState() {
    super.initState();

    // تحديث الواجهة كل ما حالة الفوكس تتغير
    _team1Focus.addListener(() => setState(() {}));
    _team2Focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    _team1Focus.dispose();
    _team2Focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.getSpacing(context),
        vertical: Responsive.getSpacing(context) * 0.75,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTeamSection(
              context,
              'الفريق الأول',
              _team1Controller,
              _team1Focus,
            ),
          ),
          SizedBox(width: Responsive.getSpacing(context) * 0.75),
          Expanded(
            child: _buildTeamSection(
              context,
              'الفريق الثاني',
              _team2Controller,
              _team2Focus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(
      BuildContext context,
      String teamLabel,
      TextEditingController controller,
      FocusNode focusNode,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          teamLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: Responsive.getSpacing(context) * 0.5),

        Container(
          width: double.infinity,
          height: Responsive.isMobile(context) ? 50 : 55,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            style: TextStyle(
              color: AppColors.brightGold,
              fontSize: Responsive.getBodySize(context) * 1.2,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: Responsive.getSpacing(context) * 0.5,
                vertical: Responsive.getSpacing(context) * 0.5,
              ),

              // 🔥 hint يختفي أول ما الفيلد ياخد فوكس
              hintText: focusNode.hasFocus ? '' : '0',
              hintStyle: TextStyle(
                color: AppColors.brightGold.withOpacity(0.5),
                fontSize: Responsive.getBodySize(context) * 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
