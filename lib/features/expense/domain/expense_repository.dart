import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import 'expense_entity.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, void>> addExpense(ExpenseEntity expense);
}
