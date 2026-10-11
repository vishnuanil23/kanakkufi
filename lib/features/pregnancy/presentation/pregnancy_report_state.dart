import '../domain/pregnancy_report_entity.dart';

enum PregnancySortOrder {
  newestFirst,
  oldestFirst,
  highestAmount,
  lowestAmount,
}

class PregnancyReportState {
  final bool isLoading;
  final String? errorMessage;
  final PregnancyReportData? reportData;
  final int? selectedTrimester; // null = all
  final String? selectedCategory; // null = all
  final String searchQuery;
  final PregnancySortOrder sortOrder;

  const PregnancyReportState({
    this.isLoading = false,
    this.errorMessage,
    this.reportData,
    this.selectedTrimester,
    this.selectedCategory,
    this.searchQuery = '',
    this.sortOrder = PregnancySortOrder.newestFirst,
  });

  PregnancyReportState copyWith({
    bool? isLoading,
    String? errorMessage,
    PregnancyReportData? reportData,
    int? selectedTrimester,
    bool clearTrimester = false,
    String? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    PregnancySortOrder? sortOrder,
  }) {
    return PregnancyReportState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      reportData: reportData ?? this.reportData,
      selectedTrimester:
          clearTrimester ? null : (selectedTrimester ?? this.selectedTrimester),
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  List<PregnancyExpenseItem> get filteredItems {
    if (reportData == null) return const [];

    List<PregnancyExpenseItem> list = List.of(reportData!.allItems);

    // Filter by trimester
    if (selectedTrimester != null) {
      list = list.where((item) => item.trimester == selectedTrimester).toList();
    }

    // Filter by category
    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      list =
          list
              .where(
                (item) =>
                    item.title.toLowerCase() == selectedCategory!.toLowerCase(),
              )
              .toList();
    }

    // Filter by search query
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list =
          list.where((item) {
            final titleMatches = item.title.toLowerCase().contains(q);
            final noteMatches =
                item.note?.toLowerCase().contains(q) ?? false;
            final amountMatches = item.amount.toString().contains(q);
            return titleMatches || noteMatches || amountMatches;
          }).toList();
    }

    // Sort items
    switch (sortOrder) {
      case PregnancySortOrder.newestFirst:
        list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
      case PregnancySortOrder.oldestFirst:
        list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case PregnancySortOrder.highestAmount:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case PregnancySortOrder.lowestAmount:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return list;
  }

  double get filteredTotal {
    return filteredItems.fold(0.0, (sum, item) => sum + item.amount);
  }

  int get filteredCount => filteredItems.length;
}
