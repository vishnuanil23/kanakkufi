import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class AmountSummaryCard extends StatelessWidget {
  final String displayAmount;
  final String category;

  const AmountSummaryCard({
    super.key,
    required this.displayAmount,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(24),
      decoration: _buildGradientCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Amount",
            style: GoogleFonts.inter(
              color: Colors.white.withAlpha(170),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              "₹ $displayAmount",
              key: ValueKey(displayAmount),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(36),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              category,
              style: GoogleFonts.inter(
                color: Colors.white.withAlpha(220),
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildGradientCardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.navyDeep,
          AppColors.navyMid,
          AppColors.sage,
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.navyDeep.withAlpha(80),
          blurRadius: 30,
          offset: const Offset(0, 18),
        ),
      ],
    );
  }
}
