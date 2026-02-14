import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../dashboard_state.dart';
import '../dashboard_viewmodel.dart';

class PeriodTabs extends StatelessWidget {
  final DashboardState state;
  final DashboardViewModel viewModel;
  final bool showTrimesterTabs;

  const PeriodTabs({
    super.key,
    required this.state,
    required this.viewModel,
    required this.showTrimesterTabs,
  });

@override
Widget build(BuildContext context) {
  final isPregnancyActive = showTrimesterTabs;

  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 400),
    transitionBuilder: (child, animation) {
      return FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axis: Axis.vertical,
          child: child,
        ),
      );
    },
    child: isPregnancyActive
        ? _buildTrimesterTabs()
        : _buildNormalTabs(),
  );
}

  Widget _buildNormalTabs() {
    return Row(
      key: const ValueKey("normal"),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPeriodTab('Week'),
        _buildPeriodTab('Month'),
        _buildPeriodTab('Year'),
      ],
    );
  }

  Widget _buildTrimesterTabs() {
    return Row(
      key: const ValueKey("preg"),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPeriodTab('Trimester 1'),
        _buildPeriodTab('Trimester 2'),
        _buildPeriodTab('Trimester 3'),
      ],
    );
  }

Widget _buildPeriodTab(String period) {
  final bool isSelected = state.selectedPeriod == period;

  return GestureDetector(
    onTap: () {
      if (!showTrimesterTabs &&
          period.contains("Trimester")) {
        return; // Safety guard
      }

      viewModel.changePeriod(period);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        period,
        style: GoogleFonts.inter(
          color: isSelected
              ? Colors.white
              : AppColors.textSecondary,
          fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ),
  );
}
}
