import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/expense_entity.dart';
import 'expense_model.dart';

class ExpenseRemoteDataSource {
  final SupabaseClient client;

  ExpenseRemoteDataSource(this.client);

  Future<void> insertExpense(ExpenseEntity expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await client.from('expenses').insert(model.toJson());
  }
}
