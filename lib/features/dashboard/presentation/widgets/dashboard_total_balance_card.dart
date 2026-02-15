import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/comparison_type.dart';

class DashboardTotalBalanceCard extends StatelessWidget {
  final double total;
  final String label;
  final double? monthlyChangePercent;
  final ComparisonType comparisonType;

  const DashboardTotalBalanceCard({
    super.key,
    required this.total,
    required this.label,
    this.monthlyChangePercent,
    this.comparisonType = ComparisonType.monthly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withAlpha(80),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navyMid, AppColors.sage],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.7, -0.6),
                    radius: 1.2,
                    colors: [AppColors.mint.withAlpha(80), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Text(
                        "KanakkuFi Premium",
                        style: GoogleFonts.inter(
                          color: Colors.white.withAlpha(200),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white.withAlpha(150),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [
                                AppColors.goldLight,
                                AppColors.goldBright,
                                AppColors.goldDark,
                              ],
                              stops: [0.0, 0.5, 1.0],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "₹ ",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'en_IN',
                                symbol: '',
                              ).format(total),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (monthlyChangePercent != null)
                              Row(
                                children: [
                                  Icon(
                                    monthlyChangePercent! >= 0
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    color:
                                        monthlyChangePercent! >= 0
                                            ? Colors.redAccent.withAlpha(200)
                                            : Colors.greenAccent.withAlpha(200),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${monthlyChangePercent!.abs().toStringAsFixed(1)}% "
                                    "${monthlyChangePercent! >= 0 ? 'more' : 'less'} than "
                                    "${comparisonType == ComparisonType.trimester ? 'last trimester' : 'last month'}",
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withAlpha(180),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
