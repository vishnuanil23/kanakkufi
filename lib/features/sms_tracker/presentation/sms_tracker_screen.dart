import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../data/sms_parser_service.dart';
import 'sms_tracker_viewmodel.dart';

class SmsTrackerScreen extends ConsumerWidget {
  const SmsTrackerScreen({super.key});

  void _showConfirmSheet(
    BuildContext context,
    WidgetRef ref,
    ParsedTransaction txn,
  ) {
    String selectedCategory = txn.autoCategory ?? '🍔 Food & Dining';
    final titleController = TextEditingController(
      text: txn.merchant ?? txn.bankName ?? 'Expense',
    );

    const categories = [
      '🍔 Food & Dining',
      '🛒 Shopping',
      '🚗 Transport',
      '🏥 Health & Medical',
      '🏠 Utilities',
      '📺 Entertainment',
      '⛽ Fuel',
      '💼 Income',
      '📌 Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      txn.isDebit ? 'Confirm Expense' : 'Confirm Income',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Transaction Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => selectedCategory = cat);
                            }
                          },
                          selectedColor: AppColors.primary.withAlpha(40),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.text,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref
                              .read(smsTrackerProvider.notifier)
                              .confirmTransaction(
                                transaction: txn,
                                category: selectedCategory,
                                title: titleController.text.trim(),
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added ₹${txn.amount.toStringAsFixed(0)} to your expenses!',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Save to Expenses',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smsTrackerProvider);
    final viewModel = ref.read(smsTrackerProvider.notifier);
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'SMS Expense Tracker',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.text,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sync SMS',
            icon: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded, color: AppColors.text),
            onPressed: () => viewModel.syncSms(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => viewModel.syncSms(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Permission Warning Banner if not granted
                if (!state.hasPermission)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.security_rounded,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SMS Permission Needed',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Allow KanakkuFi to read incoming bank SMS to automatically track expenses. We never read personal messages.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                              ),
                              onPressed: () => viewModel.requestPermission(),
                              child: const Text(
                                'Grant Access',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () => viewModel.syncSms(forceMock: true),
                              child: const Text('Try Demo Mode'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Summary Stats (Total In & Out)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Debits',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currencyFmt.format(state.totalDebits),
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Color(0xFF10B981),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Credits',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currencyFmt.format(state.totalCredits),
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All (${state.pendingTransactions.length})',
                        filterKey: 'all',
                        current: state.activeFilter,
                        onTap: () => viewModel.setFilter('all'),
                      ),
                      _buildFilterChip(
                        label: 'Debits',
                        filterKey: 'debits',
                        current: state.activeFilter,
                        onTap: () => viewModel.setFilter('debits'),
                      ),
                      _buildFilterChip(
                        label: 'Credits',
                        filterKey: 'credits',
                        current: state.activeFilter,
                        onTap: () => viewModel.setFilter('credits'),
                      ),
                      _buildFilterChip(
                        label: 'UPI Only',
                        filterKey: 'upi',
                        current: state.activeFilter,
                        onTap: () => viewModel.setFilter('upi'),
                      ),
                      _buildFilterChip(
                        label: 'Bank SMS',
                        filterKey: 'bank',
                        current: state.activeFilter,
                        onTap: () => viewModel.setFilter('bank'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Transaction List
                if (state.filteredTransactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withAlpha(100),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All Caught Up!',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No pending transactions to review in this filter.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => viewModel.syncSms(forceMock: true),
                            child: const Text('Load Demo Transactions'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...state.filteredTransactions.map((txn) {
                    return _buildTransactionCard(
                      context,
                      ref,
                      txn,
                      currencyFmt,
                    );
                  }),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterKey,
    required String current,
    required VoidCallback onTap,
  }) {
    final isSelected = current == filterKey;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    WidgetRef ref,
    ParsedTransaction txn,
    NumberFormat currencyFmt,
  ) {
    final viewModel = ref.read(smsTrackerProvider.notifier);
    final isDebit = txn.isDebit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge for Source / Bank
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDebit
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  txn.bankName ?? (txn.isUpi ? 'UPI' : 'Bank'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDebit
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (txn.accountLast4 != null)
                Text(
                  '•• ${txn.accountLast4}',
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              const Spacer(),
              Text(
                DateFormat('dd MMM, hh:mm a').format(txn.date),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.merchant ??
                          (txn.isUpi ? 'UPI Transfer' : 'Bank Transaction'),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      txn.autoCategory ?? '📌 Uncategorized',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isDebit ? '-' : '+'}${currencyFmt.format(txn.amount)}',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDebit
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          if (txn.availableBalance != null) ...[
            const SizedBox(height: 8),
            Text(
              'Avail Bal: ${currencyFmt.format(txn.availableBalance!)}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary.withAlpha(180),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                onPressed: () => viewModel.dismissTransaction(txn.id),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Dismiss'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showConfirmSheet(context, ref, txn),
                icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                label: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
