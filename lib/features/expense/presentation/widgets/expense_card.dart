import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ExpenseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const ExpenseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            borderColor != null
                ? Border.all(color: borderColor!, width: 2)
                : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
