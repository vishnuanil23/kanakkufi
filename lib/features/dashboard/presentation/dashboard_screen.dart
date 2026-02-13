import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kanakkufi/features/pregnancy/presentation/pregnancy_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../auth/presentation/auth_viewmodel.dart';
import '../../profile/presentation/profile_viewmodel.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import '../../pregnancy/domain/pregnancy_calculator.dart';
import '../../pregnancy/presentation/pregnancy_viewmodel.dart';
import 'dashboard_viewmodel.dart';
import 'dashboard_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final viewModel = ref.read(dashboardProvider.notifier);
    final pregnancyState = ref.watch(pregnancyProvider);
    final isPregEnabled = pregnancyState.isEnabled;

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
              _buildHeader(context, ref),
              const SizedBox(height: 24),
              _buildTotalBalanceCard(state.totalExpenses, state),
              const SizedBox(height: 32),
              _buildSectionHeader("Spending Wisdom"),
              const SizedBox(height: 12),
              _buildHookCard(),
              const SizedBox(height: 32),
              _buildStatisticsSection(
                state,
                viewModel,
                pregnancyState,
                isPregEnabled,
              ),
              const SizedBox(height: 32),
              _buildSectionHeader("Recent Transactions"),
              const SizedBox(height: 12),
              ...state.expenses.map((e) => _buildTransactionItem(e)),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final name =
        profileState.profile?.fullName?.isNotEmpty == true
            ? profileState.profile!.fullName!
            : 'Hello';
    final pregnancy = ref.watch(pregnancyProvider).profile;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "WELCOME BACK",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Hello, $name",
              style: GoogleFonts.inter(
                fontSize: 28,
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (pregnancy != null) ...[
              const SizedBox(height: 6),
              Text(
                "Week ${PregnancyCalculator.calculateWeek(pregnancy.startDate)} • "
                "Trimester ${PregnancyCalculator.calculateTrimester(PregnancyCalculator.calculateWeek(pregnancy.startDate))}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.text,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.text,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard(double total, DashboardState state) {
    final double displayAmount =
        state.viewType == 'Trimester' ? total * 3.2 : total;
    final String label =
        state.viewType == 'Trimester'
            ? "Total ${state.selectedPeriod} Spend"
            : "Total Monthly Spend";

    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withAlpha(80),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navyMid, AppColors.sage],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // The "Glow" Layer
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.7, -0.6),
                    radius: 1.2,
                    colors: [
                      AppColors.mint.withAlpha(80), // ~30-40% opacity
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Text(
                        "KanakkuFi Premium",
                        style: GoogleFonts.inter(
                          color: Colors.white.withAlpha(200),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white.withAlpha(150),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Three-Tone Metallic Gold Gradient for Currency
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [
                                AppColors.goldLight,
                                AppColors.goldBright,
                                AppColors.goldDark,
                              ],
                              stops: [0.0, 0.5, 1.0],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "₹ ",
                              style: GoogleFonts.inter(
                                color: Colors.white, // Mask color
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              displayAmount.toStringAsFixed(2),
                              style: GoogleFonts.inter(
                                color: Colors.white, // Mask color
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SPENDING LIMIT",
                              style: GoogleFonts.inter(
                                color: Colors.white.withAlpha(100),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Stack(
                              children: [
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Container(
                                  height: 4,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Tier 1 Elite",
                          style: GoogleFonts.inter(
                            color: Colors.white.withAlpha(150),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            "See All",
            style: GoogleFonts.inter(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHookCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 40,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.goldLight.withAlpha(50), // Soft Gold
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.goldDark, // Deep Bronze
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Spending Wisdom",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.navyDeep, // Deep Navy
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Your spending on entertainment is 15% higher than last month. Consider a small adjustment.",
                  style: GoogleFonts.inter(
                    color: Colors.black.withAlpha(128), // 0.5 opacity
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(
    DashboardState state,
    DashboardViewModel viewModel,
    PregnancyState pregnancyState,
    bool isPregEnabled,
  ) {
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
              _buildViewTypeToggle(state, viewModel),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
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
          child:
              (isPregEnabled && state.viewType == 'Trimester')
                  ? _buildTrimesterTabs(state, viewModel)
                  : _buildNormalTabs(state, viewModel),
        ),
        const SizedBox(height: 24),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Vertical bars background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      6,
                      (index) => Container(
                        width: 40,
                        decoration: BoxDecoration(
                          color:
                              index % 2 == 0
                                  ? AppColors.primary.withAlpha(10)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                  child: LineChart(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final List<String> titles;
                              if (isPregEnabled &&
                                  state.viewType == 'Trimester') {
                                if (state.selectedPeriod == 'Trimester 1') {
                                  titles = ['Wk 1', 'Wk 4', 'Wk 8', 'Wk 12'];
                                } else if (state.selectedPeriod ==
                                    'Trimester 2') {
                                  titles = [
                                    'Wk 13',
                                    'Wk 16',
                                    'Wk 20',
                                    'Wk 24',
                                    'Wk 27',
                                  ];
                                } else {
                                  titles = ['Wk 28', 'Wk 32', 'Wk 36', 'Wk 40'];
                                }
                              } else if (state.selectedPeriod == 'Week') {
                                titles = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun',
                                ];
                              } else if (state.selectedPeriod == 'Month') {
                                titles = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
                              } else {
                                // Year (Jan..Dec)
                                titles = _yearMonthLabels();
                              }

                              if (value.toInt() < titles.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    titles[value.toInt()],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                            interval: 1,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.primary,
                          tooltipRoundedRadius: 8,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((barSpot) {
                            return LineTooltipItem(
                              '₹${barSpot.y.toStringAsFixed(2)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                      lineBarsData: [
                        LineChartBarData(
                        spots: _buildChartSpots(state),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppColors.primary,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter:
                                (spot, percent, barData, index) =>
                                    FlDotCirclePainter(
                                      radius: 4,
                                      color: Colors.white,
                                      strokeWidth: 2,
                                      strokeColor: AppColors.primary,
                                    ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withAlpha(50),
                                AppColors.primary.withAlpha(0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewTypeToggle(
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleButton('All', state, viewModel),
          _buildToggleButton('Trimester', state, viewModel),
        ],
      ),
    );
  }

  Widget _buildNormalTabs(
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
    return Row(
      key: const ValueKey("normal"),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPeriodTab('Week', state, viewModel),
        _buildPeriodTab('Month', state, viewModel),
        _buildPeriodTab('Year', state, viewModel),
      ],
    );
  }

  Widget _buildTrimesterTabs(
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
    return Row(
      key: const ValueKey("preg"),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPeriodTab('Trimester 1', state, viewModel),
        _buildPeriodTab('Trimester 2', state, viewModel),
        _buildPeriodTab('Trimester 3', state, viewModel),
      ],
    );
  }

  List<FlSpot> _buildChartSpots(DashboardState state) {
    final now = DateTime.now();
    final expenses =
        state.expenses.where((e) => e['dateTime'] is DateTime).toList();

    if (expenses.isEmpty) {
      return const [FlSpot(0, 0), FlSpot(1, 0)];
    }

    if (state.viewType == 'Trimester') {
      final buckets = List<double>.filled(4, 0);
      for (final e in expenses) {
        final date = e['dateTime'] as DateTime;
        final diffDays = now.difference(date).inDays;
        if (diffDays < 0 || diffDays > 83) continue;
        final index = 3 - (diffDays ~/ 28);
        if (index >= 0 && index < 4) {
          buckets[index] += (e['amount'] as num).toDouble();
        }
      }
      return List.generate(4, (i) => FlSpot(i.toDouble(), buckets[i]));
    }

    switch (state.selectedPeriod) {
      case 'Week':
        final buckets = List<double>.filled(7, 0);
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        for (final e in expenses) {
          final date = e['dateTime'] as DateTime;
          if (date.isBefore(start) || date.isAfter(now)) continue;
          final index = date.weekday - 1; // Mon=0 ... Sun=6
          if (index >= 0 && index < 7) {
            buckets[index] += (e['amount'] as num).toDouble();
          }
        }
        return List.generate(7, (i) => FlSpot(i.toDouble(), buckets[i]));
      case 'Month':
        final buckets = List<double>.filled(4, 0);
        for (final e in expenses) {
          final date = e['dateTime'] as DateTime;
          if (date.year != now.year || date.month != now.month) continue;
          final weekIndex = ((date.day - 1) ~/ 7).clamp(0, 3);
          buckets[weekIndex] += (e['amount'] as num).toDouble();
        }
        return List.generate(4, (i) => FlSpot(i.toDouble(), buckets[i]));
      case 'Year':
      default:
        final buckets = List<double>.filled(12, 0);
        for (final e in expenses) {
          final date = e['dateTime'] as DateTime;
          if (date.year != now.year) continue;
          final index = date.month - 1; // Jan=0
          buckets[index] += (e['amount'] as num).toDouble();
        }
        return List.generate(12, (i) => FlSpot(i.toDouble(), buckets[i]));
    }
  }

  List<String> _yearMonthLabels() {
    return const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
  }

  Widget _buildToggleButton(
    String type,
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
    final bool isSelected = state.viewType == type;
    return GestureDetector(
      onTap: () => viewModel.changeViewType(type),
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

  Widget _buildPeriodTab(
    String period,
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
    final bool isSelected = state.selectedPeriod == period;
    return GestureDetector(
      onTap: () => viewModel.changePeriod(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          period,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"].toString(),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  item["date"].toString(),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "₹ ${item["amount"]}",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
