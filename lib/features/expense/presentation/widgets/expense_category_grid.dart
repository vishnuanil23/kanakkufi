import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../category/domain/category_entity.dart';
import 'expense_card.dart';

class ExpenseCategoryGrid extends StatelessWidget {
  final List<CategoryEntity> categories;
  final CategoryEntity selectedCategory;
  final ValueChanged<CategoryEntity> onSelected;

  const ExpenseCategoryGrid({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseCard(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory.id == category.id;

          return GestureDetector(
            onTap: () => onSelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(90),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                        : const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
              ),
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category.icon,
                      color: isSelected ? Colors.white : AppColors.accent,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
