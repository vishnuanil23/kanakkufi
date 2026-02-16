class DashboardState {
  final String selectedPeriod;
  final String viewType;
  final List<Map<String, dynamic>> expenses;
  final double totalExpenses;
  final double displayTotal;
  final String totalLabel;

  const DashboardState({
    this.selectedPeriod = 'Week',
    this.viewType = 'All',
    this.expenses = const [],
    this.totalExpenses = 0.0,
    this.displayTotal = 0.0,
    this.totalLabel = 'Total Monthly Spend',
  });

  DashboardState copyWith({
    String? selectedPeriod,
    String? viewType,
    List<Map<String, dynamic>>? expenses,
    double? totalExpenses,
    double? displayTotal,
    String? totalLabel,
  }) {
    return DashboardState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      viewType: viewType ?? this.viewType,
      expenses: expenses ?? this.expenses,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      displayTotal: displayTotal ?? this.displayTotal,
      totalLabel: totalLabel ?? this.totalLabel,
    );
  }
}
