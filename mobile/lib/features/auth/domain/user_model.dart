/// Utilisateur courant (vue "self" renvoyée par l'API — sans données sensibles).
class UserModel {
  final String id;
  final String pseudo;
  final String? email;
  final String? avatarUrl;
  final String language;
  final String region;
  final String role;
  final bool isPremium;
  final String? ageGroup;

  const UserModel({
    required this.id,
    required this.pseudo,
    this.email,
    this.avatarUrl,
    required this.language,
    required this.region,
    required this.role,
    required this.isPremium,
    this.ageGroup,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      pseudo: json['pseudo'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      language: (json['language'] ?? 'FR') as String,
      region: (json['region'] ?? 'Tunisie') as String,
      role: (json['role'] ?? 'USER') as String,
      isPremium: (json['isPremium'] ?? false) as bool,
      ageGroup: json['ageGroup'] as String?,
    );
  }
}
