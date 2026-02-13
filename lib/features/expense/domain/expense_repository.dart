import 'expense_entity.dart';

abstract class ExpenseRepository {
  Future<void> addExpense(ExpenseEntity expense);
}
