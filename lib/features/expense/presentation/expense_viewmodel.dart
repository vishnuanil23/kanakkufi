import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_client_provider.dart';
import '../domain/currency_service.dart';
import '../data/expense_remote_datasource.dart';
import '../data/expense_repository_impl.dart';
import '../domain/expense_entity.dart';
import '../domain/expense_repository.dart';

import '../domain/usecases/add_expense_usecase.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return ExpenseRepositoryImpl(ExpenseRemoteDataSource(client));
});

final addExpenseUseCaseProvider = Provider<AddExpenseUseCase>((ref) {
  return AddExpenseUseCase(ref.read(expenseRepositoryProvider));
});

final addExpenseProvider = ChangeNotifierProvider<AddExpenseViewModel>(
  (ref) => AddExpenseViewModel(ref),
);

class AddExpenseViewModel extends ChangeNotifier {
  final Ref ref;

  AddExpenseViewModel(this.ref);

  Timer? _debounce;
  double? convertedAmount;
  bool isConverting = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> addExpense({
    required String category,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return;

    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final useCase = ref.read(addExpenseUseCaseProvider);
      final result = await useCase(
        AddExpenseParams(
          expense: ExpenseEntity(
            userId: userId,
            category: category,
            amount: amount,
            expenseDate: date,
            note: note,
          ),
        ),
      );

      result.fold(
        (failure) {
          errorMessage = failure.message;
          isSaving = false;
          notifyListeners();
        },
        (_) {
          isSaving = false;
          notifyListeners();
        },
      );
    } catch (e) {
      errorMessage = e.toString();
      isSaving = false;
      notifyListeners();
    }
  }

  void onAmountOrDateChanged({required double amount, required DateTime date}) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await _convert(amount, date);
    });
  }

  Future<void> _convert(double amount, DateTime date) async {
    if (amount <= 0) return;

    try {
      isConverting = true;
      notifyListeners();

      final result = await CurrencyService.convertAedToInr(
        amount: amount,
        date: date,
      );

      convertedAmount = result;
    } catch (e) {
      convertedAmount = null;
    } finally {
      isConverting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
