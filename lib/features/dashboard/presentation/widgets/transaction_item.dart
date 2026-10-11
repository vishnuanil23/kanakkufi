import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../category/domain/category_entity.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../dashboard_viewmodel.dart';
import 'edit_expense_bottom_sheet.dart';

class TransactionItem extends ConsumerWidget {
  final Map<String, dynamic> item;

  const TransactionItem({super.key, required this.item});

  String _getFormattedDate(dynamic dateObj) {
    if (dateObj is! DateTime) return dateObj.toString();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(dateObj.year, dateObj.month, dateObj.day);

    if (itemDate == today) return "Today";
    if (itemDate == yesterday) return "Yesterday";
    return DateFormat("dd MMM, yyyy").format(dateObj);
  }

  void _showEditBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditExpenseBottomSheet(item: item),
    );
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: "Delete Transaction",
      message: "Are you sure you want to delete this transaction?",
      confirmText: "Delete",
      isDangerous: true,
    );

    if (confirmed == true) {
      ref.read(dashboardProvider.notifier).deleteExpense(item["id"]);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = item["title"].toString();
    final category = getCategoryByName(title);
    final dateTime = item["dateTime"];
    final isIncome = title.toLowerCase().contains('income');
    final isSelfTransfer = title.toLowerCase().contains('self transfer');

    return Slidable(
      key: ValueKey(item["id"]),
      endActionPane: ActionPane(
        extentRatio: 0.5,
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _showEditBottomSheet(context),
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.primary,
            icon: Icons.edit_rounded,
            label: 'Edit',
            borderRadius: BorderRadius.circular(20),
          ),
          SlidableAction(
            onPressed: (context) => _deleteExpense(context, ref),
            backgroundColor: AppColors.error.withAlpha(25),
            foregroundColor: AppColors.error,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showEditBottomSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withAlpha(8),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.shadow.withAlpha(5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelfTransfer
                      ? const Color(0xFFEEF2FF)
                      : (isIncome
                          ? const Color(0xFFD1FAE5)
                          : AppColors.accent.withAlpha(25)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.icon,
                  color: isSelfTransfer
                      ? const Color(0xFF4F46E5)
                      : (isIncome
                          ? const Color(0xFF059669)
                          : AppColors.goldDark),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isSelfTransfer
                            ? const Color(0xFF3730A3)
                            : (isIncome
                                ? const Color(0xFF065F46)
                                : AppColors.primary),
                      ),
                    ),
                    if (isSelfTransfer)
                      Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 2),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFFC7D2FE),
                                ),
                              ),
                              child: Text(
                                'Self Transfer • Excluded from totals',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item["note"] != null &&
                        item["note"].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          item["note"].toString(),
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      _getFormattedDate(dateTime),
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary.withAlpha(180),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${isIncome ? '+' : ''}₹${NumberFormat("#,##0.00", "en_IN").format(double.tryParse(item["amount"].toString()) ?? 0)}",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: isSelfTransfer
                      ? const Color(0xFF4F46E5)
                      : (isIncome
                          ? const Color(0xFF10B981)
                          : AppColors.navyDeep),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
