import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kanakkufi/core/config/env.dart';

class CurrencyService {
  static Future<double> convertAedToInr({
    required double amount,
    required DateTime date,
  }) async {
    final apiKey = Env.exchangeKey;

    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse(
      "https://api.exchangerate.host/convert"
      "?access_key=$apiKey"
      "&from=AED"
      "&to=INR"
      "&amount=$amount"
      "&date=$formattedDate"
      "&format=1",
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        return data['result'];
      } else {
        throw Exception("API error: ${data['error']}");
      }
    } else {
      throw Exception("Failed to fetch conversion");
    }
  }
}
