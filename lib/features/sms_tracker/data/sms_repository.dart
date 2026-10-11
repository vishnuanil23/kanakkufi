import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/notification_service.dart';
import 'sms_parser_service.dart';
import 'sms_service.dart';

class SmsRepository {
  static final SmsRepository instance = SmsRepository._internal();
  factory SmsRepository() => instance;
  SmsRepository._internal();

  final SupabaseClient _client = Supabase.instance.client;
  static const String _prefsKeyProcessedIds = 'kanakkufi_sms_auto_added_ids';
  static const String _prefsKeyLiveTrackingCutoff = 'kanakkufi_sms_live_cutoff_ms';
  static const String _prefsKeyPreviousSmsPurged = 'kanakkufi_sms_previous_purged_v1';

  // Persistent tracked transaction IDs
  final Set<String> _processedIds = <String>{};
  bool _initialized = false;

  List<ParsedTransaction> _allTransactions = [];
  List<BankAccountBalance> _bankBalances = [];
  List<CreditCardDetails> _creditCards = [];

  List<ParsedTransaction> get allTransactions => _allTransactions;
  List<BankAccountBalance> get bankBalances => _bankBalances;
  List<CreditCardDetails> get creditCards => _creditCards;
  Set<String> get processedIds => _processedIds;

  // Backward-compatibility getters
  Set<String> get confirmedIds => _processedIds;
  List<ParsedTransaction> get pendingTransactions => _allTransactions;

  Future<void> _initProcessedIds() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ensure previous SMS data has been purged and live tracking is active
      final purged = prefs.getBool(_prefsKeyPreviousSmsPurged) ?? false;
      if (!purged) {
        await purgeAllPreviousSmsExpenses();
        _initialized = true;
        return;
      }

      // Restore saved live cutoff timestamp
      final savedCutoffMs = prefs.getInt(_prefsKeyLiveTrackingCutoff);
      if (savedCutoffMs != null) {
        SmsParserService.setTrackingStartDate(
          DateTime.fromMillisecondsSinceEpoch(savedCutoffMs),
        );
      }

      final saved = prefs.getStringList(_prefsKeyProcessedIds);
      if (saved != null) {
        _processedIds.addAll(saved);
      }

      // Also check Supabase for existing [sms:...] notes for logged-in user
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final existing = await _client
            .from(AppStrings.tableExpenses)
            .select(AppStrings.colNote)
            .eq(AppStrings.colUserId, userId);
        for (final row in existing) {
          final note = row[AppStrings.colNote]?.toString() ?? '';
          final match = RegExp(r'\[sms:([^\]]+)\]').firstMatch(note);
          if (match != null) {
            _processedIds.add(match.group(1)!);
          }
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Error loading processed SMS IDs: $e');
    }
  }

  Future<void> _persistProcessedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKeyProcessedIds, _processedIds.toList());
    } catch (e) {
      debugPrint('Error persisting processed SMS IDs: $e');
    }
  }

  /// Completely removes all previously added SMS expenses & income from the database,
  /// resets tracking state, and starts live tracking only from now onwards.
  Future<int> purgeAllPreviousSmsExpenses() async {
    int deletedCount = 0;
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final existingRows = await _client
            .from(AppStrings.tableExpenses)
            .select(
              '${AppStrings.colId}, ${AppStrings.colNote}, ${AppStrings.colCategory}',
            )
            .eq(AppStrings.colUserId, userId);

        final idsToDelete = <dynamic>{};

        for (final row in existingRows) {
          final id = row[AppStrings.colId];
          final note =
              (row[AppStrings.colNote]?.toString() ?? '').toLowerCase();
          final category =
              (row[AppStrings.colCategory]?.toString() ?? '').toLowerCase();

          // Condition 1: Note contains [sms:
          if (note.contains('[sms:')) {
            idsToDelete.add(id);
            continue;
          }

          // Condition 2: Note contains 'auto-tracked via'
          if (note.contains('auto-tracked via')) {
            idsToDelete.add(id);
            continue;
          }

          // Condition 3: Category is Self Transfer
          if (category.contains('self transfer')) {
            idsToDelete.add(id);
            continue;
          }
        }

        for (final id in idsToDelete) {
          await _client
              .from(AppStrings.tableExpenses)
              .delete()
              .eq(AppStrings.colId, id);
          deletedCount++;
        }
      }

      // Clear local memory
      _processedIds.clear();
      _allTransactions.clear();
      _bankBalances.clear();
      _creditCards.clear();

      // Reset SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyProcessedIds);

      // Set live tracking cutoff to NOW
      final now = DateTime.now();
      await prefs.setInt(
        _prefsKeyLiveTrackingCutoff,
        now.millisecondsSinceEpoch,
      );
      await prefs.setBool(_prefsKeyPreviousSmsPurged, true);

      SmsParserService.setTrackingStartDate(now);

      debugPrint(
        'Purged $deletedCount previous SMS records from database. Live tracking cutoff set to $now.',
      );
    } catch (e) {
      debugPrint('Error purging previous SMS data: $e');
    }

    return deletedCount;
  }

  /// Automatically syncs new SMS messages from the live cutoff date onwards.
  /// Deduplicates against previously inserted transactions and saves new ones to Supabase.
  Future<int> syncMessages() async {
    await _initProcessedIds();

    final user = _client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String?;

    final startDate = SmsParserService.smsTrackingStartDate;
    final rawMessages = await SmsService.readMessages(sinceDate: startDate);
    _allTransactions = SmsParserService.parseAll(rawMessages, userName: userName);
    _bankBalances = SmsParserService.extractBankBalances(_allTransactions);
    _creditCards = SmsParserService.extractCreditCards(rawMessages);

    // Clean up and delete any previously added self-transfer transactions from Supabase
    await deleteSelfTransfersFromDatabase();

    int newAddedCount = 0;
    final userId = user?.id;

    for (final txn in _allTransactions) {
      if (_processedIds.contains(txn.id)) continue;

      // Automatically add this transaction without review (skips self-transfers from DB)
      final success = await _insertTransactionToDatabase(txn, userId);
      if (success) {
        _processedIds.add(txn.id);
        if (!txn.isSelfTransfer) {
          newAddedCount++;
        }
      }
    }

    if (newAddedCount > 0) {
      await _persistProcessedIds();
    }

    return newAddedCount;
  }

  /// Deletes all previously added self-transfer transactions from the Supabase expenses table.
  Future<int> deleteSelfTransfersFromDatabase() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    int deletedCount = 0;
    try {
      final existingRows = await _client
          .from(AppStrings.tableExpenses)
          .select('${AppStrings.colId}, ${AppStrings.colCategory}, ${AppStrings.colNote}')
          .eq(AppStrings.colUserId, userId);

      final selfTransferSmsIds = _allTransactions
          .where((t) => t.isSelfTransfer)
          .map((t) => t.id)
          .toSet();

      final idsToDelete = <dynamic>{};

      for (final row in existingRows) {
        final id = row[AppStrings.colId];
        final category =
            (row[AppStrings.colCategory]?.toString() ?? '').toLowerCase();
        final note =
            (row[AppStrings.colNote]?.toString() ?? '').toLowerCase();

        // 1. Tagged as Self Transfer
        if (category.contains('self transfer')) {
          idsToDelete.add(id);
          continue;
        }

        // 2. Note has [sms:<id>] where <id> belongs to a self-transfer transaction
        final match = RegExp(
          r'\[sms:([^\]]+)\]',
          caseSensitive: false,
        ).firstMatch(note);
        if (match != null) {
          final smsId = match.group(1)!;
          if (selfTransferSmsIds.contains(smsId)) {
            idsToDelete.add(id);
            continue;
          }
        }

        // 3. Note title mentions Self Transfer
        if (note.contains('self transfer')) {
          idsToDelete.add(id);
          continue;
        }
      }

      for (final id in idsToDelete) {
        await _client
            .from(AppStrings.tableExpenses)
            .delete()
            .eq(AppStrings.colId, id);
        deletedCount++;
      }

      if (deletedCount > 0) {
        debugPrint(
          'Deleted $deletedCount previously added self-transfer entries from Supabase',
        );
      }
    } catch (e) {
      debugPrint('Error deleting self-transfers from Supabase: $e');
    }

    return deletedCount;
  }

  /// Auto-adds a single incoming real-time SMS transaction.
  Future<bool> autoAddTransaction(ParsedTransaction txn) async {
    await _initProcessedIds();
    if (_processedIds.contains(txn.id)) return false;
    if (txn.date.isBefore(SmsParserService.smsTrackingStartDate)) return false;

    final user = _client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String?;

    ParsedTransaction effectiveTxn = txn;

    // Check single txn for self-transfer keywords or user name match
    if (!effectiveTxn.isSelfTransfer) {
      final identified = SmsParserService.identifySelfTransfers(
        [effectiveTxn],
        userName: userName,
      );
      if (identified.isNotEmpty && identified.first.isSelfTransfer) {
        effectiveTxn = identified.first;
      }
    }

    // Check if this new txn forms a pair with an existing transaction
    ParsedTransaction? matchedPair;
    for (int i = 0; i < _allTransactions.length; i++) {
      final existing = _allTransactions[i];
      if (SmsParserService.isPairMatch(effectiveTxn, existing)) {
        matchedPair = existing;
        _allTransactions[i] = existing.copyWith(
          isSelfTransfer: true,
          autoCategory: '🔄 Self Transfer',
        );
        // Completely remove the counterpart from Supabase expenses table!
        await _deleteTransactionFromDatabase(existing.id);
        break;
      }
    }

    if (matchedPair != null) {
      effectiveTxn = effectiveTxn.copyWith(
        isSelfTransfer: true,
        autoCategory: '🔄 Self Transfer',
      );
    }

    final userId = user?.id;
    final success = await _insertTransactionToDatabase(effectiveTxn, userId);
    if (success) {
      _processedIds.add(effectiveTxn.id);
      await _persistProcessedIds();

      if (!_allTransactions.any((t) => t.id == effectiveTxn.id)) {
        _allTransactions.insert(0, effectiveTxn);
      }

      // Show alert notification
      try {
        await NotificationService.init();
        await NotificationService.showTransactionAlert(
          amount: effectiveTxn.amount,
          isDebit: effectiveTxn.isDebit,
          source: effectiveTxn.bankName ?? (effectiveTxn.isUpi ? 'UPI' : 'Bank'),
          merchant: effectiveTxn.isSelfTransfer
              ? 'Self Transfer (Excluded)'
              : (effectiveTxn.merchant ?? effectiveTxn.resolveCategory()),
        );
      } catch (_) {}

      return true;
    }
    return false;
  }

  Future<bool> _insertTransactionToDatabase(
    ParsedTransaction txn,
    String? userId,
  ) async {
    // Self-transfers are completely excluded and not stored in the expenses table
    if (txn.isSelfTransfer) {
      return true;
    }

    final category = txn.resolveCategory();
    final title = txn.resolveTitle();

    if (userId != null) {
      try {
        await _client.from(AppStrings.tableExpenses).insert({
          AppStrings.colUserId: userId,
          AppStrings.colCategory: category,
          AppStrings.colAmount: txn.amount,
          AppStrings.colExpenseDate:
              DateFormat('yyyy-MM-dd').format(txn.date),
          AppStrings.colNote:
              '$title (Auto-tracked via ${txn.isUpi ? 'UPI' : (txn.bankName ?? 'Bank')} • ${txn.senderAddress} • [sms:${txn.id}])',
        });
        return true;
      } catch (e) {
        debugPrint('Failed to auto-save SMS transaction to Supabase: $e');
        return false;
      }
    } else {
      // When offline or unauthenticated, still record as processed locally
      return true;
    }
  }

  Future<bool> _deleteTransactionFromDatabase(String txnId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final existing = await _client
            .from(AppStrings.tableExpenses)
            .select(AppStrings.colId)
            .eq(AppStrings.colUserId, userId)
            .ilike(AppStrings.colNote, '%[sms:$txnId]%');
        for (final row in existing) {
          final id = row[AppStrings.colId];
          await _client
              .from(AppStrings.tableExpenses)
              .delete()
              .eq(AppStrings.colId, id);
        }
        return true;
      } catch (e) {
        debugPrint('Error deleting transaction from Supabase: $e');
        return false;
      }
    }
    return true;
  }

  /// Allow user to change an auto-added transaction category if desired
  Future<void> updateTransactionCategory(
    String txnId,
    String newCategory,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final existing = await _client
            .from(AppStrings.tableExpenses)
            .select()
            .eq(AppStrings.colUserId, userId)
            .ilike(AppStrings.colNote, '%[sms:$txnId]%');
        if (existing.isNotEmpty) {
          final id = existing.first[AppStrings.colId];
          await _client
              .from(AppStrings.tableExpenses)
              .update({AppStrings.colCategory: newCategory})
              .eq(AppStrings.colId, id);
        }
      } catch (e) {
        debugPrint('Error updating transaction category in Supabase: $e');
      }
    }
  }

  /// Allows user to toggle whether an auto-added transaction is a Self Transfer
  Future<void> toggleSelfTransfer(String txnId, bool isSelf) async {
    final idx = _allTransactions.indexWhere((t) => t.id == txnId);
    if (idx != -1) {
      final t = _allTransactions[idx];
      final newCategory = isSelf
          ? '🔄 Self Transfer'
          : (t.isCredit ? '💼 Income' : (t.isUpi ? '⚡ UPI' : (t.isCard ? '💳 Card' : '🏦 Bank Transfer')));
      _allTransactions[idx] = t.copyWith(
        isSelfTransfer: isSelf,
        autoCategory: newCategory,
      );

      final userId = _client.auth.currentUser?.id;
      if (isSelf) {
        // Delete from Supabase expenses table
        await _deleteTransactionFromDatabase(txnId);
      } else {
        // Re-insert into Supabase expenses table
        await _insertTransactionToDatabase(_allTransactions[idx], userId);
      }
    }
  }

  // Deprecated manual confirmation helper retained for backward compatibility
  Future<bool> confirmTransaction({
    required ParsedTransaction transaction,
    String? customCategory,
    String? customTitle,
  }) async {
    return autoAddTransaction(transaction);
  }

  void dismissTransaction(String id) {
    _processedIds.add(id);
    _persistProcessedIds();
  }
}
