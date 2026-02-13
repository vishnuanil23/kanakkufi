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
        .eq('is_active', true)
        .maybeSingle();

    if (data != null) {
      state = state.copyWith(
        profile: PregnancyEntity.fromJson(data),
      );
    }
  }

Future<void> enablePregnancy({
  required int week,
  required int day,
}) async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) return;

  final startDate =
      PregnancyCalculator.calculateStartDate(
    week: week,
    day: day,
  );

  final inserted = await _client
      .from('user_pregnancy_profiles')
      .insert({
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

  Future<void> disablePregnancy() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_pregnancy_profiles')
        .update({'is_active': false})
        .eq('user_id', userId);

    state = const PregnancyState();
  }
}
