import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../domain/expense_entity.dart';
import '../domain/expense_repository.dart';
import 'expense_remote_datasource.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remote;

  ExpenseRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, void>> addExpense(ExpenseEntity expense) async {
    try {
      await remote.insertExpense(expense);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
