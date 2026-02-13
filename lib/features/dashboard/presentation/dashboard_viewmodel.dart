import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';
import 'dashboard_state.dart';

final dashboardProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>(
      (ref) => DashboardViewModel(ref),
    );

class DashboardViewModel extends StateNotifier<DashboardState> {
  final Ref ref;

  DashboardViewModel(this.ref) : super(const DashboardState()) {
    fetchExpenses();
  }

  SupabaseClient get _client =>
      ref.read(supabaseClientProvider);

  Future<void> fetchExpenses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final data = await _client
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .order('expense_date', ascending: false)
        .limit(10);

    final expenses =
        (data as List<dynamic>).map<Map<String, dynamic>>((item) {
          final dateTime = DateTime.parse(item['expense_date']);
          return {
            "title": item['category'].toString(),
            "amount": (item['amount'] as num).toDouble(),
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
    final normalizedType = type == 'Pregnancy' ? 'Trimester' : type;
    state = state.copyWith(
      viewType: normalizedType,
      selectedPeriod: normalizedType == 'Trimester' ? 'Trimester 1' : 'Week',
    );
  }

  void changePeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
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
      viewType: 'All',
      selectedPeriod: 'Week',
    );
  }
}
