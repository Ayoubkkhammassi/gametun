import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/user_model.dart';

/// Accès aux endpoints d'authentification + persistance des tokens.
class AuthRepository {
  final ApiClient _api;
  final TokenStorage _tokens;

  AuthRepository(this._api, this._tokens);

  Future<UserModel> register({
    required String email,
    required String pseudo,
    required String password,
    required String birthDate, // YYYY-MM-DD
    String? language,
    String? region,
  }) async {
    final data = await _api.post('/auth/register', body: {
      'email': email,
      'pseudo': pseudo,
      'password': password,
      'birthDate': birthDate,
      'language': ?language,
      'region': ?region,
    });
    return _handleAuthPayload(data);
  }

  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final data = await _api.post('/auth/login', body: {
      'identifier': identifier,
      'password': password,
    });
    return _handleAuthPayload(data);
  }

  Future<UserModel> me() async {
    final data = await _api.get('/users/me');
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // On efface la session localement même si l'appel échoue.
    }
    await _tokens.clear();
  }

  /// Sauvegarde les tokens et renvoie l'utilisateur d'une réponse d'auth.
  Future<UserModel> _handleAuthPayload(dynamic data) async {
    final map = data as Map<String, dynamic>;
    final tokens = map['tokens'] as Map<String, dynamic>;
    await _tokens.saveTokens(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
    return UserModel.fromJson(map['user'] as Map<String, dynamic>);
  }
}
