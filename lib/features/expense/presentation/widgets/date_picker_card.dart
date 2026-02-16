import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import 'expense_card.dart';

class DatePickerCard extends StatelessWidget {
  final String formattedDate;
  final VoidCallback onTap;

  const DatePickerCard({
    super.key,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _DatePickerBody(formattedDate: formattedDate),
    );
  }
}

class _DatePickerBody extends StatelessWidget {
  const _DatePickerBody({required this.formattedDate});

  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    return ExpenseCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 18,
            color: AppColors.text,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              formattedDate,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            size: 20,
            color: AppColors.text,
          ),
        ],
      ),
    );
  }
}
