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

  const AmountInputCard({
    super.key,
    required this.controller,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseCard(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 12,
      ),
      child: Row(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCurrency,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: GoogleFonts.inter(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(
                  value: "AED",
                  child: Text("AED"),
                ),
                DropdownMenuItem(
                  value: "INR",
                  child: Text("INR"),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                onCurrencyChanged(value);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
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
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
