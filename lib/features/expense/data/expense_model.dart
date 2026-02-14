import '../domain/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    super.id,
    required super.userId,
    required super.category,
    required super.amount,
    required super.expenseDate,
    super.note,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id']?.toString(),
      userId: json['user_id'].toString(),
      category: json['category'].toString(),
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expense_date']),
      note: json['note']?.toString(),
    );
  }

  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      userId: entity.userId,
      category: entity.category,
      amount: entity.amount,
      expenseDate: entity.expenseDate,
      note: entity.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate.toUtc().toIso8601String(),
      'note': note,
    };
  }
}
