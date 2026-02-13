import 'package:fl_chart/fl_chart.dart';
import '../../pregnancy/presentation/pregnancy_state.dart';
import '../presentation/dashboard_state.dart';

class ChartUtils {
  static List<FlSpot> buildChartSpots({
    required DashboardState state,
    required PregnancyState pregnancyState,
  }) {
    final now = DateTime.now();
    final expenses =
        state.expenses.where((e) => e['dateTime'] is DateTime).toList();

    if (expenses.isEmpty) {
      return const [FlSpot(0, 0), FlSpot(1, 0)];
    }

    if (state.viewType == 'Trimester' && pregnancyState.profile != null) {
      final config = _trimesterConfig(state.selectedPeriod);
      final startWeek = config.$1;
      final endWeek = config.$2;
      final bucketCount = config.$3;
      final startDate = pregnancyState.profile!.startDate;
      final totalWeeks = (endWeek - startWeek) + 1;
      final buckets = List<double>.filled(bucketCount, 0);

      for (final e in expenses) {
        final date = e['dateTime'] as DateTime;
        final amount = (e['amount'] as num).toDouble();
        final pregnancyWeek = (date.difference(startDate).inDays ~/ 7) + 1;
        if (pregnancyWeek < startWeek || pregnancyWeek > endWeek) continue;

        final weekOffset = pregnancyWeek - startWeek;
        final index = ((weekOffset * bucketCount) ~/ totalWeeks)
            .clamp(0, bucketCount - 1);
        buckets[index] += amount;
      }

      return List.generate(
        bucketCount,
        (i) => FlSpot(i.toDouble(), buckets[i]),
      );
    }

    switch (state.selectedPeriod) {
      case 'Week':
        final buckets = List<double>.filled(7, 0);
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        for (final e in expenses) {
          final date = e['dateTime'] as DateTime;
          if (date.isBefore(start) || date.isAfter(now)) continue;
          final index = date.weekday - 1; // Mon=0 ... Sun=6
          if (index >= 0 && index < 7) {
            buckets[index] += (e['amount'] as num).toDouble();
          }
        }
        return List.generate(7, (i) => FlSpot(i.toDouble(), buckets[i]));
      case 'Month':
        final buckets = List<double>.filled(4, 0);
        for (final e in expenses) {
          final date = e['dateTime'] as DateTime;
          if (date.year != now.year || date.month != now.month) continue;
          final weekIndex = ((date.day - 1) ~/ 7).clamp(0, 3);
          buckets[weekIndex] += (e['amount'] as num).toDouble();
        }
        return List.generate(4, (i) => FlSpot(i.toDouble(), buckets[i]));
      case 'Year':
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final start = _yearWindowStartMonth(); // 1 or 7
    return List.generate(6, (i) => months[start - 1 + i]);
  }

  static int _yearWindowStartMonth() {
    final now = DateTime.now();
    return now.month <= 6 ? 1 : 7;
  }

  static (int, int, int) _trimesterConfig(String selectedPeriod) {
    if (selectedPeriod == 'Trimester 1') {
      return (1, 13, 4);
    }
    if (selectedPeriod == 'Trimester 2') {
      return (14, 27, 5);
    }
    return (28, 40, 4);
  }
}
