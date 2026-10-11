import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanakkufi/features/pregnancy/domain/pregnancy_report_entity.dart';
import 'package:kanakkufi/features/pregnancy/presentation/widgets/pregnancy_expense_list_item.dart';
import 'package:kanakkufi/features/pregnancy/presentation/widgets/pregnancy_report_banner.dart';

void main() {
  testWidgets('PregnancyReportBanner renders correctly and triggers tap', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PregnancyReportBanner(
            week: 16,
            trimester: 2,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Pregnancy Expenses Alone'), findsOneWidget);
    expect(find.text('• Wk 16 (T2)'), findsOneWidget);

    await tester.tap(find.byType(PregnancyReportBanner));
    expect(tapped, isTrue);
  });

  testWidgets('PregnancyExpenseListItem displays item details and week badge', (
    WidgetTester tester,
  ) async {
    final item = PregnancyExpenseItem(
      id: 'item-1',
      title: 'Doctor',
      amount: 1200.0,
      date: '10 Feb, 2026',
      dateTime: DateTime(2026, 2, 10),
      note: 'Dr. Sarah Consultation',
      week: 12,
      trimester: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PregnancyExpenseListItem(item: item),
        ),
      ),
    );

    expect(find.text('Doctor'), findsOneWidget);
    expect(find.text('Wk 12 • T1'), findsOneWidget);
    expect(find.text('Dr. Sarah Consultation'), findsOneWidget);
    expect(find.text('10 Feb, 2026'), findsOneWidget);
    expect(find.text('₹1,200.00'), findsOneWidget);
  });
}
