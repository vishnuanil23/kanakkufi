import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import 'insight_card.dart';
import 'insights_generator.dart';

class InsightsSection extends StatelessWidget {
  final List<SpendingInsight> insights;
  final Function(SpendingInsight)? onInsightTap;

  const InsightsSection({
    super.key,
    required this.insights,
    this.onInsightTap,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(width: 8),
            Text(
              'Spending Insights',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 135,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: insights.length,
            itemBuilder: (context, index) {
              final insight = insights[index];
              return InsightCard(
                insight: insight,
                onTap: () => onInsightTap?.call(insight),
              );
            },
          ),
        ),
      ],
    );
  }
}
