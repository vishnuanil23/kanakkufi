import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../dashboard_state.dart';
import '../dashboard_viewmodel.dart';

class ViewTypeToggle extends StatelessWidget {
  final DashboardState state;
  final DashboardViewModel viewModel;

  const ViewTypeToggle({
    super.key,
    required this.state,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleButton('All'),
          _buildToggleButton('Pregnancy'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String type) {
    final normalizedType = type == 'Pregnancy' ? 'Trimester' : type;
    final bool isSelected = state.viewType == normalizedType;
    return GestureDetector(
      onTap: () => viewModel.changeViewType(normalizedType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
