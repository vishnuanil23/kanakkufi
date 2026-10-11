import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import 'sms_parser_service.dart';
import 'sms_service.dart';

class SmsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // In-memory dismissed and confirmed transaction IDs
  final Set<String> _dismissedIds = <String>{};
  final Set<String> _confirmedIds = <String>{};

  List<ParsedTransaction> _allTransactions = [];
  List<BankAccountBalance> _bankBalances = [];
  List<CreditCardDetails> _creditCards = [];

  List<ParsedTransaction> get pendingTransactions => _allTransactions
      .where((t) => !_dismissedIds.contains(t.id) && !_confirmedIds.contains(t.id))
      .toList();

  List<ParsedTransaction> get allTransactions => _allTransactions;
  List<BankAccountBalance> get bankBalances => _bankBalances;
  List<CreditCardDetails> get creditCards => _creditCards;
  Set<String> get confirmedIds => _confirmedIds;

  Future<void> syncMessages({bool forceMock = false}) async {
    final rawMessages = await SmsService.readMessages(forceMock: forceMock);
    _allTransactions = SmsParserService.parseAll(rawMessages);
    _bankBalances = SmsParserService.extractBankBalances(_allTransactions);
    _creditCards = SmsParserService.extractCreditCards(rawMessages);
  }

  void dismissTransaction(String id) {
    _dismissedIds.add(id);
  }

  Future<bool> confirmTransaction({
    required ParsedTransaction transaction,
    String? customCategory,
    String? customTitle,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final category = customCategory ?? transaction.autoCategory ?? 'Other';
    final title = customTitle ?? transaction.merchant ?? transaction.bankName ?? 'Expense';

    // If logged in, persist to Supabase
    if (userId != null) {
      try {
        await _client.from(AppStrings.tableExpenses).insert({
          AppStrings.colUserId: userId,
          AppStrings.colCategory: category,
          AppStrings.colAmount: transaction.amount,
          AppStrings.colExpenseDate: DateFormat('yyyy-MM-dd').format(transaction.date),
          AppStrings.colNote:
              '$title (Auto-tracked from ${transaction.source.name} • ${transaction.senderAddress})',
        });
      } catch (e) {
        debugPrint('Failed to save SMS expense to Supabase: $e');
      }
    }

    _confirmedIds.add(transaction.id);
    return true;
  }
}
