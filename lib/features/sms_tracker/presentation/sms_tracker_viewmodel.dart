import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final String activeFilter; // 'all', 'debits', 'credits', 'upi', 'bank'

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

  List<ParsedTransaction> get pendingTransactions => allTransactions
      .where((t) => !confirmedIds.contains(t.id) && !dismissedIds.contains(t.id))
      .toList();

  List<ParsedTransaction> get filteredTransactions {
    final pending = pendingTransactions;
    switch (activeFilter) {
      case 'debits':
        return pending.where((t) => t.isDebit).toList();
      case 'credits':
        return pending.where((t) => t.isCredit).toList();
      case 'upi':
        return pending.where((t) => t.isUpi).toList();
      case 'bank':
        return pending
            .where((t) => t.source == TransactionSource.bankSms)
            .toList();
      default:
        return pending;
    }
  }

  double get totalDebits =>
      pendingTransactions.where((t) => t.isDebit).fold(0.0, (s, e) => s + e.amount);

  double get totalCredits =>
      pendingTransactions.where((t) => t.isCredit).fold(0.0, (s, e) => s + e.amount);

  double get totalLiquidBalance =>
      bankBalances.fold(0.0, (s, b) => s + b.balance);

  int get unreviewedCount => pendingTransactions.length;

  List<SpendingInsight> get insights => InsightsGenerator.generate(
        transactions: allTransactions,
        creditCards: creditCards,
        bankBalances: bankBalances,
      );
}

class SmsTrackerViewModel extends StateNotifier<SmsTrackerState> {
  final SmsRepository _repository;

  SmsTrackerViewModel(this._repository) : super(const SmsTrackerState()) {
    init();
  }

  Future<void> init() async {
    final hasPerm = await SmsService.hasPermission();
    state = state.copyWith(hasPermission: hasPerm);
    await syncSms();
  }

  Future<void> requestPermission() async {
    final granted = await SmsService.requestPermission();
    state = state.copyWith(hasPermission: granted);
    await syncSms();
  }

  Future<void> syncSms({bool forceMock = false}) async {
    state = state.copyWith(isLoading: true);
    await _repository.syncMessages(forceMock: forceMock);
    state = state.copyWith(
      isLoading: false,
      allTransactions: _repository.allTransactions,
      bankBalances: _repository.bankBalances,
      creditCards: _repository.creditCards,
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void dismissTransaction(String id) {
    _repository.dismissTransaction(id);
    final updated = Set<String>.from(state.dismissedIds)..add(id);
    state = state.copyWith(dismissedIds: updated);
  }

  Future<void> confirmTransaction({
    required ParsedTransaction transaction,
    String? category,
    String? title,
  }) async {
    await _repository.confirmTransaction(
      transaction: transaction,
      customCategory: category,
      customTitle: title,
    );
    final updated = Set<String>.from(state.confirmedIds)..add(transaction.id);
    state = state.copyWith(confirmedIds: updated);
  }
}

final smsRepositoryProvider = Provider<SmsRepository>((ref) => SmsRepository());

final smsTrackerProvider =
    StateNotifierProvider<SmsTrackerViewModel, SmsTrackerState>((ref) {
  final repo = ref.watch(smsRepositoryProvider);
  return SmsTrackerViewModel(repo);
});
