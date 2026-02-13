import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanakkufi/features/pregnancy/domain/pregnancy_calculator.dart';
import 'package:kanakkufi/features/pregnancy/domain/pregnancy_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_client_provider.dart';
import 'pregnancy_state.dart';

final pregnancyProvider =
    StateNotifierProvider<PregnancyViewModel, PregnancyState>(
  (ref) => PregnancyViewModel(ref),
);

class PregnancyViewModel extends StateNotifier<PregnancyState> {
  final Ref ref;

  PregnancyViewModel(this.ref) : super(const PregnancyState()) {
    fetchActiveProfile();
  }

  SupabaseClient get _client =>
      ref.read(supabaseClientProvider);

Future<void> fetchActiveProfile() async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) return;

  final data = await _client
      .from('user_pregnancy_profiles')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

  if (data != null) {
    state = state.copyWith(
      profile: PregnancyEntity.fromJson(data),
    );
  }
}

Future<void> togglePregnancy({
  int? week,
  int? day,
}) async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) return;

  final existingProfile = state.profile;

  if (existingProfile != null) {
    // Just toggle is_active
    final newStatus = !existingProfile.isActive;

    final updated = await _client
        .from('user_pregnancy_profiles')
        .update({'is_active': newStatus})
        .eq('user_id', userId)
        .select()
        .single();

    state = state.copyWith(
      profile: PregnancyEntity.fromJson(updated),
    );
  } else {
    // First time enable — require week/day
    if (week == null || day == null) return;

    final startDate =
        PregnancyCalculator.calculateStartDate(
      week: week,
      day: day,
    );

    final inserted = await _client
        .from('user_pregnancy_profiles')
        .upsert({
          'user_id': userId,
          'pregnancy_start_date':
              startDate.toIso8601String(),
          'is_active': true,
        })
        .select()
        .single();

    state = state.copyWith(
      profile: PregnancyEntity.fromJson(inserted),
    );
  }
}
}
