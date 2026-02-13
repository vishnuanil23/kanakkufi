class ExpenseEntity {
  final String? id;
  final String userId;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String? note;

  const ExpenseEntity({
    this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.note,
  });
}
