import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../dashboard_state.dart';
import '../dashboard_viewmodel.dart';
import '../../../pregnancy/presentation/pregnancy_state.dart';
import 'chart_section.dart';
import 'period_tabs.dart';
import 'view_type_toggle.dart';

class StatisticsSection extends StatelessWidget {
  final DashboardState state;
  final DashboardViewModel viewModel;
  final PregnancyState pregnancyState;
  final bool showTrimesterTabs;

  const StatisticsSection({
    super.key,
    required this.state,
    required this.viewModel,
    required this.pregnancyState,
    required this.showTrimesterTabs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "All Statistics",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            if (pregnancyState.isEnabled)
              ViewTypeToggle(state: state, viewModel: viewModel),
          ],
        ),
        const SizedBox(height: 16),
        PeriodTabs(
          state: state,
          viewModel: viewModel,
          showTrimesterTabs: showTrimesterTabs,
        ),
        const SizedBox(height: 24),
        ChartSection(
          state: state,
          pregnancyState: pregnancyState,
          showTrimesterTabs: showTrimesterTabs,
        ),
      ],
    );
  }
}
