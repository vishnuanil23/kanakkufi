import '../domain/expense_entity.dart';
import '../domain/expense_repository.dart';
import 'expense_remote_datasource.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remote;

  ExpenseRepositoryImpl(this.remote);

  @override
  Future<void> addExpense(ExpenseEntity expense) {
    return remote.insertExpense(expense);
  }
}
