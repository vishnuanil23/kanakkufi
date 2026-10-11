import 'pregnancy_entity.dart';

class PregnancyExpenseItem {
  final dynamic id;
  final String title;
  final double amount;
  final String date;
  final DateTime dateTime;
  final String? note;
  final int week;
  final int trimester;

  const PregnancyExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.dateTime,
    this.note,
    required this.week,
    required this.trimester,
  });
}

class TrimesterSummary {
  final int trimester;
  final String title;
  final String weekRange;
  final double totalAmount;
  final int count;
  final double percentage;

  const TrimesterSummary({
    required this.trimester,
    required this.title,
    required this.weekRange,
    required this.totalAmount,
    required this.count,
    required this.percentage,
  });
}

class CategorySummary {
  final String categoryName;
  final double totalAmount;
  final int count;
  final double percentage;

  const CategorySummary({
    required this.categoryName,
    required this.totalAmount,
    required this.count,
    required this.percentage,
  });
}

class PregnancyReportData {
  final PregnancyEntity profile;
  final double totalExpenses;
  final int currentWeek;
  final int currentDay;
  final int currentTrimester;
  final DateTime dueDate;
  final int daysRemaining;
  final double progress;
  final List<TrimesterSummary> trimesterSummaries;
  final List<CategorySummary> categorySummaries;
  final List<PregnancyExpenseItem> allItems;
  final double averageWeeklySpend;
  final PregnancyExpenseItem? highestExpense;
  final int transactionCount;

  const PregnancyReportData({
    required this.profile,
    required this.totalExpenses,
    required this.currentWeek,
    required this.currentDay,
    required this.currentTrimester,
    required this.dueDate,
    required this.daysRemaining,
    required this.progress,
    required this.trimesterSummaries,
    required this.categorySummaries,
    required this.allItems,
    required this.averageWeeklySpend,
    this.highestExpense,
    required this.transactionCount,
  });
}
