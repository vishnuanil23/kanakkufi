import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/data/profile_model.dart';
import '../../profile/domain/profile_entity.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSource(this._client);

  Future<void> signInWithOtp(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );
  }

  Future<ProfileEntity?> getUserProfile(String userId) async {
    final data =
        await _client.from('users').select().eq('id', userId).maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<ProfileEntity> createUserProfile({
    required String userId,
    required String email,
  }) async {
    final inserted =
        await _client
            .from('users')
            .insert({'id': userId, 'email': email})
            .select()
            .single();

    return ProfileModel.fromJson(inserted);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}
