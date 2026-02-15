class ExpenseComparisonService {
  static double calculatePercentageChange({
    required double current,
    required double previous,
  }) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }
}
