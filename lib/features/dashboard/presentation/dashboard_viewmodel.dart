import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_state.dart';

final dashboardProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>(
      (ref) => DashboardViewModel(),
    );

class DashboardViewModel extends StateNotifier<DashboardState> {
  DashboardViewModel() : super(const DashboardState()) {
    _initializeData();
  }

  void _initializeData() {
    final expenses = [
      {"title": "Scan Visit", "amount": 2500.0, "date": "12 Feb"},
      {"title": "Supplements", "amount": 1200.0, "date": "11 Feb"},
      {"title": "Doctor Consultation", "amount": 800.0, "date": "10 Feb"},
      {"title": "Pharmacy", "amount": 450.0, "date": "09 Feb"},
    ];

    final total = expenses.fold<double>(
      0.0,
      (sum, e) => sum + (e["amount"] as num),
    );

    state = state.copyWith(expenses: expenses, totalExpenses: total);
  }

  void changeViewType(String type) {
    state = state.copyWith(
      viewType: type,
      selectedPeriod: type == 'Trimester' ? 'Trimester 1' : 'Week',
    );
  }

  void changePeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
  }
}
