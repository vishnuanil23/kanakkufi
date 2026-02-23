import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/domain/profile_entity.dart';

abstract class AuthRepository {
  Future<void> signInWithOtp(String email);
  Future<void> verifyOtp({required String email, required String token});
  Future<ProfileEntity?> getProfile(String userId);
  Future<void> signOut();
  User? get currentUser;
}
