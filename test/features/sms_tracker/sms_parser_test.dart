import 'package:flutter_test/flutter_test.dart';
import 'package:kanakkufi/features/category/domain/category_entity.dart';
import 'package:kanakkufi/features/sms_tracker/data/sms_parser_service.dart';
import 'package:kanakkufi/features/sms_tracker/presentation/widgets/insights_generator.dart';

void main() {
  group('SmsParserService — Bank & UPI Parsing', () {
    test('parses HDFC bank debit SMS with merchant and balance', () {
      final now = DateTime.now();
      const body =
          'Rs.540.00 debited from A/c **4321 on 11-Oct at Swiggy. Avail bal: Rs.48,250.00';
      final parsed = SmsParserService.parse(
        body: body,
        sender: 'HDFCBK',
        date: now,
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(540.0));
      expect(parsed.isDebit, isTrue);
      expect(parsed.bankName, equals('HDFC'));
      expect(parsed.accountLast4, equals('4321'));
      expect(parsed.availableBalance, equals(48250.0));
      expect(parsed.autoCategory, contains('Food'));
    });

    test('parses SBI salary credit SMS', () {
      final now = DateTime.now();
      const body =
          'Rs.65,000.00 credited to A/c XX1234 on 01-Oct by SALARY TRANSFER. Avail bal: Rs.72,100.00';
      final parsed = SmsParserService.parse(
        body: body,
        sender: 'SBIINB',
        date: now,
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(65000.0));
      expect(parsed.isCredit, isTrue);
      expect(parsed.bankName, equals('SBI'));
      expect(parsed.accountLast4, equals('1234'));
      expect(parsed.availableBalance, equals(72100.0));
    });

    test('parses Google Pay UPI payment', () {
      final now = DateTime.now();
      const body =
          'You have successfully paid Rs.350 to Uber India via UPI. Ref No: 428194829103';
      final parsed = SmsParserService.parse(
        body: body,
        sender: 'GPAY',
        date: now,
      );

      expect(parsed, isNotNull);
      expect(parsed!.amount, equals(350.0));
      expect(parsed.isDebit, isTrue);
      expect(parsed.isUpi, isTrue);
      expect(parsed.autoCategory, contains('Transport'));
    });

    test('ignores OTP and non-financial SMS', () {
      final now = DateTime.now();
      const otpBody =
          'Your OTP for login is 492019. Do not share this with anyone. - SBI';
      final parsed = SmsParserService.parse(
        body: otpBody,
        sender: 'SBIINB',
        date: now,
      );

      expect(parsed, isNull);
    });
  });

  group('SmsParserService — Credit Cards & Bank Balances', () {
    test('extracts credit card statement details', () {
      final now = DateTime.now();
      final messages = [
        (
          body:
              'HDFC Bank Credit Card XX4321 — Statement due ₹14,500 by 25 Oct. Min due Rs.1,450. Avail limit: Rs.85,500',
          sender: 'HDFCCC',
          date: now,
        ),
      ];

      final cards = SmsParserService.extractCreditCards(messages);
      expect(cards.length, equals(1));
      final card = cards.first;
      expect(card.bankName, equals('HDFC'));
      expect(card.cardLast4, equals('4321'));
      expect(card.totalDue, equals(14500.0));
      expect(card.minDue, equals(1450.0));
      expect(card.dueDate, equals('25 Oct'));
      expect(card.availableLimit, equals(85500.0));
    });

    test('extracts bank accounts and sorts by balance', () {
      final now = DateTime.now();
      final txns = [
        ParsedTransaction(
          id: '1',
          amount: 500,
          type: TransactionType.debit,
          source: TransactionSource.bankSms,
          bankName: 'HDFC',
          accountLast4: '4321',
          availableBalance: 48250.0,
          date: now,
          rawSms: '',
          senderAddress: 'HDFCBK',
        ),
        ParsedTransaction(
          id: '2',
          amount: 1000,
          type: TransactionType.credit,
          source: TransactionSource.bankSms,
          bankName: 'SBI',
          accountLast4: '1234',
          availableBalance: 72100.0,
          date: now,
          rawSms: '',
          senderAddress: 'SBIINB',
        ),
      ];

      final balances = SmsParserService.extractBankBalances(txns);
      expect(balances.length, equals(2));
      // Sorted highest balance first
      expect(balances.first.bankName, equals('SBI'));
      expect(balances.first.balance, equals(72100.0));
      expect(balances.last.bankName, equals('HDFC'));
    });
  });

  group('InsightsGenerator', () {
    test('generates card due and liquid balance insights', () {
      final now = DateTime.now();
      final cards = [
        CreditCardDetails(
          bankName: 'HDFC',
          cardLast4: '4321',
          totalDue: 14500.0,
          minDue: 1450.0,
          dueDate: '25 Oct',
          lastUpdated: now,
        ),
      ];
      final balances = [
        BankAccountBalance(
          bankName: 'SBI',
          accountLast4: '1234',
          balance: 72100.0,
          lastUpdated: now,
        ),
      ];

      final insights = InsightsGenerator.generate(
        transactions: [],
        creditCards: cards,
        bankBalances: balances,
      );

      expect(insights.isNotEmpty, isTrue);
      expect(insights.any((i) => i.type == InsightType.creditCardDue), isTrue);
      expect(insights.any((i) => i.type == InsightType.bankBalance), isTrue);
    });
  });

  group('Automatic Category Resolution & Live Tracking Cutoff', () {
    test('smsTrackingStartDate returns live cutoff date and can be customized', () {
      final now = DateTime.now();
      expect(
        SmsParserService.smsTrackingStartDate
            .isBefore(now.add(const Duration(seconds: 1))),
        isTrue,
      );

      final custom = DateTime(2026, 10, 11, 20, 0, 0);
      SmsParserService.setTrackingStartDate(custom);
      expect(SmsParserService.smsTrackingStartDate, equals(custom));
      SmsParserService.resetTrackingStartDate();
    });

    test('resolves debit with known category from SMS', () {
      final now = DateTime.now();
      final txn = SmsParserService.parse(
        body: 'Rs.350 paid to Swiggy via UPI. Avail bal: Rs.10,000',
        sender: 'GPAY',
        date: now,
      );

      expect(txn, isNotNull);
      expect(txn!.isDebit, isTrue);
      expect(txn.resolveCategory(), contains('Food'));
    });

    test('resolves debit via UPI without merchant category to UPI category', () {
      final now = DateTime.now();
      final txn = SmsParserService.parse(
        body: 'Rs.200 sent to 9876543210@upi via PhonePe. Txn ID: 1982739182',
        sender: 'PHONEPE',
        date: now,
      );

      expect(txn, isNotNull);
      expect(txn!.isDebit, isTrue);
      expect(txn.resolveCategory(), equals('⚡ UPI'));
    });

    test('resolves debit via Card without category to Card category', () {
      final now = DateTime.now();
      final txn = SmsParserService.parse(
        body: 'INR 1,200.00 spent on your Credit Card ending with 4321.',
        sender: 'HDFCCC',
        date: now,
      );

      expect(txn, isNotNull);
      expect(txn!.isDebit, isTrue);
      expect(txn.resolveCategory(), equals('💳 Card'));
    });

    test('resolves credit to Income category automatically', () {
      final now = DateTime.now();
      final txn = SmsParserService.parse(
        body: 'Rs.25,000 credited to A/c XX1234 on 02-Oct. Avail bal: Rs.30,000',
        sender: 'HDFCBK',
        date: now,
      );

      expect(txn, isNotNull);
      expect(txn!.isCredit, isTrue);
      expect(txn.resolveCategory(), equals('💼 Income'));
    });

    test('resolves credit with cashback/salary keyword to Income', () {
      final now = DateTime.now();
      final txn = SmsParserService.parse(
        body: 'Rs.500 cashback credited to your account. Avail bal: Rs.5,000',
        sender: 'ICICIB',
        date: now,
      );

      expect(txn, isNotNull);
      expect(txn!.isCredit, isTrue);
      expect(txn.resolveCategory(), contains('Income'));
    });
  });

  group('Self-Transfer Detection & Resolution', () {
    test('pairs debit and credit with matching UPI reference as Self Transfer', () {
      final now = DateTime.now();
      final debit = SmsParserService.parse(
        body:
            'Rs.5,000.00 debited from A/c **4321 via UPI. Ref No: 428192837192. Avail bal: Rs.20,000',
        sender: 'HDFCBK',
        date: now,
      )!;

      final credit = SmsParserService.parse(
        body:
            'Rs.5,000.00 credited to A/c XX1234 via UPI. Ref No: 428192837192. Avail bal: Rs.15,000',
        sender: 'SBIINB',
        date: now.add(const Duration(seconds: 15)),
      )!;

      expect(SmsParserService.isPairMatch(debit, credit), isTrue);

      final paired = SmsParserService.identifySelfTransfers([debit, credit]);
      expect(paired.length, equals(2));
      expect(paired[0].isSelfTransfer, isTrue);
      expect(paired[1].isSelfTransfer, isTrue);
      expect(paired[0].resolveCategory(), equals('🔄 Self Transfer'));
      expect(paired[1].resolveCategory(), equals('🔄 Self Transfer'));
      expect(paired[0].resolveTitle(), contains('Self Transfer'));
      expect(paired[1].resolveTitle(), contains('Self Transfer'));
    });

    test('pairs debit and credit with same amount within 10 minutes between different banks', () {
      final now = DateTime.now();
      final debit = SmsParserService.parse(
        body: 'Rs.2,500 debited from A/c **4321 on 11-Oct. Avail bal: Rs.18,000',
        sender: 'HDFCBK',
        date: now,
      )!;

      final credit = SmsParserService.parse(
        body: 'Rs.2,500 credited to A/c XX9876 on 11-Oct. Avail bal: Rs.12,500',
        sender: 'ICICIB',
        date: now.add(const Duration(minutes: 3)),
      )!;

      expect(SmsParserService.isPairMatch(debit, credit), isTrue);

      final paired = SmsParserService.identifySelfTransfers([debit, credit]);
      expect(paired.every((t) => t.isSelfTransfer), isTrue);
      expect(paired.every((t) => t.resolveCategory() == '🔄 Self Transfer'), isTrue);
    });

    test('identifies self transfer when remitter matches user name', () {
      final now = DateTime.now();
      final credit = SmsParserService.parse(
        body:
            'Rs.10,000 credited to A/c **4321 by transfer from Vishnu Anil. Avail bal: Rs.35,000',
        sender: 'HDFCBK',
        date: now,
      )!;

      final identified = SmsParserService.identifySelfTransfers(
        [credit],
        userName: 'Vishnu Anil',
      );

      expect(identified.first.isSelfTransfer, isTrue);
      expect(identified.first.resolveCategory(), equals('🔄 Self Transfer'));
    });

    test('getCategoryByName maps 🔄 Self Transfer to self_transfer CategoryEntity', () {
      final cat = getCategoryByName('🔄 Self Transfer');
      expect(cat.id, equals('self_transfer'));
      expect(cat.name, equals('Self Transfer'));
    });

    test('self transfers are flagged with isSelfTransfer true for database exclusion', () {
      final now = DateTime.now();
      final debit = SmsParserService.parse(
        body:
            'Rs.3,000.00 debited from A/c **4321 to self transfer. Avail bal: Rs.15,000',
        sender: 'HDFCBK',
        date: now,
      )!;

      final identified = SmsParserService.identifySelfTransfers([debit]);
      expect(identified.first.isSelfTransfer, isTrue);
      expect(identified.first.resolveCategory(), equals('🔄 Self Transfer'));
    });
  });
}
