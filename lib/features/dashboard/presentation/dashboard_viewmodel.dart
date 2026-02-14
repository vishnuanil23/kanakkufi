import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';
import 'dashboard_state.dart';
import '../../pregnancy/presentation/pregnancy_viewmodel.dart';
import '../../pregnancy/domain/pregnancy_chart_utils.dart';
import '../../../core/constants/app_strings.dart';

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
    DateTime endRange = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

    // efficient data fetching based on view type
    if (state.viewType == AppStrings.viewTrimester) {
      // For pregnancy view, we need data from the start of pregnancy
      // Access pregnancy state to get start date
      final pregnancyState = ref.read(pregnancyProvider);
      if (pregnancyState.profile != null && pregnancyState.profile!.isActive) {
        startRange = pregnancyState.profile!.startDate;
        // End range is today (or future if we allow future expenses, but usually today)
        endRange = now;
      } else {
        // Fallback if no active pregnancy profile, just show current year or month
        startRange = DateTime(now.year, 1, 1);
      }
    } else {
      // Standard view: Handle differently based on period
      if (state.selectedPeriod == AppStrings.viewYear) {
        startRange = DateTime(now.year, 1, 1);
      } else {
        // Default to current month for Month/Week initially
        startRange = DateTime(now.year, now.month, 1);
      }
    }

    final data = await _client
        .from(AppStrings.tableExpenses)
        .select()
        .eq(AppStrings.colUserId, userId)
        .gte(AppStrings.colExpenseDate, startRange.toUtc().toIso8601String())
        .lte(AppStrings.colExpenseDate, endRange.toUtc().toIso8601String())
        .order(AppStrings.colExpenseDate, ascending: false);

    final expenses =
        (data as List<dynamic>).map<Map<String, dynamic>>((item) {
          final dateTime =
              DateTime.parse(item[AppStrings.colExpenseDate]).toLocal();
          return {
            "title": item[AppStrings.colCategory].toString(),
            "amount": (item[AppStrings.colAmount] as num).toDouble(),
            "date": DateFormat("dd MMM").format(dateTime),
            "dateTime": dateTime,
            "note": item[AppStrings.colNote],
          };
        }).toList();

    final viewData = _calculateViewData(expenses);
    state = state.copyWith(
      expenses: expenses,
      totalExpenses: viewData.total,
      displayTotal: viewData.displayTotal,
      totalLabel: viewData.label,
    );
  }

  ({double total, double displayTotal, String label}) _calculateViewData(
    List<Map<String, dynamic>> expenses,
  ) {
    final total = expenses.fold<double>(
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
      // Keep Monthly label or change? Existing logic was: "Total Monthly Spend" for everything else.
      // But let's check DashboardScreen logic:
      // state.selectedPeriod == AppStrings.viewYear ? "Toal Yearly Spend" : "Total Monthly Spend"
      // So for Week it was "Total Monthly Spend".
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

  void addExpense({
    required String title,
    required double amount,
    required DateTime date,
    String? note,
  }) {
    final item = {
      "title": title,
      "amount": amount,
      "date": DateFormat("dd MMM").format(date),
      "dateTime": date,
      "note": note,
    };

    final updatedExpenses = [item, ...state.expenses];
    final viewData = _calculateViewData(updatedExpenses);

    state = state.copyWith(
      expenses: updatedExpenses,
      totalExpenses: viewData.total,
      displayTotal: viewData.displayTotal,
      totalLabel: viewData.label,
    );
  }

  void resetToDefaultView() {
    state = state.copyWith(
      viewType: AppStrings.viewAll,
      selectedPeriod: AppStrings.viewWeek,
    );
  }
}
