import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../auth/presentation/auth_viewmodel.dart';
import '../../profile/presentation/profile_viewmodel.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import '../../pregnancy/domain/pregnancy_calculator.dart';
import '../../pregnancy/presentation/pregnancy_viewmodel.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_total_balance_card.dart';
import 'widgets/dashboard_section_header.dart';
import 'widgets/dashboard_hook_card.dart';
import 'widgets/transaction_item.dart';
import 'widgets/statistics_section.dart';
import 'dashboard_viewmodel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final viewModel = ref.read(dashboardProvider.notifier);
    final pregnancyState = ref.watch(pregnancyProvider);
    final showTrimesterTabs = state.viewType == 'Trimester';
    final profileState = ref.watch(profileProvider);
    final name =
        profileState.profile?.fullName?.isNotEmpty == true
            ? profileState.profile!.fullName!
            : 'Hello';
final pregnancy = pregnancyState.profile;

final pregnancySummary =
    (pregnancy != null && pregnancy.isActive)
        ? "Week ${PregnancyCalculator.calculateWeek(pregnancy.startDate)} • "
          "Trimester ${PregnancyCalculator.calculateTrimester(
              PregnancyCalculator.calculateWeek(pregnancy.startDate))}"
        : null;

    final displayAmount =
        state.viewType == 'Trimester' ? state.totalExpenses * 3.2 : state.totalExpenses;
    final totalLabel =
        state.viewType == 'Trimester'
            ? "Total ${state.selectedPeriod} Spend"
            : "Total Monthly Spend";

    ref.listen(pregnancyProvider, (prev, next) {
      if (!next.isEnabled) {
        ref.read(dashboardProvider.notifier).resetToDefaultView();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              DashboardHeader(
                name: name,
                pregnancySummary: pregnancySummary,
                onProfileTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) => const EditProfileSheet(),
                  );
                },
                onLogoutTap: () async {
                  final confirmed = await showConfirmationDialog(
                    context: context,
                    title: 'Logout',
                    message: 'Are you sure you want to logout?',
                    confirmText: 'Logout',
                    cancelText: 'Cancel',
                    isDangerous: true,
                  );

                  if (confirmed == true) {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/auth');
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              DashboardTotalBalanceCard(
                total: displayAmount,
                label: totalLabel,
              ),
              const SizedBox(height: 32),
              const DashboardSectionHeader(title: "Spending Wisdom"),
              const SizedBox(height: 12),
              const DashboardHookCard(),
              const SizedBox(height: 32),
              StatisticsSection(
                state: state,
                viewModel: viewModel,
                pregnancyState: pregnancyState,
                showTrimesterTabs: showTrimesterTabs,
              ),
              const SizedBox(height: 32),
              const DashboardSectionHeader(title: "Recent Transactions"),
              const SizedBox(height: 12),
              ...state.expenses.map((e) => TransactionItem(item: e)),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await context.push('/add-expense');
          if (result is Map<String, dynamic>) {
            final amount = result["amount"] as double?;
            final title = result["title"] as String?;
            final date = result["date"] as DateTime?;

            if (amount != null && title != null && date != null) {
              viewModel.addExpense(
                title: title,
                amount: amount,
                date: date,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Expense added")),
                );
              }
            }
          }
        },
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Add Expense",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }


}
