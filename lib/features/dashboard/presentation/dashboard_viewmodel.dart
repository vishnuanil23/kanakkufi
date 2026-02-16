import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';
import 'dashboard_state.dart';
import '../../pregnancy/presentation/pregnancy_viewmodel.dart';
import '../../pregnancy/domain/pregnancy_chart_utils.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/enums/comparison_type.dart';
import '../../../core/services/expense_comparison_service.dart';
import '../../pregnancy/domain/pregnancy_calculator.dart';

final dashboardProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>(
      (ref) => DashboardViewModel(ref),
    );

class DashboardViewModel extends StateNotifier<DashboardState> {
  final Ref ref;

  DashboardViewModel(this.ref) : super(const DashboardState()) {
    fetchExpenses();
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> fetchExpenses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();
    DateTime startRange;

    final pregnancyState = ref.read(pregnancyProvider);
    final isPregnancyActive =
        pregnancyState.profile != null && pregnancyState.profile!.isActive;

    // Always fetch from at least the previous month for standard trends
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);

    if (isPregnancyActive) {
      // Fetch from earlier of: pregnancy start OR previous month start
      final pStart = pregnancyState.profile!.startDate;
      startRange = pStart.isBefore(prevMonthStart) ? pStart : prevMonthStart;
    } else {
      startRange = prevMonthStart;
    }

    final endRange = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

    final data = await _client
        .from(AppStrings.tableExpenses)
        .select()
        .eq(AppStrings.colUserId, userId)
        .gte(
          AppStrings.colExpenseDate,
          DateFormat('yyyy-MM-dd').format(startRange),
        )
        .lte(
          AppStrings.colExpenseDate,
          DateFormat('yyyy-MM-dd').format(endRange),
        )
        .order(AppStrings.colExpenseDate, ascending: false);

    final expenses =
        (data as List<dynamic>).map<Map<String, dynamic>>((item) {
          final dateTime =
              DateTime.parse(item[AppStrings.colExpenseDate]).toLocal();
          return {
            "id": item[AppStrings.colId],
            "title": item[AppStrings.colCategory].toString(),
            "amount": (item[AppStrings.colAmount] as num).toDouble(),
            "date": DateFormat("dd MMM").format(dateTime),
            "dateTime": dateTime,
            "note": item[AppStrings.colNote],
          };
        }).toList();

    _updateStateWithExpenses(expenses);
  }

  double get currentMonthTotal {
    final now = DateTime.now();
    return state.expenses
        .where(
          (e) =>
              (e["dateTime"] as DateTime).month == now.month &&
              (e["dateTime"] as DateTime).year == now.year,
        )
        .fold(0.0, (sum, e) => sum + (e["amount"] as num));
  }

  double get previousMonthTotal {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1);
    return state.expenses
        .where(
          (e) =>
              (e["dateTime"] as DateTime).month == prev.month &&
              (e["dateTime"] as DateTime).year == prev.year,
        )
        .fold(0.0, (sum, e) => sum + (e["amount"] as num));
  }

  double? get expenseComparisonPercent {
    if (state.viewType == AppStrings.viewTrimester) {
      return _trimesterComparison();
    } else {
      return _monthlyComparison();
    }
  }

  ComparisonType get comparisonType {
    return state.viewType == AppStrings.viewTrimester
        ? ComparisonType.trimester
        : ComparisonType.monthly;
  }

  double? _monthlyComparison() {
    final prev = previousMonthTotal;
    final current = currentMonthTotal;
    if (prev == 0) return null;
    return ExpenseComparisonService.calculatePercentageChange(
      current: current,
      previous: prev,
    );
  }

  double? _trimesterComparison() {
    final pregnancyState = ref.read(pregnancyProvider);
    if (pregnancyState.profile == null) return null;

    final week = PregnancyCalculator.calculateWeek(
      pregnancyState.profile!.startDate,
    );
    final currentTrimester = PregnancyCalculator.calculateTrimester(week);
    final previousTrimester = currentTrimester - 1;

    if (previousTrimester < 1) return null;

    final current = _calculateTotalForTrimester(
      currentTrimester,
      pregnancyState.profile!.startDate,
    );
    final previous = _calculateTotalForTrimester(
      previousTrimester,
      pregnancyState.profile!.startDate,
    );

    if (previous == 0) return null;

    return ExpenseComparisonService.calculatePercentageChange(
      current: current,
      previous: previous,
    );
  }

  double _calculateTotalForTrimester(int trimester, DateTime startDate) {
    return state.expenses
        .where((e) {
          final date = e["dateTime"] as DateTime;
          final week = PregnancyCalculator.calculateWeekFromDate(
            date,
            startDate,
          );
          return PregnancyCalculator.calculateTrimester(week) == trimester;
        })
        .fold(0.0, (sum, e) => sum + (e["amount"] as num));
  }

  ({double total, double displayTotal, String label}) _calculateViewData(
    List<Map<String, dynamic>> expenses,
  ) {
    // Filter display total based on current view/period
    final now = DateTime.now();
    List<Map<String, dynamic>> filteredExpenses;

    if (state.viewType == AppStrings.viewTrimester) {
      filteredExpenses = expenses; // Pregnancy does its own calculation
    } else if (state.selectedPeriod == AppStrings.viewYear) {
      filteredExpenses =
          expenses
              .where((e) => (e["dateTime"] as DateTime).year == now.year)
              .toList();
    } else {
      // Month or Week view for current month
      filteredExpenses =
          expenses
              .where(
                (e) =>
                    (e["dateTime"] as DateTime).month == now.month &&
                    (e["dateTime"] as DateTime).year == now.year,
              )
              .toList();
    }

    final total = filteredExpenses.fold<double>(
      0.0,
      (sum, e) => sum + (e["amount"] as num),
    );

    double displayTotal = total;
    String label = "Total Monthly Spend";

    if (state.viewType == AppStrings.viewTrimester) {
      final pregnancyState = ref.read(pregnancyProvider);
      if (pregnancyState.profile != null && pregnancyState.profile!.isActive) {
        displayTotal = PregnancyChartUtils.calculateTotal(
          expenses: expenses,
          period: state.selectedPeriod,
          startDate: pregnancyState.profile!.startDate,
        );
      }
      label = "Total ${state.selectedPeriod} Spend";
    } else if (state.selectedPeriod == AppStrings.viewYear) {
      label = "Total Yearly Spend";
    } else if (state.selectedPeriod == AppStrings.viewWeek) {
      label = "Total Monthly Spend";
    }

    return (total: total, displayTotal: displayTotal, label: label);
  }

  void changeViewType(String type) {
    final normalizedType =
        type == AppStrings.viewPregnancy ? AppStrings.viewTrimester : type;
    state = state.copyWith(
      viewType: normalizedType,
      selectedPeriod:
          normalizedType == AppStrings.viewTrimester
              ? AppStrings.periodTrimester1
              : AppStrings.viewWeek,
    );
    fetchExpenses();
  }

  void changePeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
    fetchExpenses();
  }

  void _updateStateWithExpenses(List<Map<String, dynamic>> expenses) {
    final viewData = _calculateViewData(expenses);
    state = state.copyWith(
      expenses: expenses,
      totalExpenses: viewData.total,
      displayTotal: viewData.displayTotal,
      totalLabel: viewData.label,
    );
  }

  Future<void> deleteExpense(dynamic id) async {
    final previousExpenses = List<Map<String, dynamic>>.from(state.expenses);

    // Optimistic remove
    final updatedExpenses =
        state.expenses
            .where((e) => e["id"].toString() != id.toString())
            .toList();
    _updateStateWithExpenses(updatedExpenses);

    try {
      await _client
          .from(AppStrings.tableExpenses)
          .delete()
          .eq(AppStrings.colId, id);
    } catch (e) {
      // Rollback
      state = state.copyWith(expenses: previousExpenses);
      // Recalculate with previous
      _updateStateWithExpenses(previousExpenses);
      rethrow;
    }
  }

  Future<void> updateExpense({
    required dynamic id,
    required String category,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final previousExpenses = List<Map<String, dynamic>>.from(state.expenses);

    // Optimistic update
    final updatedExpenses =
        state.expenses.map((e) {
          if (e["id"].toString() == id.toString()) {
            return {
              "id": id,
              "title": category,
              "amount": amount,
              "date": DateFormat("dd MMM").format(date),
              "dateTime": date,
              "note": note,
            };
          }
          return e;
        }).toList();

    _updateStateWithExpenses(updatedExpenses);

    try {
      final updateData = {
        AppStrings.colCategory: category,
        AppStrings.colAmount: amount,
        AppStrings.colExpenseDate: DateFormat('yyyy-MM-dd').format(date),
        AppStrings.colNote: (note == null || note.isEmpty) ? null : note,
      };

      await _client
          .from(AppStrings.tableExpenses)
          .update(updateData)
          .eq(AppStrings.colId, id);
    } catch (e) {
      // Rollback
      _updateStateWithExpenses(previousExpenses);
      rethrow;
    }
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response =
          await _client
              .from(AppStrings.tableExpenses)
              .insert({
                AppStrings.colUserId: userId,
                AppStrings.colCategory: title,
                AppStrings.colAmount: amount,
                AppStrings.colExpenseDate: DateFormat(
                  'yyyy-MM-dd',
                ).format(date),
                AppStrings.colNote: note,
              })
              .select()
              .single();

      final item = {
        "id": response[AppStrings.colId],
        "title": title,
        "amount": amount,
        "date": DateFormat("dd MMM").format(date),
        "dateTime": date,
        "note": note,
      };

      final updatedExpenses = [item, ...state.expenses];
      _updateStateWithExpenses(updatedExpenses);
    } catch (e) {
      fetchExpenses();
      rethrow;
    }
  }

  void resetToDefaultView() {
    state = state.copyWith(
      viewType: AppStrings.viewAll,
      selectedPeriod: AppStrings.viewWeek,
    );
  }
}
