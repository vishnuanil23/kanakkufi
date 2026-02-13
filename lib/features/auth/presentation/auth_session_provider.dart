import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';

/// Provider that exposes the current auth state (Session) as a Stream.
final sessionProvider = StreamProvider<Session?>((ref) {
  final supabase = ref.watch(supabaseClientProvider);

  return supabase.auth.onAuthStateChange.map((data) => data.session);
});

/// Provider that checks if the user is currently authenticated.
final authStateProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider).value;
  return session != null;
});

/// Provider for the current Supabase User.
final currentUserProvider = Provider<User?>((ref) {
  final session = ref.watch(sessionProvider).value;
  return session?.user;
});
