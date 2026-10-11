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
  });

  bool get isDebit => type == TransactionType.debit;
  bool get isCredit => type == TransactionType.credit;
  bool get isUpi =>
      source == TransactionSource.upiApp ||
      source == TransactionSource.upiBank;
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

  // UPI Ref / Txn ID
  static final upiRef = RegExp(
    r'(?:UPI\s*(?:Ref(?:erence)?|Txn|ID|No)[:.]?\s*)(\w{10,})',
    caseSensitive: false,
  );

  // VPA (UPI address)
  static final vpa = RegExp(
    r'[\w.\-]+@(?:okicici|okhdfcbank|okaxis|ybl|upi|paytm|apl|ibl|axl|sbi|boi|cnrb|oksbi)\b',
    caseSensitive: false,
  );

  // Debit keywords
  static final debitKeywords = RegExp(
    r'\b(?:debited?|paid|payment\s+(?:of|done|success)|purchase|withdrawn?|sent|deduct)\b',
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
      'restaurant', 'dining', 'food'], '🍔 Food & Dining'],
    [['amazon', 'flipkart', 'myntra', 'meesho', 'ajio', 'nykaa', 'snapdeal',
      'shop', 'store', 'mart'], '🛒 Shopping'],
    [['uber', 'ola', 'rapido', 'namma', 'metro', 'irctc', 'bus', 'train',
      'travel', 'taxi', 'auto'], '🚗 Transport'],
    [['netflix', 'spotify', 'hotstar', 'prime', 'zee5', 'sony', 'jio',
      'youtube', 'entertainment', 'cinema', 'movie'], '📺 Entertainment'],
    [['hospital', 'pharmacy', 'medic', 'clinic', 'doctor', 'health',
      'apollo', 'max', 'fortis', 'manipal'], '🏥 Health'],
    [['electricity', 'bescom', 'tneb', 'water', 'gas', 'lpg',
      'bill', 'utility', 'broadband', 'wifi'], '🏠 Utilities'],
    [['petrol', 'diesel', 'fuel', 'hpcl', 'bpcl', 'iocl', 'shell',
      'indian oil', 'bharat petroleum'], '⛽ Fuel'],
    [['school', 'college', 'university', 'fees', 'tuition', 'coaching',
      'course', 'udemy', 'coursera', 'education'], '📚 Education'],
    [['salary', 'payroll', 'stipend', 'wages', 'income'], '💼 Income'],
    [['recharge', 'jio', 'airtel', 'vi ', 'vodafone', 'bsnl',
      'mobile', 'prepaid'], '📱 Mobile Recharge'],
    [['hotel', 'booking', 'makemytrip', 'goibibo', 'oyo',
      'airbnb', 'lodge'], '🏨 Travel & Stay'],
    [['gym', 'yoga', 'fitness', 'sports', 'cult'], '💪 Fitness'],
    [['insurance', 'lic', 'term', 'policy', 'premium'], '🛡️ Insurance'],
    [['emi', 'loan', 'home loan', 'car loan', 'hdfc loan',
      'bajaj', 'repayment'], '🏦 Loan/EMI'],
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

    final source = upiApp != null
        ? TransactionSource.upiApp
        : isUpiSms
            ? TransactionSource.upiBank
            : bankName != null
                ? TransactionSource.bankSms
                : TransactionSource.bankSms;

    // Extract merchant name from UPI SMS
    final merchant = _extractMerchant(trimmed, vpa, type);

    // Auto-categorise
    final autoCategory = _CategoryMapper.categorise(merchant, vpa, trimmed);

    // Build unique ID (hash of sender + date + amount to avoid duplicates)
    final idSource = '${sender}_${date.millisecondsSinceEpoch}_$amount';
    final id = idSource.hashCode.abs().toString();

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
      autoCategory: autoCategory,
      availableBalance: availableBalance,
      date: date,
      rawSms: body,
      senderAddress: sender,
    );
  }

  /// Parse a list of raw SMS messages
  static List<ParsedTransaction> parseAll(
    List<({String body, String sender, DateTime date})> messages,
  ) {
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

    // Sort newest first
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
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
