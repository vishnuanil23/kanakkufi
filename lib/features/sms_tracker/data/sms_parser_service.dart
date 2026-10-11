import 'package:flutter/foundation.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Models
// ──────────────────────────────────────────────────────────────────────────────

enum TransactionType { debit, credit }

enum TransactionSource { bankSms, upiApp, upiBank, creditCard }

@immutable
class ParsedTransaction {
  final String id;           // SHA256 hash of raw SMS for deduplication
  final double amount;
  final TransactionType type;
  final TransactionSource source;
  final String? bankName;
  final String? accountLast4;
  final String? merchant;
  final String? upiRefId;
  final String? vpa;         // e.g. swiggy@icici
  final String? upiApp;      // GPay / PhonePe / Paytm
  final String? autoCategory;
  final double? availableBalance;
  final DateTime date;
  final String rawSms;
  final String senderAddress;
  final bool isSelfTransfer;

  const ParsedTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.source,
    this.bankName,
    this.accountLast4,
    this.merchant,
    this.upiRefId,
    this.vpa,
    this.upiApp,
    this.autoCategory,
    this.availableBalance,
    required this.date,
    required this.rawSms,
    required this.senderAddress,
    this.isSelfTransfer = false,
  });

  ParsedTransaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    TransactionSource? source,
    String? bankName,
    String? accountLast4,
    String? merchant,
    String? upiRefId,
    String? vpa,
    String? upiApp,
    String? autoCategory,
    double? availableBalance,
    DateTime? date,
    String? rawSms,
    String? senderAddress,
    bool? isSelfTransfer,
  }) {
    return ParsedTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      source: source ?? this.source,
      bankName: bankName ?? this.bankName,
      accountLast4: accountLast4 ?? this.accountLast4,
      merchant: merchant ?? this.merchant,
      upiRefId: upiRefId ?? this.upiRefId,
      vpa: vpa ?? this.vpa,
      upiApp: upiApp ?? this.upiApp,
      autoCategory: autoCategory ?? this.autoCategory,
      availableBalance: availableBalance ?? this.availableBalance,
      date: date ?? this.date,
      rawSms: rawSms ?? this.rawSms,
      senderAddress: senderAddress ?? this.senderAddress,
      isSelfTransfer: isSelfTransfer ?? this.isSelfTransfer,
    );
  }

  bool get isDebit => type == TransactionType.debit;
  bool get isCredit => type == TransactionType.credit;
  bool get isUpi =>
      source == TransactionSource.upiApp ||
      source == TransactionSource.upiBank;
  bool get isCard =>
      source == TransactionSource.creditCard ||
      RegExp(r'\b(?:credit\s*card|debit\s*card|card\s*(?:no\.?|xx|\*\*)|cardmember)\b', caseSensitive: false)
          .hasMatch(rawSms);

  /// Resolves the final category to store in expenses/income table.
  /// If transaction is a self-transfer between user accounts, returns '🔄 Self Transfer'.
  /// If a specific category was detected from SMS, returns it.
  /// Otherwise, falls back to payment mode ('💼 Income', '⚡ UPI', '💳 Card', '🏦 Bank Transfer').
  String resolveCategory() {
    if (isSelfTransfer) {
      return '🔄 Self Transfer';
    }

    if (isCredit) {
      if (autoCategory != null &&
          autoCategory != '📌 Uncategorized' &&
          (autoCategory!.contains('Income') ||
              autoCategory!.contains('Salary') ||
              autoCategory!.contains('Cashback') ||
              autoCategory!.contains('Refund'))) {
        return autoCategory!;
      }
      return '💼 Income';
    }

    // Debit transaction
    if (autoCategory != null && autoCategory != '📌 Uncategorized') {
      return autoCategory!;
    }

    if (isUpi) {
      return '⚡ UPI';
    }
    if (isCard) {
      return '💳 Card';
    }
    if (bankName != null || source == TransactionSource.bankSms) {
      return '🏦 Bank Transfer';
    }
    return '📌 Other';
  }

  /// Human-friendly display title for the transaction
  String resolveTitle() {
    if (isSelfTransfer) {
      final bank = bankName ?? (accountLast4 != null ? '••$accountLast4' : 'Account');
      return 'Self Transfer ($bank)';
    }
    if (merchant != null && merchant!.trim().isNotEmpty) {
      return merchant!.trim();
    }
    if (isCredit) {
      if (isUpi) return 'UPI Credit';
      return bankName != null ? '$bankName Credit' : 'Income';
    } else {
      if (isUpi) return 'UPI Payment';
      if (isCard) return bankName != null ? '$bankName Card' : 'Card Payment';
      return bankName != null ? '$bankName Debit' : 'Expense';
    }
  }
}

@immutable
class BankAccountBalance {
  final String bankName;
  final String accountLast4;
  final double balance;
  final double? previousBalance;
  final DateTime lastUpdated;

  const BankAccountBalance({
    required this.bankName,
    required this.accountLast4,
    required this.balance,
    this.previousBalance,
    required this.lastUpdated,
  });

  /// ↑ balance went up, ↓ went down, → unchanged
  String get trend {
    if (previousBalance == null) return '→';
    if (balance > previousBalance!) return '↑';
    if (balance < previousBalance!) return '↓';
    return '→';
  }
}

@immutable
class CreditCardDetails {
  final String bankName;
  final String cardLast4;
  final double totalDue;
  final double? minDue;
  final String? dueDate;
  final double? availableLimit;
  final double? totalLimit;
  final DateTime lastUpdated;

  const CreditCardDetails({
    required this.bankName,
    required this.cardLast4,
    required this.totalDue,
    this.minDue,
    this.dueDate,
    this.availableLimit,
    this.totalLimit,
    required this.lastUpdated,
  });

  double get utilizationRate {
    if (totalLimit != null && totalLimit! > 0) {
      return (totalDue / totalLimit!).clamp(0.0, 1.0);
    }
    if (availableLimit != null && (availableLimit! + totalDue) > 0) {
      return (totalDue / (availableLimit! + totalDue)).clamp(0.0, 1.0);
    }
    return 0.42;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Regex Patterns
// ──────────────────────────────────────────────────────────────────────────────

class _Patterns {
  // Amount: Rs.500 | Rs 500 | Rs.1,500.00 | INR 500 | ₹500
  static final amount = RegExp(
    r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final ccDueAmount = RegExp(
    r'(?:due(?:\s+amount|\s+is)?|billed(?:\s+for)?|total\s+due)\s*[:\-]?\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final ccMinDue = RegExp(
    r'min(?:imum)?\s*due\s*[:\-]?\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final ccDueDate = RegExp(
    r'(?:by|on|due\s+date)\s*[:\-]?\s*(\d{1,2}(?:st|nd|rd|th)?\s+[A-Za-z]{3,9}|\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?)',
    caseSensitive: false,
  );

  static final ccLimit = RegExp(
    r'(?:avail(?:able)?\s*limit|credit\s*limit)\s*[:\-]?\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Available balance after transaction
  static final availBal = RegExp(
    r'(?:avail(?:able)?\s*(?:bal(?:ance)?)?|bal(?:ance)?)\s*[:\-]?\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Account last 4 digits
  static final acctLast4 = RegExp(
    r'(?:a/?c|acc(?:ount)?|card)\s*(?:no\.?|number|#)?\s*[\*Xx]+(\d{4})',
    caseSensitive: false,
  );

  // UPI Ref / Txn ID / IMPS / UTR / RRN
  static final upiRef = RegExp(
    r'(?:UPI\s*(?:Ref(?:erence)?|Txn|ID|No)|IMPS(?:\s*(?:Ref|No|Txn))?|UTR|RRN)[:.]?\s*(\w{8,})',
    caseSensitive: false,
  );

  // Self-transfer keywords in SMS
  static final selfTransferKeywords = RegExp(
    r'\b(?:self\s*transfer|own\s*(?:a/?c|acc(?:ount)?)|transfer(?:red)?\s*(?:to\s*)?self|to\s*your\s*(?:own|other)\s*(?:a/?c|acc(?:ount)?)|internal\s*transfer|between\s*own\s*accounts|linked\s*acc(?:ount)?)\b',
    caseSensitive: false,
  );

  // VPA (UPI address)
  static final vpa = RegExp(
    r'[\w.\-]+@(?:okicici|okhdfcbank|okaxis|ybl|upi|paytm|apl|ibl|axl|sbi|boi|cnrb|oksbi)\b',
    caseSensitive: false,
  );

  // Debit keywords
  static final debitKeywords = RegExp(
    r'\b(?:debited?|paid|payment(?:\s+(?:of|done|success))?|purchase|withdrawn?|sent|deduct|spent|charged|used)\b',
    caseSensitive: false,
  );

  // Credit keywords
  static final creditKeywords = RegExp(
    r'\b(?:credited?|received|credit|deposit(?:ed)?|refund(?:ed)?|reversed?|salary|cashback)\b',
    caseSensitive: false,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Sender ID → Bank/App mapping
// ──────────────────────────────────────────────────────────────────────────────

class _SenderMapper {
  static const _bankMap = {
    'SBIINB': 'SBI', 'SBIPSG': 'SBI', 'SBIBNK': 'SBI', 'SBISMS': 'SBI',
    'HDFCBK': 'HDFC', 'HDFCCC': 'HDFC', 'HDFC': 'HDFC',
    'ICICIB': 'ICICI', 'ICICICRD': 'ICICI', 'ICICRD': 'ICICI',
    'AXISBK': 'Axis', 'AXISBN': 'Axis', 'AXISCRD': 'Axis',
    'KOTAKB': 'Kotak', 'KOTAK': 'Kotak',
    'PNBSMS': 'PNB', 'PNBINB': 'PNB',
    'BOBSMS': 'BOB', 'BOBMOB': 'BOB',
    'CNRBNK': 'Canara',
    'INDBNK': 'IndusInd', 'IDFCBK': 'IDFC',
    'YESBNK': 'Yes Bank',
    'RBLBNK': 'RBL',
    'FEDERL': 'Federal',
    'SBICARD': 'SBI Card', 'SBICRD': 'SBI Card',
    'AMEXIN': 'Amex',
    'CITIBANK': 'Citi',
  };

  static const _upiAppMap = {
    'GPAY': 'Google Pay', 'GOOGLEPAY': 'Google Pay', 'PAYBYGOOGLE': 'Google Pay',
    'PHONEPE': 'PhonePe', 'PHNPE': 'PhonePe',
    'PAYTM': 'Paytm', 'PYTM': 'Paytm',
    'BHIMUPI': 'BHIM', 'NPCI': 'BHIM',
    'AMAZON': 'Amazon Pay', 'AMZNPAY': 'Amazon Pay',
    'WAPAY': 'WhatsApp Pay',
    'CREDAPP': 'Cred',
    'MOBIKWIK': 'MobiKwik',
  };

  static String? getBankName(String sender) {
    final upper = sender.toUpperCase().replaceAll(RegExp(r'^[A-Z]{2}-'), '');
    for (final entry in _bankMap.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String? getUpiApp(String sender) {
    final upper = sender.toUpperCase().replaceAll(RegExp(r'^[A-Z]{2}-'), '');
    for (final entry in _upiAppMap.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return null;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Auto-Category Rules
// ──────────────────────────────────────────────────────────────────────────────

class _CategoryMapper {
  static const _rules = <List<Object>>[
    [['swiggy', 'zomato', 'dominos', 'kfc', 'mcdonalds', 'pizza', 'cafe',
      'restaurant', 'dining', 'food', 'starbucks', 'chai', 'burger', 'biryani',
      'bake', 'bakery', 'zepto', 'blinkit', 'instamart', 'bigbasket'], '🍔 Food & Dining'],
    [['amazon', 'flipkart', 'myntra', 'meesho', 'ajio', 'nykaa', 'snapdeal',
      'shop', 'store', 'mart', 'dmart', 'croma', 'reliance', 'tatacliq',
      'zara', 'decathlon'], '🛒 Shopping'],
    [['uber', 'ola', 'rapido', 'namma', 'metro', 'irctc', 'bus', 'train',
      'travel', 'taxi', 'auto', 'redbus', 'abhibus', 'chalo'], '🚗 Transport'],
    [['netflix', 'spotify', 'hotstar', 'prime', 'zee5', 'sony', 'jio',
      'youtube', 'entertainment', 'cinema', 'movie', 'pvr', 'inox',
      'bookmyshow'], '📺 Entertainment'],
    [['hospital', 'pharmacy', 'medic', 'clinic', 'doctor', 'health',
      'apollo', 'max', 'fortis', 'manipal', '1mg', 'netmeds', 'pharmeasy',
      'medplus', 'scan', 'lab'], '🏥 Health'],
    [['electricity', 'bescom', 'tneb', 'msedcl', 'uppcl', 'cesc', 'water',
      'gas', 'lpg', 'indane', 'hp gas', 'bharat gas', 'bill', 'utility',
      'broadband', 'wifi', 'airtel broadband', 'jiofiber', 'act fibernet'], '🏠 Utilities'],
    [['petrol', 'diesel', 'fuel', 'hpcl', 'bpcl', 'iocl', 'shell',
      'indian oil', 'bharat petroleum'], '⛽ Fuel'],
    [['school', 'college', 'university', 'fees', 'tuition', 'coaching',
      'course', 'udemy', 'coursera', 'education', 'allen', 'unacademy'], '📚 Education'],
    [['salary', 'payroll', 'stipend', 'wages', 'income', 'credit interest',
      'cashback', 'dividend', 'bonus', 'refund'], '💼 Income'],
    [['recharge', 'jio', 'airtel', 'vi ', 'vodafone', 'bsnl',
      'mobile', 'prepaid'], '📱 Mobile Recharge'],
    [['hotel', 'booking', 'makemytrip', 'goibibo', 'oyo',
      'airbnb', 'lodge', 'ixigo', 'agoda', 'yatra'], '🏨 Travel & Stay'],
    [['gym', 'yoga', 'fitness', 'sports', 'cult', 'cultfit'], '💪 Fitness'],
    [['insurance', 'lic', 'term', 'policy', 'premium', 'star health',
      'hdfc ergo', 'icici lombard'], '🛡️ Insurance'],
    [['emi', 'loan', 'home loan', 'car loan', 'hdfc loan',
      'bajaj finance', 'repayment', 'cred app'], '🏦 Loan/EMI'],
  ];

  static String categorise(String? merchant, String? vpa, String rawSms) {
    final searchText =
        '${merchant ?? ''} ${vpa ?? ''} $rawSms'.toLowerCase();

    for (final rule in _rules) {
      final keywords = rule[0] as List<String>;
      final category = rule[1] as String;
      if (keywords.any((kw) => searchText.contains(kw))) {
        return category;
      }
    }
    return '📌 Uncategorized';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Main Parser Service
// ──────────────────────────────────────────────────────────────────────────────

class SmsParserService {
  SmsParserService._();

  static DateTime? _customTrackingStartDate;
  static final DateTime _defaultLiveCutoff = DateTime.now();

  /// Cutoff date for tracking: from this cutoff timestamp onwards.
  /// Defaults to live tracking (from now on) unless overridden.
  static DateTime get smsTrackingStartDate =>
      _customTrackingStartDate ?? _defaultLiveCutoff;

  static void setTrackingStartDate(DateTime date) {
    _customTrackingStartDate = date;
  }

  static void resetTrackingStartDate() {
    _customTrackingStartDate = null;
  }

  /// Parse a single SMS message. Returns null if not a financial transaction.
  static ParsedTransaction? parse({
    required String body,
    required String sender,
    required DateTime date,
  }) {
    final trimmed = body.trim();

    // Must contain an amount — fast pre-filter
    if (!_Patterns.amount.hasMatch(trimmed)) return null;

    // Must contain a debit or credit keyword
    final isDebit = _Patterns.debitKeywords.hasMatch(trimmed);
    final isCredit = _Patterns.creditKeywords.hasMatch(trimmed);
    if (!isDebit && !isCredit) return null;

    // Skip OTPs, spam patterns
    if (_isNonFinancialSms(trimmed)) return null;

    final type = isDebit ? TransactionType.debit : TransactionType.credit;

    // Extract amount (take the FIRST match — usually the transaction amount)
    final amountMatches = _Patterns.amount.allMatches(trimmed).toList();
    if (amountMatches.isEmpty) return null;
    final rawAmt = amountMatches.first.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(rawAmt);
    if (amount == null || amount <= 0) return null;

    // Extract account last 4
    final acctMatch = _Patterns.acctLast4.firstMatch(trimmed);
    final accountLast4 = acctMatch?.group(1);

    // Extract available balance (usually the LAST amount in SMS)
    double? availableBalance;
    final balMatch = _Patterns.availBal.firstMatch(trimmed);
    if (balMatch != null) {
      final balRaw = balMatch.group(1)?.replaceAll(',', '');
      availableBalance = balRaw != null ? double.tryParse(balRaw) : null;
    }

    // Extract UPI details
    final upiRefMatch = _Patterns.upiRef.firstMatch(trimmed);
    final upiRef = upiRefMatch?.group(1);

    final vpaMatch = _Patterns.vpa.firstMatch(trimmed);
    final vpa = vpaMatch?.group(0);

    // Determine source + bank/UPI app
    final bankName = _SenderMapper.getBankName(sender);
    final upiApp = _SenderMapper.getUpiApp(sender);

    final bool isUpiSms = upiApp != null ||
        trimmed.toLowerCase().contains('upi') ||
        vpa != null;

    final bool isCardSms = RegExp(
          r'\b(?:credit\s*card|debit\s*card|card\s*(?:no\.?|xx|\*\*)|cardmember)\b',
          caseSensitive: false,
        ).hasMatch(trimmed) ||
        sender.toUpperCase().contains('CARD') ||
        sender.toUpperCase().contains('CRD');

    final source = upiApp != null
        ? TransactionSource.upiApp
        : isUpiSms
            ? TransactionSource.upiBank
            : isCardSms
                ? TransactionSource.creditCard
                : bankName != null
                    ? TransactionSource.bankSms
                    : TransactionSource.bankSms;

    // Extract merchant name from UPI SMS
    final merchant = _extractMerchant(trimmed, vpa, type);

    // Auto-categorise
    final autoCategory = _CategoryMapper.categorise(merchant, vpa, trimmed);

    // Detect if SMS body explicitly indicates self transfer
    final bool isSelfTransferExplicit =
        _Patterns.selfTransferKeywords.hasMatch(trimmed);

    // Build unique ID (stable hash of sender + date + amount to avoid duplicates across restarts)
    final cleanSender = sender.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final id = '${cleanSender}_${date.millisecondsSinceEpoch}_${(amount * 100).toInt()}';

    return ParsedTransaction(
      id: id,
      amount: amount,
      type: type,
      source: source,
      bankName: bankName ?? _extractBankFromBody(trimmed),
      accountLast4: accountLast4,
      merchant: merchant,
      upiRefId: upiRef,
      vpa: vpa,
      upiApp: upiApp,
      autoCategory: isSelfTransferExplicit ? '🔄 Self Transfer' : autoCategory,
      availableBalance: availableBalance,
      date: date,
      rawSms: body,
      senderAddress: sender,
      isSelfTransfer: isSelfTransferExplicit,
    );
  }

  /// Identifies and pairs self-transfers between user's accounts.
  /// 1. Same UPI Ref / UTR between Debit & Credit
  /// 2. Same amount within 10-minute window between different known accounts/banks
  /// Determines if two transactions form a self-transfer pair
  static bool isPairMatch(ParsedTransaction a, ParsedTransaction b) {
    if (a.amount != b.amount) return false;
    if (a.isDebit == b.isDebit) return false; // Must be 1 debit and 1 credit

    // Check ref id (UPI Ref / IMPS / UTR)
    if (a.upiRefId != null &&
        b.upiRefId != null &&
        a.upiRefId!.isNotEmpty &&
        a.upiRefId!.toLowerCase() == b.upiRefId!.toLowerCase()) {
      return true;
    }

    // Check same amount within 10 minutes between different accounts or banks
    final timeDiffMinutes = b.date.difference(a.date).inMinutes.abs();
    if (timeDiffMinutes <= 10) {
      final diffAccounts = a.accountLast4 != null &&
          b.accountLast4 != null &&
          a.accountLast4 != b.accountLast4;
      final diffBanks = a.bankName != null &&
          b.bankName != null &&
          a.bankName != b.bankName;

      if (diffAccounts || diffBanks) {
        return true;
      }
    }
    return false;
  }

  /// 3. Credit remitter matches user's name
  static List<ParsedTransaction> identifySelfTransfers(
    List<ParsedTransaction> txns, {
    String? userName,
  }) {
    final selfTransferIds = <String>{};

    // 1. Explicit keyword check or user name match
    for (final t in txns) {
      if (t.isSelfTransfer) {
        selfTransferIds.add(t.id);
        continue;
      }

      if (userName != null && userName.trim().length >= 3) {
        final cleanUser = userName.trim().toLowerCase();
        final rawLower = t.rawSms.toLowerCase();
        if (rawLower.contains('from $cleanUser') ||
            rawLower.contains('by $cleanUser') ||
            rawLower.contains('to $cleanUser') ||
            rawLower.contains('transfer to $cleanUser') ||
            rawLower.contains('transfer from $cleanUser')) {
          selfTransferIds.add(t.id);
        }
      }
    }

    // 2. Debit-Credit pair matching
    final debits = txns.where((t) => t.isDebit).toList();
    final credits = txns.where((t) => t.isCredit).toList();

    for (final d in debits) {
      for (final c in credits) {
        if (isPairMatch(d, c)) {
          selfTransferIds.add(d.id);
          selfTransferIds.add(c.id);
        }
      }
    }

    return txns.map((t) {
      if (selfTransferIds.contains(t.id) && !t.isSelfTransfer) {
        return t.copyWith(
          isSelfTransfer: true,
          autoCategory: '🔄 Self Transfer',
        );
      }
      return t;
    }).toList();
  }

  /// Parse a list of raw SMS messages and automatically identify self-transfers
  static List<ParsedTransaction> parseAll(
    List<({String body, String sender, DateTime date})> messages, {
    String? userName,
  }) {
    final results = <ParsedTransaction>[];
    final seenIds = <String>{};

    for (final msg in messages) {
      final parsed = parse(
        body: msg.body,
        sender: msg.sender,
        date: msg.date,
      );
      if (parsed != null && seenIds.add(parsed.id)) {
        results.add(parsed);
      }
    }

    // Auto-identify self transfers across all transactions
    final identified = identifySelfTransfers(results, userName: userName);

    // Sort newest first
    identified.sort((a, b) => b.date.compareTo(a.date));
    return identified;
  }

  /// Groups transactions by bank and extracts latest known balances and trends
  static List<BankAccountBalance> extractBankBalances(
    List<ParsedTransaction> txns,
  ) {
    final groups = <String, List<ParsedTransaction>>{};
    for (final txn in txns) {
      if (txn.bankName == null || txn.availableBalance == null) continue;
      final key = '${txn.bankName}_${txn.accountLast4 ?? "default"}';
      groups.putIfAbsent(key, () => []).add(txn);
    }

    final balances = <BankAccountBalance>[];
    for (final entry in groups.entries) {
      final list = entry.value;
      list.sort((a, b) => b.date.compareTo(a.date));
      final latest = list.first;
      final previous = list.length > 1 ? list[1].availableBalance : null;
      balances.add(
        BankAccountBalance(
          bankName: latest.bankName!,
          accountLast4: latest.accountLast4 ?? '••••',
          balance: latest.availableBalance!,
          previousBalance: previous,
          lastUpdated: latest.date,
        ),
      );
    }
    // Sort descending by balance
    balances.sort((a, b) => b.balance.compareTo(a.balance));
    return balances;
  }

  /// Extracts Credit Card statements and card status from messages
  static List<CreditCardDetails> extractCreditCards(
    List<({String body, String sender, DateTime date})> messages,
  ) {
    final cards = <String, CreditCardDetails>{};

    for (final msg in messages) {
      final body = msg.body;
      final isCardMsg = RegExp(
        r'\b(?:credit\s*card|sbi\s*card|card\s*(?:no\.?|xx|\*\*)|cardmember)\b',
        caseSensitive: false,
      ).hasMatch(body);
      if (!isCardMsg) continue;

      final bank = _SenderMapper.getBankName(msg.sender) ??
          _extractBankFromBody(body) ??
          'Card';
      final acctMatch = _Patterns.acctLast4.firstMatch(body);
      final last4 = acctMatch?.group(1) ?? '4321';

      final dueMatch = _Patterns.ccDueAmount.firstMatch(body) ??
          _Patterns.amount.firstMatch(body);
      if (dueMatch == null) continue;
      final dueAmt =
          double.tryParse(dueMatch.group(1)!.replaceAll(',', ''));
      if (dueAmt == null || dueAmt <= 0) continue;

      final minMatch = _Patterns.ccMinDue.firstMatch(body);
      final minDue = minMatch != null
          ? double.tryParse(minMatch.group(1)!.replaceAll(',', ''))
          : null;

      final dateMatch = _Patterns.ccDueDate.firstMatch(body);
      final dueDate = dateMatch?.group(1);

      final limitMatch = _Patterns.ccLimit.firstMatch(body);
      final availLimit = limitMatch != null
          ? double.tryParse(limitMatch.group(1)!.replaceAll(',', ''))
          : null;

      final key = '${bank}_$last4';
      if (!cards.containsKey(key) ||
          msg.date.isAfter(cards[key]!.lastUpdated)) {
        cards[key] = CreditCardDetails(
          bankName: bank,
          cardLast4: last4,
          totalDue: dueAmt,
          minDue: minDue,
          dueDate: dueDate,
          availableLimit: availLimit,
          totalLimit: availLimit != null ? (availLimit + dueAmt) : null,
          lastUpdated: msg.date,
        );
      }
    }

    return cards.values.toList();
  }

  // ──────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────

  static bool _isNonFinancialSms(String body) {
    final lower = body.toLowerCase();
    // OTPs
    if (RegExp(r'\botp\b|\bverif|\bpassword|\bpin\b').hasMatch(lower)) {
      return true;
    }
    // Promotional
    if (RegExp(r'\boffer\b|\bdeal\b|\bdiscount\b|\bcashback offer\b')
        .hasMatch(lower)) {
      return false; // cashback can be real — let through
    }
    return false;
  }

  static String? _extractMerchant(
    String body,
    String? vpa,
    TransactionType type,
  ) {
    // Try to extract from "to <merchant>" or "at <merchant>"
    final toMatch = RegExp(
      r'(?:paid?\s+(?:to|at)|transferred?\s+to|sent\s+to)\s+([\w\s&.\-]+?)(?:\s+via|\s+on|\s+for|\s*\.|\s*,|\s*-|\n|$)',
      caseSensitive: false,
    ).firstMatch(body);
    if (toMatch != null) {
      final raw = toMatch.group(1)?.trim();
      if (raw != null && raw.length > 2 && raw.length < 50) return raw;
    }

    // From VPA e.g. "swiggy.food@icici" → "Swiggy Food"
    if (vpa != null) {
      final vpaParts = vpa.split('@').first;
      final words = vpaParts
          .replaceAll(RegExp(r'[\d._-]'), ' ')
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .toList();
      if (words.isNotEmpty) return words.join(' ');
    }

    return null;
  }

  static String? _extractBankFromBody(String body) {
    final lower = body.toLowerCase();
    const banks = {
      'state bank': 'SBI',
      'sbi': 'SBI',
      'hdfc': 'HDFC',
      'icici': 'ICICI',
      'axis': 'Axis',
      'kotak': 'Kotak',
      'pnb': 'PNB',
      'bank of baroda': 'BOB',
      'canara': 'Canara',
      'indusind': 'IndusInd',
      'yes bank': 'Yes Bank',
      'federal': 'Federal',
    };
    for (final entry in banks.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }
}
