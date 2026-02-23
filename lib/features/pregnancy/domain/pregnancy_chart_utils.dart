import 'package:fl_chart/fl_chart.dart';
import '../../dashboard/presentation/dashboard_state.dart';
import '../presentation/pregnancy_state.dart';
import '../domain/pregnancy_calculator.dart';
import '../../../../core/constants/app_strings.dart';

class PregnancyChartUtils {
  static List<FlSpot> buildChartSpots({
    required DashboardState state,
    required PregnancyState pregnancyState,
  }) {
    if (pregnancyState.profile == null || !pregnancyState.profile!.isActive) {
      return const [FlSpot(0, 0), FlSpot(1, 0)];
    }

    final startDate = pregnancyState.profile!.startDate;

    final expenses =
        state.expenses.where((e) => e['dateTime'] is DateTime).toList();

    if (expenses.isEmpty) {
      return const [FlSpot(0, 0), FlSpot(1, 0)];
    }

    if (state.selectedPeriod == AppStrings.periodPregnancyAll) {
      // 3 buckets for T1, T2, T3
      final buckets = List<double>.filled(3, 0);

      for (final e in expenses) {
        final date = e['dateTime'] as DateTime;
        final amount = (e['amount'] as num).toDouble();
        final pregnancyWeek = (date.difference(startDate).inDays ~/ 7) + 1;

        final trimester = PregnancyCalculator.calculateTrimester(pregnancyWeek);
        if (trimester == 1) {
          buckets[0] += amount;
        } else if (trimester == 2) {
          buckets[1] += amount;
        } else if (trimester == 3) {
          buckets[2] += amount;
        }
      }
      return List.generate(3, (i) => FlSpot(i.toDouble(), buckets[i]));
    }

    final config = _trimesterConfig(state.selectedPeriod);
    final startWeek = config.$1;
    final endWeek = config.$2;
    final bucketCount = config.$3;
    final totalWeeks = (endWeek - startWeek) + 1;
    final buckets = List<double>.filled(bucketCount, 0);

    for (final e in expenses) {
      final date = e['dateTime'] as DateTime;
      final amount = (e['amount'] as num).toDouble();

      // Calculate which week of pregnancy this expense falls into
      final pregnancyWeek = (date.difference(startDate).inDays ~/ 7) + 1;

      // Filter out expenses not in this trimester
      if (pregnancyWeek < startWeek || pregnancyWeek > endWeek) continue;

      final weekOffset = pregnancyWeek - startWeek;
      final index = ((weekOffset * bucketCount) ~/ totalWeeks).clamp(
        0,
        bucketCount - 1,
      );
      buckets[index] += amount;
    }

    return List.generate(bucketCount, (i) => FlSpot(i.toDouble(), buckets[i]));
  }

  static double calculateTotal({
    required List<Map<String, dynamic>> expenses,
    required String period,
    required DateTime startDate,
  }) {
    double total = 0.0;

    // For "All" in Pregnancy view, we just return sum of everything provided
    // (assuming the list passed is already filtered to pregnancy start date)
    if (period == AppStrings.periodPregnancyAll) {
      for (final e in expenses) {
        total += (e['amount'] as num).toDouble();
      }
      return total;
    }

    final config = _trimesterConfig(period);
    final startWeek = config.$1;
    final endWeek = config.$2;

    for (final e in expenses) {
      final date = e['dateTime'] as DateTime;
      final amount = (e['amount'] as num).toDouble();
      final pregnancyWeek = (date.difference(startDate).inDays ~/ 7) + 1;

      if (pregnancyWeek >= startWeek && pregnancyWeek <= endWeek) {
        total += amount;
      }
    }
    return total;
  }

  static (int, int, int) _trimesterConfig(String selectedPeriod) {
    if (selectedPeriod == AppStrings.periodTrimester1) {
      return (1, 13, 6);
    }
    if (selectedPeriod == AppStrings.periodTrimester2) {
      return (14, 27, 6);
    }
    // Trimester 3 cover rest
    return (28, 100, 6);
  }
}
