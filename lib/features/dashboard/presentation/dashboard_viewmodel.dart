import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';
import 'dashboard_state.dart';
import '../../pregnancy/presentation/pregnancy_viewmodel.dart';
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
          };
        }).toList();

    final total = expenses.fold<double>(
      0.0,
      (sum, e) => sum + (e["amount"] as num),
    );

    state = state.copyWith(expenses: expenses, totalExpenses: total);
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
  }) {
    final item = {
      "title": title,
      "amount": amount,
      "date": DateFormat("dd MMM").format(date),
      "dateTime": date,
    };

    final updatedExpenses = [item, ...state.expenses];
    final updatedTotal = state.totalExpenses + amount;

    state = state.copyWith(
      expenses: updatedExpenses,
      totalExpenses: updatedTotal,
    );
  }

  void resetToDefaultView() {
    state = state.copyWith(
      viewType: AppStrings.viewAll,
      selectedPeriod: AppStrings.viewWeek,
    );
  }
}
