import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';

final authProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<void>>(
  (ref) => AuthViewModel(ref),
);

class AuthViewModel extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  AuthViewModel(this.ref) : super(const AsyncData(null));

  SupabaseClient get _client =>
      ref.read(supabaseClientProvider);

  // STEP 1: Send OTP
  Future<void> sendOtp(String email) async {
    try {
      state = const AsyncLoading();

      await _client.auth.signInWithOtp(
        email: email,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // STEP 2: Verify OTP
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      state = const AsyncLoading();

      await _client.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: token,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  User? get currentUser => _client.auth.currentUser;
}
