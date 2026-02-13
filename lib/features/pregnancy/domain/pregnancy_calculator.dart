class PregnancyCalculator {
  static DateTime calculateStartDate({
    required int week,
    required int day,
  }) {
    final totalDays = ((week - 1) * 7) + day;
    return DateTime.now().subtract(
      Duration(days: totalDays),
    );
  }

  static int calculateWeek(DateTime startDate) {
    final diff = DateTime.now().difference(startDate).inDays;
    return (diff ~/ 7) + 1;
  }

  static int calculateDay(DateTime startDate) {
    final diff = DateTime.now().difference(startDate).inDays;
    return diff % 7;
  }

  static int calculateTrimester(int week) {
    if (week <= 12) return 1;
    if (week <= 27) return 2;
    return 3;
  }
}
