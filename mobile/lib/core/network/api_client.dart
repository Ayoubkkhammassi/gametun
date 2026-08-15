import 'package:dio/dio.dart';
import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Client HTTP central (Dio) :
///  - injecte le Bearer token,
///  - rafraîchit automatiquement le token expiré (401) via /auth/refresh,
///  - normalise les réponses `{ success, data }` et les erreurs.
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokens;

  // Callback déclenché quand la session est définitivement invalide
  // (refresh échoué) — l'app doit alors rediriger vers la connexion.
  void Function()? onSessionExpired;

  ApiClient(this._tokens, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: Env.connectTimeout,
              receiveTimeout: Env.receiveTimeout,
              contentType: 'application/json',
            )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Les routes d'auth publiques n'ont pas besoin de token.
    final isAuthRoute = options.path.startsWith('/auth/login') ||
        options.path.startsWith('/auth/register') ||
        options.path.startsWith('/auth/refresh');
    if (!isAuthRoute) {
      final token = await _tokens.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;

    // Tentative de refresh unique sur 401 (hors route de refresh elle-même).
    if (response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh') &&
        err.requestOptions.extra['retried'] != true) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        try {
          final opts = err.requestOptions;
          opts.extra['retried'] = true;
          final token = await _tokens.accessToken;
          opts.headers['Authorization'] = 'Bearer $token';
          final retry = await _dio.fetch(opts);
          return handler.resolve(retry);
        } catch (_) {
          // tombe dans le rejet ci-dessous
        }
      } else {
        onSessionExpired?.call();
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      await _tokens.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    }
  }

  // ---- Verbes HTTP (renvoient directement le `data` déballé) -------------

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _unwrap(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _unwrap(() => _dio.post(path, data: body));

  Future<dynamic> put(String path, {Object? body}) =>
      _unwrap(() => _dio.put(path, data: body));

  Future<dynamic> delete(String path, {Object? body}) =>
      _unwrap(() => _dio.delete(path, data: body));

  Future<dynamic> _unwrap(Future<Response> Function() call) async {
    try {
      final res = await call();
      final body = res.data;
      if (body is Map && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException('Hors connexion — vérifie ta connexion internet.');
    }
    final data = e.response?.data;
    String message = 'Une erreur est survenue.';
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      message = m is List ? m.join('\n') : m.toString();
    }
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}
