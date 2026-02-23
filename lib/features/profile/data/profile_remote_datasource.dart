import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_model.dart';

class ProfileRemoteDataSource {
  final SupabaseClient client;

  ProfileRemoteDataSource(this.client);

  Future<ProfileModel> getProfile(String userId) async {
    final data = await client.from('users').select().eq('id', userId).single();
    return ProfileModel.fromJson(data);
  }

  Future<void> updateProfile({
    required String userId,
    required String fullName,
  }) async {
    await client
        .from('users')
        .update({
          'full_name': fullName,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }
}
