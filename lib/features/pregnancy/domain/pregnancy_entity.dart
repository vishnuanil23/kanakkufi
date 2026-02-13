class PregnancyEntity {
  final String id;
  final String userId;
  final DateTime startDate;
  final bool isActive;

  const PregnancyEntity({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.isActive,
  });

  factory PregnancyEntity.fromJson(Map<String, dynamic> json) {
    return PregnancyEntity(
      id: json['id'],
      userId: json['user_id'],
      startDate: DateTime.parse(json['pregnancy_start_date']),
      isActive: json['is_active'],
    );
  }
}
