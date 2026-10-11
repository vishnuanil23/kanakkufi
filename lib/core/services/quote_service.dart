import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Quote {
  final String content;
  final String author;

  const Quote({
    required this.content,
    required this.author,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      content: json['content'] as String? ?? '',
      author: json['author'] as String? ?? 'Unknown',
    );
  }

  static const defaultWisdom = Quote(
    content:
        'To make no mistakes is not in the power of man; but from their errors and mistakes the wise and good learn wisdom for the future.',
    author: 'Plutarch',
  );
}

class QuoteService {
  static const _prefKeyContent = 'daily_quote_content';
  static const _prefKeyAuthor = 'daily_quote_author';
  static const _prefKeyDate = 'daily_quote_date';
  static const _apiUrl = 'https://api.quotable.io/random';

  /// Fetches the daily quote. Caches per day so it updates daily.
  /// If [forceRefresh] is true, fetches a fresh quote immediately.
  static Future<Quote> getDailyQuote({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cachedDate = prefs.getString(_prefKeyDate);

    // Return today's cached quote if available and not forcing refresh
    if (!forceRefresh && cachedDate == today) {
      final content = prefs.getString(_prefKeyContent);
      final author = prefs.getString(_prefKeyAuthor);
      if (content != null && content.isNotEmpty) {
        return Quote(
          content: content,
          author: author ?? 'Unknown',
        );
      }
    }

    // Otherwise, fetch new quote from API
    try {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(Uri.parse(_apiUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final rawJson = await response.transform(utf8.decoder).join();
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        final quote = Quote.fromJson(map);

        if (quote.content.isNotEmpty) {
          // Cache for the day
          await prefs.setString(_prefKeyContent, quote.content);
          await prefs.setString(_prefKeyAuthor, quote.author);
          await prefs.setString(_prefKeyDate, today);
          return quote;
        }
      }
    } catch (e) {
      debugPrint('QuoteService: Failed to fetch quote: $e');
    }

    // Fallback to previous cache or default wisdom
    final cachedContent = prefs.getString(_prefKeyContent);
    final cachedAuthor = prefs.getString(_prefKeyAuthor);
    if (cachedContent != null && cachedContent.isNotEmpty) {
      return Quote(
        content: cachedContent,
        author: cachedAuthor ?? 'Unknown',
      );
    }

    return Quote.defaultWisdom;
  }
}

class QuoteNotifier extends StateNotifier<AsyncValue<Quote>> {
  QuoteNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    try {
      final quote = await QuoteService.getDailyQuote(forceRefresh: forceRefresh);
      state = AsyncValue.data(quote);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final quoteProvider =
    StateNotifierProvider<QuoteNotifier, AsyncValue<Quote>>((ref) {
  return QuoteNotifier();
});
