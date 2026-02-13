import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/amount_input_card.dart';
import 'widgets/amount_summary_card.dart';
import 'widgets/date_picker_card.dart';
import 'widgets/expense_card.dart';
import 'widgets/expense_section_header.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() =>
      _AddExpenseScreenState();
}

class _AddExpenseScreenState
    extends ConsumerState<AddExpenseScreen> {
  final TextEditingController _amountController =
      TextEditingController();

  String _selectedCategory = "Doctor";
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    "Doctor",
    "Pharmacy",
    "Scan",
    "Baby Care",
    "Hospital",
    "Nutrition",
    "Travel",
    "Other",
  ];

  double get _amount =>
      double.tryParse(_amountController.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "en_IN");

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          "Add Expense",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AmountSummaryCard(
              displayAmount: formatter.format(_amount),
              category: _selectedCategory,
            ),
            const SizedBox(height: 28),
            const ExpenseSectionHeader(text: "Category"),
            const SizedBox(height: 12),
            _buildCategoryGrid(),
            const SizedBox(height: 24),
            const ExpenseSectionHeader(text: "Date"),
            const SizedBox(height: 12),
            _buildDateAmountRow(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return ExpenseCard(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected =
              _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.background,
                borderRadius:
                    BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(90),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  category,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? Colors.white
                        : AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateAmountRow() {
    final formatted =
        DateFormat("MMM dd, yyyy").format(_selectedDate);

    return Row(
      children: [
        Expanded(
          child: DatePickerCard(
            formattedDate: formatted,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );

              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AmountInputCard(
            controller: _amountController,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed:
            _amount > 0 ? _insertExpense : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withAlpha(120),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "Add Expense",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _insertExpense() async {
    final client = Supabase.instance.client;
    final userId =
        client.auth.currentUser?.id;

    final payload = {
      "title": _selectedCategory,
      "amount": _amount,
      "date": _selectedDate,
    };

    if (mounted) {
      Navigator.pop(context, payload);
    }

    unawaited(_persistExpense(userId));
  }

  Future<void> _persistExpense(String? userId) async {
    try {
      final client = Supabase.instance.client;
      await client.from('expenses').insert({
        'user_id': userId,
        'amount': _amount,
        'category': _selectedCategory,
        'expense_date':
            _selectedDate.toIso8601String(),
      });
    } catch (_) {}
  }

}
