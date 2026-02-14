import 'package:fl_chart/fl_chart.dart';

import '../presentation/dashboard_state.dart';
import '../../../../core/constants/app_strings.dart';

class ChartUtils {
  static List<FlSpot> buildChartSpots({required DashboardState state}) {
    final now = DateTime.now();
    final expenses =
        state.expenses.where((e) => e['dateTime'] is DateTime).toList();

    if (expenses.isEmpty) {
      return const [FlSpot(0, 0), FlSpot(1, 0)];
    }

    switch (state.selectedPeriod) {
      case AppStrings.viewWeek:
        final buckets = List<double>.filled(7, 0);
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        for (final e in expenses) {
          final date = e['dateTime'] as DateTime;
          if (date.isBefore(start) || date.isAfter(now)) continue;
          final index = date.weekday - 1; // Mon=0 ... Sun=6
          if (index >= 0 && index < 7) {
            buckets[index] += (e['amount'] as num).toDouble();
          }
        }
        return List.generate(7, (i) => FlSpot(i.toDouble(), buckets[i]));
      case AppStrings.viewMonth:
        final buckets = List<double>.filled(4, 0);
        for (final e in expenses) {
          final date = (e['dateTime'] as DateTime).toLocal();
          if (date.year != now.year || date.month != now.month) continue;
          final weekIndex = ((date.day - 1) ~/ 7).clamp(0, 3);
          buckets[weekIndex] += (e['amount'] as num).toDouble();
        }
        return List.generate(4, (i) => FlSpot(i.toDouble(), buckets[i]));
      case AppStrings.viewYear:
      default:
        final buckets = List<double>.filled(6, 0);
        final windowStartMonth = _yearWindowStartMonth();
        for (final e in expenses) {
          final date = e['dateTime'] as DateTime;
          if (date.year != now.year) continue;
          final index = date.month - windowStartMonth;
          if (index < 0 || index > 5) continue;
          buckets[index] += (e['amount'] as num).toDouble();
        }
        return List.generate(6, (i) => FlSpot(i.toDouble(), buckets[i]));
    }
  }

  static List<String> yearMonthLabels() {
    const months = [
      AppStrings.jan,
      AppStrings.feb,
      AppStrings.mar,
      AppStrings.apr,
      AppStrings.may,
      AppStrings.jun,
      AppStrings.jul,
      AppStrings.aug,
      AppStrings.sep,
      AppStrings.oct,
      AppStrings.nov,
      AppStrings.dec,
    ];
    final start = _yearWindowStartMonth(); // 1 or 7
    return List.generate(6, (i) => months[start - 1 + i]);
  }

  static int _yearWindowStartMonth() {
    final now = DateTime.now();
    return now.month <= 6 ? 1 : 7;
  }
}
