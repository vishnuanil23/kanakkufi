import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/presentation/dashboard_viewmodel.dart';
import '../data/sms_parser_service.dart';
import '../data/sms_repository.dart';
import '../data/sms_service.dart';
import 'widgets/insights_generator.dart';

class SmsTrackerState {
  final bool isLoading;
  final bool hasPermission;
  final List<ParsedTransaction> allTransactions;
  final List<BankAccountBalance> bankBalances;
  final List<CreditCardDetails> creditCards;
  final Set<String> confirmedIds;
  final Set<String> dismissedIds;
  final String activeFilter; // 'all', 'debits', 'credits', 'upi', 'card', 'bank'

  const SmsTrackerState({
    this.isLoading = false,
    this.hasPermission = false,
    this.allTransactions = const [],
    this.bankBalances = const [],
    this.creditCards = const [],
    this.confirmedIds = const {},
    this.dismissedIds = const {},
    this.activeFilter = 'all',
  });

  SmsTrackerState copyWith({
    bool? isLoading,
    bool? hasPermission,
    List<ParsedTransaction>? allTransactions,
    List<BankAccountBalance>? bankBalances,
    List<CreditCardDetails>? creditCards,
    Set<String>? confirmedIds,
    Set<String>? dismissedIds,
    String? activeFilter,
  }) {
    return SmsTrackerState(
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      allTransactions: allTransactions ?? this.allTransactions,
      bankBalances: bankBalances ?? this.bankBalances,
      creditCards: creditCards ?? this.creditCards,
      confirmedIds: confirmedIds ?? this.confirmedIds,
      dismissedIds: dismissedIds ?? this.dismissedIds,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  // All transactions are automatically tracked without manual review
  List<ParsedTransaction> get autoAddedTransactions => allTransactions;
  List<ParsedTransaction> get pendingTransactions => allTransactions;

  List<ParsedTransaction> get filteredTransactions {
    switch (activeFilter) {
      case 'debits':
        return allTransactions
            .where((t) => t.isDebit && !t.isSelfTransfer)
            .toList();
      case 'credits':
        return allTransactions
            .where((t) => t.isCredit && !t.isSelfTransfer)
            .toList();
      case 'transfers':
        return allTransactions.where((t) => t.isSelfTransfer).toList();
      case 'upi':
        return allTransactions.where((t) => t.isUpi).toList();
      case 'card':
        return allTransactions.where((t) => t.isCard).toList();
      case 'bank':
        return allTransactions
            .where((t) => t.source == TransactionSource.bankSms)
            .toList();
      default:
        return allTransactions;
    }
  }

  double get totalDebits => allTransactions
      .where((t) => t.isDebit && !t.isSelfTransfer)
      .fold(0.0, (s, e) => s + e.amount);

  double get totalCredits => allTransactions
      .where((t) => t.isCredit && !t.isSelfTransfer)
      .fold(0.0, (s, e) => s + e.amount);

  double get totalSelfTransfers => allTransactions
      .where((t) => t.isSelfTransfer)
      .fold(0.0, (s, e) => s + e.amount);

  int get selfTransfersCount =>
      allTransactions.where((t) => t.isSelfTransfer).length;

  double get totalLiquidBalance =>
      bankBalances.fold(0.0, (s, b) => s + b.balance);

  int get syncedCount => allTransactions.length;
  int get unreviewedCount => allTransactions.length;

  List<SpendingInsight> get insights => InsightsGenerator.generate(
        transactions: allTransactions,
        creditCards: creditCards,
        bankBalances: bankBalances,
      );
}

class SmsTrackerViewModel extends StateNotifier<SmsTrackerState> {
  final SmsRepository _repository;
  final Ref? _ref;

  SmsTrackerViewModel(this._repository, [this._ref]) : super(const SmsTrackerState()) {
    init();
  }

  Future<void> init() async {
    final hasPerm = await SmsService.hasPermission();
    state = state.copyWith(hasPermission: hasPerm);

    if (hasPerm) {
      await SmsService.startListening();
    }

    // Listen to real-time incoming SMS
    SmsService.addListener(_onIncomingTransaction);

    await syncSms();
  }

  @override
  void dispose() {
    SmsService.removeListener(_onIncomingTransaction);
    super.dispose();
  }

  void _onIncomingTransaction(ParsedTransaction txn) {
    final updatedList = [txn, ...state.allTransactions.where((t) => t.id != txn.id)];
    state = state.copyWith(
      allTransactions: updatedList,
      confirmedIds: Set<String>.from(state.confirmedIds)..add(txn.id),
      bankBalances: _repository.bankBalances,
      creditCards: _repository.creditCards,
    );
  }

  Future<void> requestPermission() async {
    final granted = await SmsService.requestPermission();
    state = state.copyWith(hasPermission: granted);
    if (granted) {
      await SmsService.startListening();
      await syncSms();
    }
  }

  Future<void> syncSms() async {
    state = state.copyWith(isLoading: true);
    await _repository.syncMessages();
    state = state.copyWith(
      isLoading: false,
      allTransactions: _repository.allTransactions,
      bankBalances: _repository.bankBalances,
      creditCards: _repository.creditCards,
      confirmedIds: _repository.processedIds,
    );
    _ref?.read(dashboardProvider.notifier).fetchExpenses();
  }

  /// Completely removes all previously added SMS data from database and resets to live tracking from now
  Future<int> purgePreviousSmsData() async {
    state = state.copyWith(isLoading: true);
    final count = await _repository.purgeAllPreviousSmsExpenses();
    await syncSms();
    return count;
  }

  /// Removes all previously added self-transfer transactions from the database
  Future<int> removeSelfTransfersFromExpenses() async {
    state = state.copyWith(isLoading: true);
    final count = await _repository.deleteSelfTransfersFromDatabase();
    await syncSms();
    return count;
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void dismissTransaction(String id) {
    _repository.dismissTransaction(id);
    final updated = Set<String>.from(state.dismissedIds)..add(id);
    state = state.copyWith(dismissedIds: updated);
  }

  Future<void> updateCategory(String id, String newCategory) async {
    await _repository.updateTransactionCategory(id, newCategory);
    await syncSms();
  }

  Future<void> toggleSelfTransfer(String id, bool isSelf) async {
    await _repository.toggleSelfTransfer(id, isSelf);
    await syncSms();
  }

  // Deprecated manual confirmation retained for backward compatibility
  Future<void> confirmTransaction({
    required ParsedTransaction transaction,
    String? category,
    String? title,
  }) async {
    await _repository.autoAddTransaction(transaction);
    final updated = Set<String>.from(state.confirmedIds)..add(transaction.id);
    state = state.copyWith(confirmedIds: updated);
  }
}

final smsRepositoryProvider =
    Provider<SmsRepository>((ref) => SmsRepository.instance);

final smsTrackerProvider =
    StateNotifierProvider<SmsTrackerViewModel, SmsTrackerState>((ref) {
  final repo = ref.watch(smsRepositoryProvider);
  return SmsTrackerViewModel(repo, ref);
});
