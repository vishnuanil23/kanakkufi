import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  CategoryEntity _selectedCategory = expenseCategories.first;
  String _selectedCurrency = "INR";
  DateTime _selectedDate = DateTime.now();
  bool _showValidationError = false;

  double get _amount => double.tryParse(_amountController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _noteFocusNode.addListener(() {
      if (_noteFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    _amountController.addListener(() {
      if (_showValidationError && _amount > 0) {
        setState(() {
          _showValidationError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountSummaryCard(
                displayAmount:
                    _selectedCurrency == "AED" &&
                            expenseVM.convertedAmount != null
                        ? formatter.format(expenseVM.convertedAmount)
                        : formatter.format(_amount),
                category: _selectedCategory.name,
              ),
              const SizedBox(height: 32),
              const ExpenseSectionHeader(text: "Choose Category"),
              const SizedBox(height: 16),
              _buildCategoryGrid(),
              const SizedBox(height: 32),
              const ExpenseSectionHeader(text: "Date & Amount"),
              const SizedBox(height: 16),
              _buildDateAmountRow(),
              const SizedBox(height: 32),
              const ExpenseSectionHeader(text: "Additional Note"),
              const SizedBox(height: 16),
              _buildNoteField(),
              const SizedBox(height: 48),
              _buildSubmitButton(expenseVM),
              const SizedBox(height: 40),
            ],
          ),
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
    final formatted = DateFormat("MMM dd, yyyy").format(_selectedDate);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    ref
                        .read(addExpenseProvider)
                        .onAmountOrDateChanged(
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
              hasError: _showValidationError,
              selectedCurrency: _selectedCurrency,
              onCurrencyChanged: (value) {
                setState(() {
                  _selectedCurrency = value;
                });
                if (_selectedCurrency == "AED") {
                  ref
                      .read(addExpenseProvider)
                      .onAmountOrDateChanged(
                        amount: _amount,
                        date: _selectedDate,
                      );
                }
              },
              onChanged: (_) {
                setState(() {});
                if (_selectedCurrency == "AED") {
                  ref
                      .read(addExpenseProvider)
                      .onAmountOrDateChanged(
                        amount: _amount,
                        date: _selectedDate,
                      );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AddExpenseViewModel expenseVM) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _insertExpense(expenseVM),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withAlpha(120),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppColors.primary.withAlpha(100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          "Save Transaction",
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _noteController,
        focusNode: _noteFocusNode,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: "Add details about this expense...",
          hintStyle: GoogleFonts.inter(
            color: AppColors.textSecondary.withAlpha(150),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        style: GoogleFonts.inter(fontSize: 15, color: AppColors.text),
      ),
    );
  }

  Future<void> _insertExpense(AddExpenseViewModel expenseVM) async {
    if (_amount <= 0) {
      setState(() {
        _showValidationError = true;
      });
      HapticFeedback.lightImpact();
      return;
    }

    final amountInr = expenseVM.convertedAmount;
    final finalAmount =
        _selectedCurrency == "AED" && amountInr != null ? amountInr : _amount;
    final note = _noteController.text.trim();

    final payload = {
      "title": _selectedCategory.name,
      "amount": finalAmount,
      "date": _selectedDate,
      "note": note.isEmpty ? null : note,
    };

    if (mounted) {
      Navigator.pop(context, payload);
    }

    unawaited(
      expenseVM.addExpense(
        category: _selectedCategory.name,
        amount: finalAmount,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
      ),
    );
  }
}
