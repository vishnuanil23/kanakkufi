import 'package:flutter_test/flutter_test.dart';
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
}
