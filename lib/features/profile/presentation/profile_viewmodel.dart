import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';
import '../domain/profile_entity.dart';
import 'profile_state.dart';

final profileProvider =
    StateNotifierProvider<ProfileViewModel, ProfileState>(
  (ref) => ProfileViewModel(ref),
);

class ProfileViewModel extends StateNotifier<ProfileState> {
  final Ref ref;

  ProfileViewModel(this.ref) : super(const ProfileState()) {
    fetchProfile();
  }

  SupabaseClient get _client =>
      ref.read(supabaseClientProvider);

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true);

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      state = state.copyWith(
        profile: ProfileEntity.fromJson(data),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProfile(String fullName) async {
    try {
      state = state.copyWith(isLoading: true);

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      await _client.from('users').update({
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      await fetchProfile();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
