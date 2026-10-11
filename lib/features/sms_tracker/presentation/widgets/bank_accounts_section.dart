import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/sms_parser_service.dart';
import 'bank_account_tile.dart';

class BankAccountsSection extends StatelessWidget {
  final List<BankAccountBalance> accounts;
  final VoidCallback? onViewAll;

  const BankAccountsSection({
    super.key,
    required this.accounts,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();

    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final totalBalance = accounts.fold<double>(
      0.0,
      (sum, acc) => sum + acc.balance,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Bank Accounts',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    currencyFmt.format(totalBalance),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View SMS',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...accounts.map(
          (account) => BankAccountTile(
            account: account,
            onTap: onViewAll,
          ),
        ),
      ],
    );
  }
}
