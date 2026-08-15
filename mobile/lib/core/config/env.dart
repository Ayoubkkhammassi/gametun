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
}
