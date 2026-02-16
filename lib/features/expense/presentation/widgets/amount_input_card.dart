import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import 'expense_card.dart';

class AmountInputCard extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final bool hasError;

  const AmountInputCard({
    super.key,
    required this.controller,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseCard(
      borderColor: hasError ? AppColors.error : null,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCurrency,
              icon: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.text,
                ),
              ),
              style: GoogleFonts.inter(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              items: const [
                DropdownMenuItem(value: "AED", child: Text("AED")),
                DropdownMenuItem(value: "INR", child: Text("INR")),
              ],
              onChanged: (value) {
                if (value == null) return;
                onCurrencyChanged(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: "0.00",
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary.withAlpha(120),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
