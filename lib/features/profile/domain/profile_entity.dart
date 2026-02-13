class ProfileEntity {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;

  const ProfileEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
  });

  factory ProfileEntity.fromJson(Map<String, dynamic> json) {
    return ProfileEntity(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    };
  }
}
