import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../domain/pregnancy_calculator.dart';
import '../domain/pregnancy_report_entity.dart';
import 'pregnancy_report_state.dart';
import 'pregnancy_viewmodel.dart';
import '../../dashboard/presentation/dashboard_viewmodel.dart';

final pregnancyReportProvider =
    StateNotifierProvider<PregnancyReportViewModel, PregnancyReportState>(
  (ref) => PregnancyReportViewModel(ref),
);

class PregnancyReportViewModel extends StateNotifier<PregnancyReportState> {
  final Ref ref;

  PregnancyReportViewModel(this.ref) : super(const PregnancyReportState()) {
    fetchReport();
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> fetchReport() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not logged in',
        );
        return;
      }

      // Ensure pregnancy profile is up to date
      var pregnancyState = ref.read(pregnancyProvider);
      if (pregnancyState.profile == null) {
        await ref.read(pregnancyProvider.notifier).fetchActiveProfile();
        pregnancyState = ref.read(pregnancyProvider);
      }

      final profile = pregnancyState.profile;
      if (profile == null || !profile.isActive) {
        state = state.copyWith(
          isLoading: false,
          reportData: null,
          errorMessage: 'Pregnancy Mode is not currently enabled.',
        );
        return;
      }

      final startDate = profile.startDate;
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);

      // Fetch all expenses from pregnancy start date onwards
      final data = await _client
          .from(AppStrings.tableExpenses)
          .select()
          .eq(AppStrings.colUserId, userId)
          .gte(AppStrings.colExpenseDate, formattedStartDate)
          .order(AppStrings.colExpenseDate, ascending: false);

      final rawList = data as List<dynamic>;

      final List<PregnancyExpenseItem> items = [];
      for (final item in rawList) {
        final dateTime =
            DateTime.parse(item[AppStrings.colExpenseDate]).toLocal();

        final week = PregnancyCalculator.calculateWeekFromDate(
          dateTime,
          startDate,
        );

        // Filter only expenses occurring during pregnancy (week >= 1)
        if (week >= 1) {
          final trimester = PregnancyCalculator.calculateTrimester(week);
          items.add(
            PregnancyExpenseItem(
              id: item[AppStrings.colId],
              title: item[AppStrings.colCategory]?.toString() ?? 'Other',
              amount: (item[AppStrings.colAmount] as num).toDouble(),
              date: DateFormat('dd MMM, yyyy').format(dateTime),
              dateTime: dateTime,
              note: item[AppStrings.colNote]?.toString(),
              week: week,
              trimester: trimester,
            ),
          );
        }
      }

      // Calculate totals
      final totalExpenses = items.fold<double>(
        0.0,
        (sum, item) => sum + item.amount,
      );

      // Trimester summaries (1, 2, 3)
      final List<TrimesterSummary> trimesterSummaries = [];
      final trimesterConfigs = [
        (1, 'Trimester 1', 'Weeks 1 – 13'),
        (2, 'Trimester 2', 'Weeks 14 – 27'),
        (3, 'Trimester 3', 'Weeks 28 – 40+'),
      ];

      for (final config in trimesterConfigs) {
        final trimesterNum = config.$1;
        final tItems = items.where((it) => it.trimester == trimesterNum);
        final tTotal = tItems.fold<double>(0.0, (sum, it) => sum + it.amount);
        final tCount = tItems.length;
        final tPercent = totalExpenses > 0 ? (tTotal / totalExpenses) * 100 : 0.0;

        trimesterSummaries.add(
          TrimesterSummary(
            trimester: trimesterNum,
            title: config.$2,
            weekRange: config.$3,
            totalAmount: tTotal,
            count: tCount,
            percentage: tPercent,
          ),
        );
      }

      // Category breakdown
      final Map<String, List<PregnancyExpenseItem>> categoryMap = {};
      for (final it in items) {
        categoryMap.putIfAbsent(it.title, () => []).add(it);
      }

      final List<CategorySummary> categorySummaries = [];
      categoryMap.forEach((categoryName, catItems) {
        final catTotal = catItems.fold<double>(
          0.0,
          (sum, it) => sum + it.amount,
        );
        final catCount = catItems.length;
        final catPercent =
            totalExpenses > 0 ? (catTotal / totalExpenses) * 100 : 0.0;

        categorySummaries.add(
          CategorySummary(
            categoryName: categoryName,
            totalAmount: catTotal,
            count: catCount,
            percentage: catPercent,
          ),
        );
      });
      // Sort categories by highest spend first
      categorySummaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      // Pregnancy Timeline calculation
      final currentWeek = PregnancyCalculator.calculateWeek(startDate);
      final currentDay = PregnancyCalculator.calculateDay(startDate);
      final currentTrimester = PregnancyCalculator.calculateTrimester(currentWeek);
      final dueDate = startDate.add(const Duration(days: 280));
      final daysRemaining = dueDate.difference(DateTime.now()).inDays.clamp(0, 280);
      final progress = (currentWeek / 40.0).clamp(0.0, 1.0);

      final averageWeeklySpend =
          currentWeek > 0 ? (totalExpenses / currentWeek) : totalExpenses;

      PregnancyExpenseItem? highestExpense;
      if (items.isNotEmpty) {
        highestExpense = items.reduce(
          (curr, next) => curr.amount > next.amount ? curr : next,
        );
      }

      final reportData = PregnancyReportData(
        profile: profile,
        totalExpenses: totalExpenses,
        currentWeek: currentWeek,
        currentDay: currentDay,
        currentTrimester: currentTrimester,
        dueDate: dueDate,
        daysRemaining: daysRemaining,
        progress: progress,
        trimesterSummaries: trimesterSummaries,
        categorySummaries: categorySummaries,
        allItems: items,
        averageWeeklySpend: averageWeeklySpend,
        highestExpense: highestExpense,
        transactionCount: items.length,
      );

      state = state.copyWith(
        isLoading: false,
        reportData: reportData,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load pregnancy report: $e',
      );
    }
  }

  void filterByTrimester(int? trimester) {
    if (state.selectedTrimester == trimester) {
      // Toggle off if already active
      state = state.copyWith(clearTrimester: true);
    } else {
      state = state.copyWith(selectedTrimester: trimester);
    }
  }

  void filterByCategory(String? category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOrder(PregnancySortOrder order) {
    state = state.copyWith(sortOrder: order);
  }

  Future<void> deleteExpense(dynamic id) async {
    try {
      await _client
          .from(AppStrings.tableExpenses)
          .delete()
          .eq(AppStrings.colId, id);

      // Refresh both report and dashboard
      await fetchReport();
      ref.read(dashboardProvider.notifier).fetchExpenses();
    } catch (_) {
      rethrow;
    }
  }

  String getFormattedReportText() {
    final data = state.reportData;
    if (data == null) return 'No report data available.';

    final currencyFmt = NumberFormat('#,##0.00', 'en_IN');
    final dateFmt = DateFormat('dd MMM yyyy');

    final buffer = StringBuffer();
    buffer.writeln('🤰 KanakkuFi • Pregnancy Expense Report');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🗓️ Date Generated: ${dateFmt.format(DateTime.now())}');
    buffer.writeln(
      '👶 Timeline: Week ${data.currentWeek} (Day ${data.currentDay}) • Trimester ${data.currentTrimester}',
    );
    buffer.writeln('🎯 Est. Due Date: ${dateFmt.format(data.dueDate)}');
    buffer.writeln('💰 Total Pregnancy Spend: ₹${currencyFmt.format(data.totalExpenses)}');
    buffer.writeln('📊 Avg Spend/Week: ₹${currencyFmt.format(data.averageWeeklySpend)}');
    buffer.writeln('📝 Total Bills: ${data.transactionCount}');
    buffer.writeln();
    buffer.writeln('📈 Trimester Breakdown:');
    for (final t in data.trimesterSummaries) {
      buffer.writeln(
        '  • ${t.title} (${t.weekRange}): ₹${currencyFmt.format(t.totalAmount)} (${t.percentage.toStringAsFixed(1)}%) • ${t.count} bills',
      );
    }
    buffer.writeln();
    buffer.writeln('🏥 Category Breakdown:');
    for (final c in data.categorySummaries) {
      buffer.writeln(
        '  • ${c.categoryName}: ₹${currencyFmt.format(c.totalAmount)} (${c.percentage.toStringAsFixed(1)}%) • ${c.count} bills',
      );
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buffer.toString();
  }
}
