import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../core/constants/app_colors.dart';
import '../data/sms_parser_service.dart';
import 'sms_tracker_viewmodel.dart';

class SmsTrackerScreen extends ConsumerWidget {
  const SmsTrackerScreen({super.key});

  void _showEditCategorySheet(
    BuildContext context,
    WidgetRef ref,
    ParsedTransaction txn,
  ) {
    String selectedCategory = txn.resolveCategory();

    const categories = [
      '🍔 Food & Dining',
      '🛒 Shopping',
      '🚗 Transport',
      '🏥 Health',
      '🏠 Utilities',
      '📺 Entertainment',
      '⛽ Fuel',
      '⚡ UPI',
      '💳 Card',
      '🏦 Bank Transfer',
      '💼 Income',
      '🔄 Self Transfer',
      '📚 Education',
      '📱 Mobile Recharge',
      '🏨 Travel & Stay',
      '💪 Fitness',
      '🛡️ Insurance',
      '🏦 Loan/EMI',
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
                      'Change Category',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      txn.resolveTitle(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            color:
                                isSelected ? AppColors.primary : AppColors.text,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
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
                              .updateCategory(txn.id, selectedCategory);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Updated category to $selectedCategory',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Update Category',
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
          'SMS Tracker (Auto-Sync)',
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
            tooltip: 'Remove all previous SMS & track from now on',
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: AppColors.error,
            ),
            onPressed: () async {
              final confirmed = await showConfirmationDialog(
                context: context,
                title: 'Reset SMS Tracking',
                message:
                    'This will remove all previously auto-added SMS data from your expenses and income, and only track new live SMS from now onwards.',
                confirmText: 'Remove & Reset',
                isDangerous: true,
              );
              if (confirmed == true) {
                final count = await viewModel.purgePreviousSmsData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Removed $count previous SMS records. Tracking live SMS from now on.',
                      ),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Sync live SMS',
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
                const SizedBox(height: 8),

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
                          'Allow KanakkuFi to read incoming bank SMS to automatically track expenses & income. No manual review needed.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                      ],
                    ),
                  )
                else
                  // Automatic Sync Status Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withAlpha(25),
                          const Color(0xFF047857).withAlpha(12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live SMS Tracking (From Now On)',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF065F46),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Previous SMS data removed. All new incoming SMS from now onwards are auto-added without review.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Summary Stats (Total Expenses & Total Income)
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
                                  'Expenses',
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
                                  'Income',
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

                if (state.totalSelfTransfers > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Color(0xFF4F46E5),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Self Transfers: ${currencyFmt.format(state.totalSelfTransfers)} (${state.selfTransfersCount})',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3730A3),
                                ),
                              ),
                              Text(
                                'Internal transfers • Removed from expenses & income',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF4338CA).withAlpha(180),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final count = await viewModel
                                .removeSelfTransfersFromExpenses();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    count > 0
                                        ? 'Removed $count self-transfer entries from expenses'
                                        : 'All self-transfers are removed from expenses',
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.delete_sweep_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Clean Up',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All (${state.allTransactions.length})',
                        filterKey: 'all',
                        current: state.activeFilter,
                        onTap: () => viewModel.setFilter('all'),
                      ),
                      _buildFilterChip(
                        label: 'Debits (Expenses)',
                        filterKey: 'debits',
                        current: state.activeFilter,
                        onTap: () => viewModel.setFilter('debits'),
                      ),
                      _buildFilterChip(
                        label: 'Credits (Income)',
                        filterKey: 'credits',
                        current: state.activeFilter,
                        onTap: () => viewModel.setFilter('credits'),
                      ),
                      if (state.selfTransfersCount > 0)
                        _buildFilterChip(
                          label: '🔄 Self Transfers (${state.selfTransfersCount})',
                          filterKey: 'transfers',
                          current: state.activeFilter,
                          onTap: () => viewModel.setFilter('transfers'),
                        ),
                      _buildFilterChip(
                        label: 'UPI Only',
                        filterKey: 'upi',
                        current: state.activeFilter,
                        onTap: () => viewModel.setFilter('upi'),
                      ),
                      _buildFilterChip(
                        label: 'Card Only',
                        filterKey: 'card',
                        current: state.activeFilter,
                        onTap: () => viewModel.setFilter('card'),
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
                            'No Live SMS Transactions Yet',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Previous SMS data removed. All new SMS received from now on will appear here.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
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
    final isDebit = txn.isDebit;
    final resolvedCategory = txn.resolveCategory();

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
                  color: txn.isSelfTransfer
                      ? const Color(0xFFEEF2FF)
                      : (isDebit
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFD1FAE5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  txn.bankName ?? (txn.isUpi ? 'UPI' : (txn.isCard ? 'Card' : 'Bank')),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: txn.isSelfTransfer
                        ? const Color(0xFF4F46E5)
                        : (isDebit
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669)),
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
              // Status Badge (Auto-Added or Self Transfer)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: txn.isSelfTransfer
                      ? const Color(0xFFEEF2FF)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(6),
                  border: txn.isSelfTransfer
                      ? Border.all(color: const Color(0xFFC7D2FE))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      txn.isSelfTransfer
                          ? Icons.swap_horiz_rounded
                          : Icons.check_circle_rounded,
                      size: 12,
                      color: txn.isSelfTransfer
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      txn.isSelfTransfer
                          ? 'Self Transfer (Excluded)'
                          : (isDebit ? 'Added to Expenses' : 'Added to Income'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: txn.isSelfTransfer
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF059669),
                      ),
                    ),
                  ],
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
                      txn.resolveTitle(),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: txn.isSelfTransfer
                            ? const Color(0xFFEEF2FF)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: txn.isSelfTransfer
                              ? const Color(0xFFC7D2FE)
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        resolvedCategory,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: txn.isSelfTransfer
                              ? const Color(0xFF4F46E5)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    txn.isSelfTransfer
                        ? currencyFmt.format(txn.amount)
                        : '${isDebit ? '-' : '+'}${currencyFmt.format(txn.amount)}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: txn.isSelfTransfer
                          ? const Color(0xFF4F46E5)
                          : (isDebit
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(txn.date),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
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
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: txn.isSelfTransfer
                      ? const Color(0xFF4F46E5)
                      : AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () async {
                  await ref
                      .read(smsTrackerProvider.notifier)
                      .toggleSelfTransfer(txn.id, !txn.isSelfTransfer);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          txn.isSelfTransfer
                              ? 'Unmarked from Self Transfer'
                              : 'Saved as 🔄 Self Transfer (excluded from spend & income)',
                        ),
                        backgroundColor: const Color(0xFF4F46E5),
                      ),
                    );
                  }
                },
                icon: Icon(
                  txn.isSelfTransfer
                      ? Icons.check_circle_rounded
                      : Icons.swap_horiz_rounded,
                  size: 15,
                ),
                label: Text(
                  txn.isSelfTransfer ? 'Self Transfer' : 'Mark Self Transfer',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => _showEditCategorySheet(context, ref, txn),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text(
                  'Edit Category',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
