/// Configuration d'environnement du client.
///
/// L'URL de l'API se règle au build sans toucher au code :
///   flutter run --dart-define=API_BASE_URL=https://gametun-api.onrender.com/api/v1
///
/// Valeur par défaut = émulateur Android (10.0.2.2 = localhost de la machine hôte).
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Numéro de version de CETTE build (à incrémenter à chaque nouvel APK).
  /// Le serveur renvoie la dernière version ; si elle est > à celle-ci,
  /// l'app propose la mise à jour.
  static const int appVersionCode = 4;

  /// ID client Web Google (public) — pour obtenir un idToken vérifiable serveur.
  static const String googleServerClientId =
      '560455067095-1m461lg873hn29ccfg24m8ga3a74g3aa.apps.googleusercontent.com';

  /// Cloudinary — stockage des médias (photos, vocaux) hors base de données.
  static const String cloudinaryCloudName = 'emepl8sr';
  static const String cloudinaryUploadPreset = 'nf86n2bx';
}
