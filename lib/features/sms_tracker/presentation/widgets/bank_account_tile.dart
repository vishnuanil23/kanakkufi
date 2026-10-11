import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/sms_parser_service.dart';

class BankAccountTile extends StatelessWidget {
  final BankAccountBalance account;
  final VoidCallback? onTap;

  const BankAccountTile({
    super.key,
    required this.account,
    this.onTap,
  });

  Color _getBankColor(String bank) {
    final lower = bank.toLowerCase();
    if (lower.contains('sbi')) return const Color(0xFF1B1464);
    if (lower.contains('hdfc')) return const Color(0xFF004F8A);
    if (lower.contains('icici')) return const Color(0xFFC0392B);
    if (lower.contains('axis')) return const Color(0xFF80164B);
    if (lower.contains('kotak')) return const Color(0xFFD92128);
    if (lower.contains('pnb')) return const Color(0xFFA20000);
    return AppColors.primary;
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bankColor = _getBankColor(account.bankName);
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final isUp = account.trend == '↑';
    final isDown = account.trend == '↓';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Bank avatar circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bankColor.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: bankColor.withAlpha(40), width: 1.5),
              ),
              child: Center(
                child: Text(
                  account.bankName.length >= 2
                      ? account.bankName.substring(0, 2).toUpperCase()
                      : account.bankName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: bankColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Bank name and account number
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.bankName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'A/c •• ${account.accountLast4}',
                        style: GoogleFonts.firaCode(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${_formatTimeAgo(account.lastUpdated)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Balance and trend
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFmt.format(account.balance),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp
                          ? Icons.arrow_upward_rounded
                          : isDown
                              ? Icons.arrow_downward_rounded
                              : Icons.remove_rounded,
                      size: 13,
                      color: isUp
                          ? const Color(0xFF10B981)
                          : isDown
                              ? const Color(0xFFEF4444)
                              : Colors.grey,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      isUp
                          ? 'Received'
                          : isDown
                              ? 'Spent'
                              : 'Active',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isUp
                            ? const Color(0xFF10B981)
                            : isDown
                                ? const Color(0xFFEF4444)
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
