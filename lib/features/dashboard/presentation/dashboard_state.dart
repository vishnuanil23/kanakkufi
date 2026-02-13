class DashboardState {
  final String selectedPeriod;
  final String viewType;
  final List<Map<String, dynamic>> expenses;
  final double totalExpenses;

  const DashboardState({
    this.selectedPeriod = 'Week',
    this.viewType = 'Monthly',
    this.expenses = const [],
    this.totalExpenses = 0.0,
  });

  DashboardState copyWith({
    String? selectedPeriod,
    String? viewType,
    List<Map<String, dynamic>>? expenses,
    double? totalExpenses,
  }) {
    return DashboardState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      viewType: viewType ?? this.viewType,
      expenses: expenses ?? this.expenses,
      totalExpenses: totalExpenses ?? this.totalExpenses,
    );
  }
}
