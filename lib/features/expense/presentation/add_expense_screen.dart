import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../category/domain/category_entity.dart';
import 'expense_viewmodel.dart';
import 'widgets/amount_input_card.dart';
import 'widgets/amount_summary_card.dart';
import 'widgets/date_picker_card.dart';
import 'widgets/expense_category_grid.dart';
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
  final TextEditingController _noteController =
      TextEditingController();

  String _selectedCategory = "Doctor";
  String _selectedCurrency = "INR";
  DateTime _selectedDate = DateTime.now();

  double get _amount =>
      double.tryParse(_amountController.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "en_IN");
    final expenseVM = ref.watch(addExpenseProvider);

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
              displayAmount:
                  _selectedCurrency == "AED" &&
                          expenseVM.convertedAmount != null
                      ? formatter.format(expenseVM.convertedAmount)
                      : formatter.format(_amount),
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
            const SizedBox(height: 20),
            const ExpenseSectionHeader(text: "Note"),
            const SizedBox(height: 12),
            _buildNoteField(),
            const SizedBox(height: 40),
            _buildSubmitButton(expenseVM),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return ExpenseCategoryGrid(
      categories: expenseCategories,
      selectedCategory: _selectedCategory,
      onSelected: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
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
                if (_selectedCurrency == "AED") {
                  ref.read(addExpenseProvider).onAmountOrDateChanged(
                        amount: _amount,
                        date: _selectedDate,
                      );
                }
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AmountInputCard(
            controller: _amountController,
            selectedCurrency: _selectedCurrency,
            onCurrencyChanged: (value) {
              setState(() {
                _selectedCurrency = value;
              });
              if (_selectedCurrency == "AED") {
                if (_selectedCurrency == "AED") {
                  ref.read(addExpenseProvider).onAmountOrDateChanged(
                        amount: _amount,
                        date: _selectedDate,
                      );
                }
              }
            },
            onChanged: (_) {
              setState(() {});
              if (_selectedCurrency == "AED") {
                ref.read(addExpenseProvider).onAmountOrDateChanged(
                      amount: _amount,
                      date: _selectedDate,
                    );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AddExpenseViewModel expenseVM) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed:
            _amount > 0 ? () => _insertExpense(expenseVM) : null,
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

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: "Add a note (optional)",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.text,
      ),
    );
  }

  Future<void> _insertExpense(AddExpenseViewModel expenseVM) async {
    final amountInr = expenseVM.convertedAmount;
    final finalAmount =
        _selectedCurrency == "AED" && amountInr != null
            ? amountInr
            : _amount;
    final note = _noteController.text.trim();

    final payload = {
      "title": _selectedCategory,
      "amount": finalAmount,
      "date": _selectedDate,
      "note": note.isEmpty ? null : note,
    };

    if (mounted) {
      Navigator.pop(context, payload);
    }

    unawaited(
      expenseVM.addExpense(
        category: _selectedCategory,
        amount: finalAmount,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

}
