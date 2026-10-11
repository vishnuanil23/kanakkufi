import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/pregnancy_report_entity.dart';

class TrimesterBreakdownSection extends StatelessWidget {
  final List<TrimesterSummary> summaries;
  final int? selectedTrimester;
  final int currentTrimester;
  final ValueChanged<int?> onTrimesterSelected;

  const TrimesterBreakdownSection({
    super.key,
    required this.summaries,
    required this.selectedTrimester,
    required this.currentTrimester,
    required this.onTrimesterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Trimester Breakdown",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            if (selectedTrimester != null)
              GestureDetector(
                onTap: () => onTrimesterSelected(null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.clear_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Show All",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: summaries.map((summary) {
            final isSelected = selectedTrimester == summary.trimester;
            final isCurrent = currentTrimester == summary.trimester;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildTrimesterCard(
                  context: context,
                  summary: summary,
                  isSelected: isSelected,
                  isCurrent: isCurrent,
                  onTap: () {
                    if (isSelected) {
                      onTrimesterSelected(null);
                    } else {
                      onTrimesterSelected(summary.trimester);
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrimesterCard({
    required BuildContext context,
    required TrimesterSummary summary,
    required bool isSelected,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final currencyFmt = NumberFormat('#,##0', 'en_IN');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDeep : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.goldBright
                    : (isCurrent
                        ? AppColors.accent.withAlpha(120)
                        : AppColors.border),
            width: isSelected || isCurrent ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? AppColors.primary.withAlpha(40)
                      : AppColors.shadow.withAlpha(6),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "T${summary.trimester}",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.goldBright : AppColors.primary,
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.accent.withAlpha(50)
                              : AppColors.accent.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "NOW",
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color:
                            isSelected
                                ? AppColors.goldLight
                                : AppColors.goldDark,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              summary.weekRange,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "₹${currencyFmt.format(summary.totalAmount)}",
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${summary.percentage.toStringAsFixed(0)}%",
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? AppColors.goldLight : AppColors.accent,
                  ),
                ),
                Text(
                  "${summary.count} bills",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w400,
                    color:
                        isSelected
                            ? Colors.white60
                            : AppColors.textSecondary.withAlpha(160),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
