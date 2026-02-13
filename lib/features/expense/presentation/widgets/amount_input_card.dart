import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import 'expense_card.dart';

class AmountInputCard extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const AmountInputCard({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseCard(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 12,
      ),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(
                decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r'^\d+\.?\d{0,2}'),
          )
        ],
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          hintText: "Amount",
          hintStyle: GoogleFonts.inter(
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          prefixText: "₹ ",
          prefixStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
