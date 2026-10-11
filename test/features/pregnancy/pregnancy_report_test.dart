import 'package:flutter_test/flutter_test.dart';
import 'package:kanakkufi/features/pregnancy/domain/pregnancy_calculator.dart';
import 'package:kanakkufi/features/pregnancy/domain/pregnancy_entity.dart';
import 'package:kanakkufi/features/pregnancy/domain/pregnancy_report_entity.dart';
import 'package:kanakkufi/features/pregnancy/presentation/pregnancy_report_state.dart';

void main() {
  group('PregnancyCalculator tests', () {
    test('calculateTrimester returns correct trimester for weeks', () {
      expect(PregnancyCalculator.calculateTrimester(1), 1);
      expect(PregnancyCalculator.calculateTrimester(13), 1);
      expect(PregnancyCalculator.calculateTrimester(14), 2);
      expect(PregnancyCalculator.calculateTrimester(27), 2);
      expect(PregnancyCalculator.calculateTrimester(28), 3);
      expect(PregnancyCalculator.calculateTrimester(40), 3);
    });

    test('calculateWeekFromDate calculates relative weeks accurately', () {
      final startDate = DateTime(2026, 1, 1);
      final dateWk1 = DateTime(2026, 1, 3);
      final dateWk3 = DateTime(2026, 1, 16);

      expect(PregnancyCalculator.calculateWeekFromDate(dateWk1, startDate), 1);
      expect(PregnancyCalculator.calculateWeekFromDate(dateWk3, startDate), 3);
    });
  });

  group('PregnancyReportState filtering & sorting', () {
    final sampleProfile = PregnancyEntity(
      id: 'profile-1',
      userId: 'user-1',
      startDate: DateTime(2026, 1, 1),
      isActive: true,
    );

    final item1 = PregnancyExpenseItem(
      id: '1',
      title: 'Doctor',
      amount: 1500.0,
      date: '05 Jan, 2026',
      dateTime: DateTime(2026, 1, 5),
      note: 'Routine checkup',
      week: 1,
      trimester: 1,
    );

    final item2 = PregnancyExpenseItem(
      id: '2',
      title: 'Scan',
      amount: 3500.0,
      date: '15 Apr, 2026',
      dateTime: DateTime(2026, 4, 15),
      note: 'Anomaly scan',
      week: 16,
      trimester: 2,
    );

    final item3 = PregnancyExpenseItem(
      id: '3',
      title: 'Pharmacy',
      amount: 800.0,
      date: '20 Jul, 2026',
      dateTime: DateTime(2026, 7, 20),
      note: 'Supplements & Iron',
      week: 29,
      trimester: 3,
    );

    final reportData = PregnancyReportData(
      profile: sampleProfile,
      totalExpenses: 5800.0,
      currentWeek: 30,
      currentDay: 2,
      currentTrimester: 3,
      dueDate: DateTime(2026, 10, 8),
      daysRemaining: 70,
      progress: 0.75,
      trimesterSummaries: const [
        TrimesterSummary(
          trimester: 1,
          title: 'Trimester 1',
          weekRange: 'Weeks 1 – 13',
          totalAmount: 1500.0,
          count: 1,
          percentage: 25.86,
        ),
        TrimesterSummary(
          trimester: 2,
          title: 'Trimester 2',
          weekRange: 'Weeks 14 – 27',
          totalAmount: 3500.0,
          count: 1,
          percentage: 60.34,
        ),
        TrimesterSummary(
          trimester: 3,
          title: 'Trimester 3',
          weekRange: 'Weeks 28 – 40+',
          totalAmount: 800.0,
          count: 1,
          percentage: 13.80,
        ),
      ],
      categorySummaries: const [
        CategorySummary(
          categoryName: 'Scan',
          totalAmount: 3500.0,
          count: 1,
          percentage: 60.34,
        ),
        CategorySummary(
          categoryName: 'Doctor',
          totalAmount: 1500.0,
          count: 1,
          percentage: 25.86,
        ),
        CategorySummary(
          categoryName: 'Pharmacy',
          totalAmount: 800.0,
          count: 1,
          percentage: 13.80,
        ),
      ],
      allItems: [item1, item2, item3],
      averageWeeklySpend: 193.33,
      highestExpense: item2,
      transactionCount: 3,
    );

    test('filters items by trimester', () {
      final state = PregnancyReportState(
        reportData: reportData,
        selectedTrimester: 2,
      );

      expect(state.filteredItems.length, 1);
      expect(state.filteredItems.first.title, 'Scan');
      expect(state.filteredTotal, 3500.0);
    });

    test('filters items by category', () {
      final state = PregnancyReportState(
        reportData: reportData,
        selectedCategory: 'Doctor',
      );

      expect(state.filteredItems.length, 1);
      expect(state.filteredItems.first.title, 'Doctor');
      expect(state.filteredTotal, 1500.0);
    });

    test('filters items by search query', () {
      final state = PregnancyReportState(
        reportData: reportData,
        searchQuery: 'iron',
      );

      expect(state.filteredItems.length, 1);
      expect(state.filteredItems.first.title, 'Pharmacy');
    });

    test('sorts items by highest amount', () {
      final state = PregnancyReportState(
        reportData: reportData,
        sortOrder: PregnancySortOrder.highestAmount,
      );

      final items = state.filteredItems;
      expect(items[0].amount, 3500.0);
      expect(items[1].amount, 1500.0);
      expect(items[2].amount, 800.0);
    });
  });
}
