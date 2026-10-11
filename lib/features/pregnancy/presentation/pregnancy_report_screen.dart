import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../dashboard/presentation/widgets/edit_expense_bottom_sheet.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import 'pregnancy_report_state.dart';
import 'pregnancy_report_viewmodel.dart';
import 'widgets/category_analytics_section.dart';
import 'widgets/pregnancy_expense_list_item.dart';
import 'widgets/pregnancy_report_hero_card.dart';
import 'widgets/trimester_breakdown_card.dart';

class PregnancyReportScreen extends ConsumerStatefulWidget {
  const PregnancyReportScreen({super.key});

  @override
  ConsumerState<PregnancyReportScreen> createState() =>
      _PregnancyReportScreenState();
}

class _PregnancyReportScreenState extends ConsumerState<PregnancyReportScreen> {
  final TextEditingController _searchController = TextEditingController();

  // ── Share card ───────────────────────────────────────────────────
  final GlobalKey _heroCardKey = GlobalKey();
  bool _isSharing = false;

  /// Captures the dark hero card as a 3× PNG and shares it natively
  Future<void> _shareHeroCard(PregnancyReportState state) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      // Give the widget one frame to render with the key attached
      await Future.delayed(const Duration(milliseconds: 80));

      final boundary = _heroCardKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Card not rendered yet');

      // 3× pixel ratio = crisp on high-DPI screens
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode image');

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kanakkufi_pregnancy_report.png');
      await file.writeAsBytes(pngBytes);

      final data = state.reportData!;
      final totalFmt = NumberFormat('#,##0.00', 'en_IN');
      final caption =
          '🤰 My Pregnancy Expense Summary\n'
          '💰 Total: ₹${totalFmt.format(data.totalExpenses)}\n'
          '📅 Week ${data.currentWeek} • Trimester ${data.currentTrimester}\n'
          '📊 ${(data.progress * 100).toInt()}% complete • ${data.daysRemaining} days left\n'
          '\nTracked with KanakkuFi 💜';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: caption,
          subject: 'My Pregnancy Expense Report',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share card: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortMenu(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(pregnancyReportProvider).sortOrder;
    final notifier = ref.read(pregnancyReportProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Sort Expenses",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSortOption(
                  title: "Newest First",
                  icon: Icons.calendar_today_rounded,
                  selected: currentSort == PregnancySortOrder.newestFirst,
                  onTap: () {
                    notifier.setSortOrder(PregnancySortOrder.newestFirst);
                    Navigator.pop(context);
                  },
                ),
                _buildSortOption(
                  title: "Oldest First",
                  icon: Icons.history_rounded,
                  selected: currentSort == PregnancySortOrder.oldestFirst,
                  onTap: () {
                    notifier.setSortOrder(PregnancySortOrder.oldestFirst);
                    Navigator.pop(context);
                  },
                ),
                _buildSortOption(
                  title: "Highest Amount",
                  icon: Icons.arrow_upward_rounded,
                  selected: currentSort == PregnancySortOrder.highestAmount,
                  onTap: () {
                    notifier.setSortOrder(PregnancySortOrder.highestAmount);
                    Navigator.pop(context);
                  },
                ),
                _buildSortOption(
                  title: "Lowest Amount",
                  icon: Icons.arrow_downward_rounded,
                  selected: currentSort == PregnancySortOrder.lowestAmount,
                  onTap: () {
                    notifier.setSortOrder(PregnancySortOrder.lowestAmount);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.text,
          ),
        ),
        trailing:
            selected
                ? const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                )
                : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pregnancyReportProvider);
    final notifier = ref.read(pregnancyReportProvider.notifier);
    final currencyFmt = NumberFormat('#,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.text,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pregnancy Report",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            Text(
              "Standalone Maternity Expense Analysis",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (state.reportData != null) ...[
            IconButton(
              icon: const Icon(
                Icons.sort_rounded,
                color: AppColors.text,
                size: 22,
              ),
              tooltip: "Sort",
              onPressed: () => _showSortMenu(context, ref),
            ),
            IconButton(
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.text,
                      ),
                    )
                  : const Icon(
                      Icons.share_outlined,
                      color: AppColors.text,
                      size: 22,
                    ),
              tooltip: 'Share Card',
              onPressed: state.reportData == null
                  ? null
                  : () => _shareHeroCard(state),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => notifier.fetchReport(),
          child:
              state.isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                  : state.reportData == null
                  ? _buildEmptyOrDisabledState(context, state.errorMessage)
                  : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Overview Card — wrapped in RepaintBoundary for image capture
                        RepaintBoundary(
                          key: _heroCardKey,
                          child: PregnancyReportHeroCard(data: state.reportData!),
                        ),
                        const SizedBox(height: 24),

                        // Trimester Breakdown
                        TrimesterBreakdownSection(
                          summaries: state.reportData!.trimesterSummaries,
                          selectedTrimester: state.selectedTrimester,
                          currentTrimester: state.reportData!.currentTrimester,
                          onTrimesterSelected: notifier.filterByTrimester,
                        ),
                        const SizedBox(height: 24),

                        // Category Analytics
                        CategoryAnalyticsSection(
                          summaries: state.reportData!.categorySummaries,
                          selectedCategory: state.selectedCategory,
                          onCategorySelected: notifier.filterByCategory,
                        ),
                        const SizedBox(height: 28),

                        // Itemized Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pregnancy Expenses Alone",
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${state.filteredCount} items • ₹${currencyFmt.format(state.filteredTotal)}",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow.withAlpha(5),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: notifier.search,
                            decoration: InputDecoration(
                              hintText: "Search notes, bills, doctor...",
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary.withAlpha(160),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          notifier.search('');
                                        },
                                      )
                                      : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // List of pregnancy expenses alone
                        if (state.filteredItems.isEmpty)
                          _buildNoExpensesMatchingState()
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = state.filteredItems[index];
                              return PregnancyExpenseListItem(
                                item: item,
                                onTap: () {
                                  // Open edit modal for quick inspection or adjustment
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder:
                                        (context) => EditExpenseBottomSheet(
                                          item: {
                                            "id": item.id,
                                            "title": item.title,
                                            "amount": item.amount,
                                            "dateTime": item.dateTime,
                                            "note": item.note,
                                          },
                                        ),
                                  ).then((_) {
                                    notifier.fetchReport();
                                  });
                                },
                              );
                            },
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildEmptyOrDisabledState(BuildContext context, String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pregnant_woman_rounded,
                size: 64,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Pregnancy Tracking Inactive",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  "Enable Pregnancy Mode in your profile to generate and view dedicated pregnancy expense reports.",
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
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
                ).then((_) {
                  ref.read(pregnancyReportProvider.notifier).fetchReport();
                });
              },
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                "Enable in Profile",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoExpensesMatchingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppColors.textSecondary.withAlpha(120),
          ),
          const SizedBox(height: 12),
          Text(
            "No Expenses Found",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Try clearing your search or trimester/category filter to view all pregnancy expenses.",
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
