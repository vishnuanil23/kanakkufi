import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  static String get exchangeKey =>
      dotenv.get('EXCHANGE_API_KEY', fallback: '');

  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }
}
