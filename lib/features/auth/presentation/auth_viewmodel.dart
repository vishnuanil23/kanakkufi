import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';
import '../data/auth_remote_datasource.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  final remoteDataSource = AuthRemoteDataSource(client);
  return AuthRepositoryImpl(remoteDataSource);
});

final authProvider = StateNotifierProvider<AuthViewModel, AsyncValue<void>>(
  (ref) => AuthViewModel(ref),
);

class AuthViewModel extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  AuthViewModel(this.ref) : super(const AsyncData(null));

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  // STEP 1: Send OTP
  Future<void> sendOtp(String email) async {
    try {
      state = const AsyncLoading();

      await _repository.signInWithOtp(email);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // STEP 2: Verify OTP
  Future<void> verifyOtp({required String email, required String token}) async {
    try {
      state = const AsyncLoading();

      await _repository.verifyOtp(email: email, token: token);

      // Profile handling is now done in repository
      // await _handleUserProfile();

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  User? get currentUser => _repository.currentUser;
  Future<void> logout() async {
    await _repository.signOut();
  }
}
