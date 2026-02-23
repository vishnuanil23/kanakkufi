import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/domain/profile_entity.dart';
import '../domain/auth_repository.dart';
import 'auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> signInWithOtp(String email) async {
    await _remoteDataSource.signInWithOtp(email);
  }

  @override
  Future<void> verifyOtp({required String email, required String token}) async {
    final response = await _remoteDataSource.verifyOtp(
      email: email,
      token: token,
    );

    // Handle user profile creation if needed
    final user = response.user;
    if (user != null) {
      final profile = await _remoteDataSource.getUserProfile(user.id);
      if (profile == null) {
        await _remoteDataSource.createUserProfile(
          userId: user.id,
          email: user.email ?? email,
        );
      }
    }
  }

  @override
  Future<ProfileEntity?> getProfile(String userId) async {
    return await _remoteDataSource.getUserProfile(userId);
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
  }

  @override
  User? get currentUser => _remoteDataSource.currentUser;
}
