import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../category/domain/category_entity.dart';
import '../../../expense/presentation/widgets/amount_input_card.dart';
import '../../../expense/presentation/widgets/date_picker_card.dart';
import '../../../expense/presentation/widgets/expense_category_grid.dart';
import '../dashboard_viewmodel.dart';

class EditExpenseBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;

  const EditExpenseBottomSheet({super.key, required this.item});

  @override
  ConsumerState<EditExpenseBottomSheet> createState() =>
      _EditExpenseBottomSheetState();
}

class _EditExpenseBottomSheetState
    extends ConsumerState<EditExpenseBottomSheet> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late CategoryEntity _selectedCategory;
  String _selectedCurrency = "INR";
  bool _showValidationError = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.item["amount"].toString(),
    );
    _noteController = TextEditingController(text: widget.item["note"] ?? "");
    _selectedDate = widget.item["dateTime"] ?? DateTime.now();
    _selectedCategory = getCategoryByName(widget.item["title"].toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0.0;

  void _updateExpense() {
    if (_amount <= 0) {
      setState(() {
        _showValidationError = true;
      });
      return;
    }

    ref
        .read(dashboardProvider.notifier)
        .updateExpense(
          id: widget.item["id"],
          category: _selectedCategory.name,
          amount: _amount,
          date: _selectedDate,
          note: _noteController.text,
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Transaction",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "Category",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ExpenseCategoryGrid(
                categories: expenseCategories,
                selectedCategory: _selectedCategory,
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              Text(
                "Date & Amount",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: DatePickerCard(
                        formattedDate: DateFormat(
                          "MMM dd, yyyy",
                        ).format(_selectedDate),
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
                        hasError: _showValidationError,
                        selectedCurrency: _selectedCurrency,
                        onCurrencyChanged: (value) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                        },
                        onChanged: (_) {
                          if (_showValidationError) {
                            setState(() {
                              _showValidationError = false;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Note",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.text,
                ),
                decoration: InputDecoration(
                  hintText: "What was this for?",
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _updateExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    "Save Changes",
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
