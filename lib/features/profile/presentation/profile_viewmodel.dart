import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';

import 'profile_state.dart';

import '../domain/usecases/get_profile_usecase.dart';
import '../domain/usecases/update_profile_usecase.dart';
import '../data/profile_repository_impl.dart';
import '../data/profile_remote_datasource.dart';
import '../domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return ProfileRepositoryImpl(ProfileRemoteDataSource(client));
});

final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.read(profileRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.read(profileRepositoryProvider));
});

final profileProvider = StateNotifierProvider<ProfileViewModel, ProfileState>(
  (ref) => ProfileViewModel(ref),
);

class ProfileViewModel extends StateNotifier<ProfileState> {
  final Ref ref;

  ProfileViewModel(this.ref) : super(const ProfileState()) {
    fetchProfile();
  }

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true);

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final useCase = ref.read(getProfileUseCaseProvider);
      final result = await useCase(GetProfileParams(userId: userId));

      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
        },
        (profile) {
          state = state.copyWith(profile: profile, isLoading: false);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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

      final useCase = ref.read(updateProfileUseCaseProvider);
      final result = await useCase(
        UpdateProfileParams(userId: userId, fullName: fullName),
      );

      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
        },
        (_) async {
          await fetchProfile();
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
