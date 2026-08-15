/// Erreur applicative normalisée (issue de l'API ou du réseau).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  /// True si l'erreur vient d'une absence de connexion (mode hors ligne).
  bool get isNetwork => statusCode == null;

  @override
  String toString() => message;
}
