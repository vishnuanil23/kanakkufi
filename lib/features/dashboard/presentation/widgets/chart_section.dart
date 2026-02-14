import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/chart_utils.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../pregnancy/domain/pregnancy_chart_utils.dart';
import '../dashboard_state.dart';
import '../../../pregnancy/presentation/pregnancy_state.dart';

class ChartSection extends StatelessWidget {
  final DashboardState state;
  final PregnancyState pregnancyState;
  final bool showTrimesterTabs;

  const ChartSection({
    super.key,
    required this.state,
    required this.pregnancyState,
    required this.showTrimesterTabs,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => Container(
                    width: 40,
                    decoration: BoxDecoration(
                      color:
                          index % 2 == 0
                              ? AppColors.primary.withAlpha(10)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
              child: LineChart(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final List<String> titles;
                          if (showTrimesterTabs &&
                              state.viewType == AppStrings.viewTrimester) {
                            if (state.selectedPeriod ==
                                AppStrings.periodTrimester1) {
                              titles = [
                                AppStrings.wk2,
                                AppStrings.wk4,
                                AppStrings.wk6,
                                AppStrings.wk8,
                                AppStrings.wk10,
                                AppStrings.wk12,
                              ];
                            } else if (state.selectedPeriod ==
                                AppStrings.periodTrimester2) {
                              titles = [
                                AppStrings.wk14,
                                AppStrings.wk17,
                                AppStrings.wk20,
                                AppStrings.wk22,
                                AppStrings.wk25,
                                AppStrings.wk27,
                              ];
                            } else if (state.selectedPeriod ==
                                AppStrings.periodPregnancyAll) {
                              titles = [
                                AppStrings.axisT1,
                                AppStrings.axisT2,
                                AppStrings.axisT3,
                              ];
                            } else {
                              titles = [
                                AppStrings.wk29,
                                AppStrings.wk31,
                                AppStrings.wk33,
                                AppStrings.wk36,
                                AppStrings.wk38,
                                AppStrings.wk40,
                              ];
                            }
                          } else if (state.selectedPeriod ==
                              AppStrings.viewWeek) {
                            titles = [
                              AppStrings.mon,
                              AppStrings.tue,
                              AppStrings.wed,
                              AppStrings.thu,
                              AppStrings.fri,
                              AppStrings.sat,
                              AppStrings.sun,
                            ];
                          } else if (state.selectedPeriod ==
                              AppStrings.viewMonth) {
                            titles = [
                              AppStrings.wk1,
                              AppStrings.wk2,
                              AppStrings.wk3,
                              AppStrings.wk4,
                            ];
                          } else {
                            titles = ChartUtils.yearMonthLabels();
                          }

                          if (value.toInt() < titles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                titles[value.toInt()],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        interval: 1,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primary,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((barSpot) {
                          return LineTooltipItem(
                            '₹${barSpot.y.toStringAsFixed(2)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          state.viewType == AppStrings.viewTrimester
                              ? PregnancyChartUtils.buildChartSpots(
                                state: state,
                                pregnancyState: pregnancyState,
                              )
                              : ChartUtils.buildChartSpots(state: state),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter:
                            (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: AppColors.primary,
                                ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withAlpha(50),
                            AppColors.primary.withAlpha(0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
