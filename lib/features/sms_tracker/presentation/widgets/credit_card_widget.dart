import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/sms_parser_service.dart';

class CreditCardWidget extends StatelessWidget {
  final CreditCardDetails card;
  final VoidCallback? onTap;

  const CreditCardWidget({
    super.key,
    required this.card,
    this.onTap,
  });

  // Unique bank theme gradients
  (LinearGradient, Color) _getBankTheme(String bank) {
    final lower = bank.toLowerCase();
    if (lower.contains('hdfc')) {
      return (
        const LinearGradient(
          colors: [Color(0xFF002B49), Color(0xFF004F8A), Color(0xFF1B75BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        const Color(0xFF00A3E0),
      );
    } else if (lower.contains('icici')) {
      return (
        const LinearGradient(
          colors: [Color(0xFF8B2500), Color(0xFFC0392B), Color(0xFFE67E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        const Color(0xFFF39C12),
      );
    } else if (lower.contains('sbi')) {
      return (
        const LinearGradient(
          colors: [Color(0xFF1B1464), Color(0xFF2E3192), Color(0xFF0071BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        const Color(0xFF29ABE2),
      );
    } else if (lower.contains('axis')) {
      return (
        const LinearGradient(
          colors: [Color(0xFF4A0E2E), Color(0xFF80164B), Color(0xFF9E1B58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        const Color(0xFFE91E63),
      );
    }
    // Sleek obsidian / graphite
    return (
      const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const Color(0xFF94A3B8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (gradient, accentColor) = _getBankTheme(card.bankName);
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final utilization = (card.utilizationRate * 100).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 180,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha(90),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Bank name, EMV chip icon, Contactless
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Metallic chip representation
                    Container(
                      width: 32,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFB8860B), width: 1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.memory,
                          size: 16,
                          color: Colors.brown.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.contactless_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
                Text(
                  card.bankName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            // Middle: Card Number Masked
            Text(
              '••••  ••••  ••••  ${card.cardLast4}',
              style: GoogleFonts.firaCode(
                color: Colors.white.withAlpha(220),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),

            // Bottom: Due Amount, Due Date & Utilization
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL DUE',
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFmt.format(card.totalDue),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (card.dueDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withAlpha(50),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Due ${card.dueDate}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Utilization Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: card.utilizationRate,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      utilization > 75 ? const Color(0xFFEF4444) : accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
