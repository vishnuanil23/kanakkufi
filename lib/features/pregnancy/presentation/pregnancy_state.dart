import 'package:kanakkufi/features/pregnancy/domain/pregnancy_entity.dart';


class PregnancyState {
  final PregnancyEntity? profile;
  final bool isLoading;

  const PregnancyState({
    this.profile,
    this.isLoading = false,
  });

  PregnancyState copyWith({
    PregnancyEntity? profile,
    bool? isLoading,
  }) {
    return PregnancyState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isEnabled => profile != null;
}
