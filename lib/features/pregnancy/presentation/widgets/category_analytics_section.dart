import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../category/domain/category_entity.dart';
import '../../domain/pregnancy_report_entity.dart';

class CategoryAnalyticsSection extends StatelessWidget {
  final List<CategorySummary> summaries;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryAnalyticsSection({
    super.key,
    required this.summaries,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  Color _getCategoryColor(String name) {
    switch (name.toLowerCase()) {
      case 'doctor':
        return const Color(0xFF2563EB); // Royal Blue
      case 'pharmacy':
        return const Color(0xFF059669); // Emerald Green
      case 'scan':
        return const Color(0xFF7C3AED); // Purple
      case 'hospital':
        return const Color(0xFFE11D48); // Rose / Crimson
      case 'baby care':
        return const Color(0xFFD97706); // Amber / Warm Orange
      case 'nutrition':
        return const Color(0xFF10B981); // Mint Green
      case 'laboratory':
        return const Color(0xFF4F46E5); // Indigo
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    final currencyFmt = NumberFormat('#,##0', 'en_IN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Category Analytics",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            if (selectedCategory != null)
              GestureDetector(
                onTap: () => onCategorySelected(null),
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
                        "All Categories",
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

        // Visual Proportion Bar
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.withAlpha(30),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: summaries.map((summary) {
              final flex = (summary.percentage * 10).toInt();
              if (flex <= 0) return const SizedBox.shrink();
              return Expanded(
                flex: flex,
                child: Container(
                  color: _getCategoryColor(summary.categoryName),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Category Cards List / Wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: summaries.map((summary) {
            final isSelected =
                selectedCategory?.toLowerCase() ==
                summary.categoryName.toLowerCase();
            final category = getCategoryByName(summary.categoryName);
            final color = _getCategoryColor(summary.categoryName);

            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  onCategorySelected(null);
                } else {
                  onCategorySelected(summary.categoryName);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyDeep : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.goldBright : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.white.withAlpha(25)
                                : color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        category.icon,
                        size: 16,
                        color: isSelected ? AppColors.goldBright : color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          summary.categoryName,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.text,
                          ),
                        ),
                        Text(
                          "₹${currencyFmt.format(summary.totalAmount)} • ${summary.percentage.toStringAsFixed(0)}%",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                isSelected
                                    ? AppColors.goldLight
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
