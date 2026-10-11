import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/quote_service.dart';

class DashboardHookCard extends ConsumerWidget {
  const DashboardHookCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(quoteProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withAlpha(80)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 40,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.goldLight.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.goldDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: quoteAsync.when(
              data: (quote) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Spending Wisdom",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.navyDeep,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '“${quote.content}”',
                    style: GoogleFonts.inter(
                      color: AppColors.text,
                      fontSize: 13,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${quote.author}',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Spending Wisdom",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.navyDeep,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '“${Quote.defaultWisdom.content}”',
                    style: GoogleFonts.inter(
                      color: AppColors.text.withAlpha(180),
                      fontSize: 13,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${Quote.defaultWisdom.author}',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              error: (err, stack) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Spending Wisdom",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.navyDeep,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '“${Quote.defaultWisdom.content}”',
                    style: GoogleFonts.inter(
                      color: AppColors.text,
                      fontSize: 13,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${Quote.defaultWisdom.author}',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
