import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/sms_parser_service.dart';

enum InsightType { topCategory, creditCardDue, bankBalance, upiActivity, income }

class SpendingInsight {
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final InsightType type;

  const SpendingInsight({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.primaryColor,
    required this.backgroundColor,
    required this.type,
  });
}

class InsightsGenerator {
  static List<SpendingInsight> generate({
    required List<ParsedTransaction> transactions,
    required List<CreditCardDetails> creditCards,
    required List<BankAccountBalance> bankBalances,
  }) {
    final insights = <SpendingInsight>[];
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // 1. Credit Card Due Alert (Highest priority if present)
    if (creditCards.isNotEmpty) {
      final card = creditCards.first;
      insights.add(
        SpendingInsight(
          title: '${card.bankName} Card Due',
          subtitle:
              '${currencyFmt.format(card.totalDue)} due ${card.dueDate ?? "soon"}${card.minDue != null ? " (Min: ${currencyFmt.format(card.minDue!)})" : ""}',
          actionLabel: 'Pay Bill',
          icon: Icons.credit_card_rounded,
          primaryColor: const Color(0xFFEF4444),
          backgroundColor: const Color(0xFFFEE2E2),
          type: InsightType.creditCardDue,
        ),
      );
    }

    // 2. Liquid Bank Balance Insight
    if (bankBalances.isNotEmpty) {
      final totalLiquid = bankBalances.fold<double>(
        0.0,
        (sum, item) => sum + item.balance,
      );
      insights.add(
        SpendingInsight(
          title: 'Total Bank Balance',
          subtitle:
              '${currencyFmt.format(totalLiquid)} across ${bankBalances.length} active accounts',
          actionLabel: 'View Accounts',
          icon: Icons.account_balance_rounded,
          primaryColor: const Color(0xFF10B981),
          backgroundColor: const Color(0xFFD1FAE5),
          type: InsightType.bankBalance,
        ),
      );
    }

    // 3. Top Spending Category
    final categoryTotals = <String, double>{};
    for (final txn in transactions.where((t) => t.isDebit)) {
      final cat = txn.autoCategory ?? 'Other';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + txn.amount;
    }

    if (categoryTotals.isNotEmpty) {
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCat = sortedCategories.first;

      insights.add(
        SpendingInsight(
          title: 'Top Spend: ${topCat.key}',
          subtitle:
              '${currencyFmt.format(topCat.value)} spent this month (${((topCat.value / (transactions.where((t) => t.isDebit).fold<double>(0.0, (s, e) => s + e.amount) + 1)) * 100).toInt()}% of debits)',
          actionLabel: 'Analyze',
          icon: Icons.pie_chart_rounded,
          primaryColor: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFFE0E7FF),
          type: InsightType.topCategory,
        ),
      );
    }

    // 4. UPI Spending Insight
    final upiDebits = transactions.where((t) => t.isUpi && t.isDebit).toList();
    if (upiDebits.isNotEmpty) {
      final upiTotal = upiDebits.fold<double>(0.0, (sum, t) => sum + t.amount);
      insights.add(
        SpendingInsight(
          title: 'UPI Daily Spends',
          subtitle:
              '${currencyFmt.format(upiTotal)} paid in ${upiDebits.length} transactions via UPI',
          actionLabel: 'Details',
          icon: Icons.bolt_rounded,
          primaryColor: const Color(0xFFF59E0B),
          backgroundColor: const Color(0xFFFEF3C7),
          type: InsightType.upiActivity,
        ),
      );
    }

    // 5. Salary / Income Credit
    final credits = transactions.where((t) => t.isCredit).toList();
    if (credits.isNotEmpty) {
      final totalCredit = credits.fold<double>(0.0, (sum, t) => sum + t.amount);
      insights.add(
        SpendingInsight(
          title: 'Total Inflow',
          subtitle:
              '${currencyFmt.format(totalCredit)} credited to accounts recently',
          actionLabel: 'Summary',
          icon: Icons.trending_up_rounded,
          primaryColor: const Color(0xFF059669),
          backgroundColor: const Color(0xFFECFDF5),
          type: InsightType.income,
        ),
      );
    }

    return insights;
  }
}
