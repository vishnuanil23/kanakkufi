import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../expense_entity.dart';
import '../expense_repository.dart';

class AddExpenseUseCase implements UseCase<void, AddExpenseParams> {
  final ExpenseRepository repository;

  AddExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddExpenseParams params) async {
    return await repository.addExpense(params.expense);
  }
}

class AddExpenseParams extends Equatable {
  final ExpenseEntity expense;

  const AddExpenseParams({required this.expense});

  @override
  List<Object?> get props => [expense];
}
