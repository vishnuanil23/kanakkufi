import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanakkufi/core/services/quote_service.dart';
import 'package:kanakkufi/features/dashboard/presentation/widgets/dashboard_hook_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quote model & parsing', () {
    test('parses Quotable API response correctly', () {
      final sampleJson = {
        "_id": "dMJ9b4iwZ0Lj",
        "content":
            "To make no mistakes is not in the power of man; but from their errors and mistakes the wise and good learn wisdom for the future.",
        "author": "Plutarch",
        "tags": ["Famous Quotes", "Wisdom"],
        "authorSlug": "plutarch",
        "length": 129,
        "dateAdded": "2019-03-17",
        "dateModified": "2023-04-14",
      };

      final quote = Quote.fromJson(sampleJson);
      expect(
        quote.content,
        "To make no mistakes is not in the power of man; but from their errors and mistakes the wise and good learn wisdom for the future.",
      );
      expect(quote.author, "Plutarch");
    });

    test('handles missing or null fields gracefully', () {
      final emptyJson = <String, dynamic>{};
      final quote = Quote.fromJson(emptyJson);
      expect(quote.content, "");
      expect(quote.author, "Unknown");
    });
  });

  group('QuoteService caching', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'daily_quote_content':
            'To make no mistakes is not in the power of man; but from their errors and mistakes the wise and good learn wisdom for the future.',
        'daily_quote_author': 'Plutarch',
        'daily_quote_date': '2026-10-11',
      });
    });

    test('retrieves cached quote if date matches today', () async {
      final quote = await QuoteService.getDailyQuote();
      expect(quote.author, 'Plutarch');
      expect(quote.content, contains('To make no mistakes'));
    });
  });

  group('DashboardHookCard widget', () {
    testWidgets('renders Spending Wisdom card with quote and author', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'daily_quote_content':
            'To make no mistakes is not in the power of man; but from their errors and mistakes the wise and good learn wisdom for the future.',
        'daily_quote_author': 'Plutarch',
        'daily_quote_date': '2026-10-11',
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DashboardHookCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Spending Wisdom'), findsOneWidget);
      expect(find.textContaining('To make no mistakes'), findsOneWidget);
      expect(find.text('— Plutarch'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    });
  });
}
