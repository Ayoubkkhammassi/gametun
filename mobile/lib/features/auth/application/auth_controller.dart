import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/env.dart';
import '../../../core/providers.dart';
import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

/// Phases de la session d'authentification.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final bool loading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.loading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthController(this._repo, this._ref) : super(const AuthState()) {
    _bootstrap();
  }

  /// Au démarrage : tente de restaurer la session via le token stocké.
  /// Durée minimale d'affichage du splash animé (~2,2s) pour l'effet marque.
  Future<void> _bootstrap() async {
    final minSplash =
        Future<void>.delayed(const Duration(milliseconds: 2200));
    final tokens = _ref.read(tokenStorageProvider);
    final token = await tokens.accessToken;
    if (token == null) {
      await minSplash;
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.me();
      await minSplash;
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await tokens.clear();
      await minSplash;
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await _repo.login(
        identifier: identifier,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        loading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String pseudo,
    required String password,
    required String birthDate,
    String? language,
    String? region,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await _repo.register(
        email: email,
        pseudo: pseudo,
        password: password,
        birthDate: birthDate,
        language: language,
        region: region,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        loading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    }
  }

  /// Recharge l'utilisateur depuis l'API (après édition du profil/avatar).
  Future<void> refreshUser() async {
    try {
      final user = await _repo.me();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  /// Connexion « Continuer avec Google ».
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: Env.googleServerClientId,
        scopes: const ['email', 'profile'],
      );
      await googleSignIn.signOut(); // force le choix du compte
      final account = await googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(loading: false); // annulé par l'utilisateur
        return false;
      }
      final gAuth = await account.authentication;
      final idToken = gAuth.idToken;
      if (idToken == null) {
        state = state.copyWith(
            loading: false, error: 'Échec Google (pas de token).');
        return false;
      }
      final user = await _repo.googleLogin(idToken);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        loading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          loading: false, error: 'Connexion Google impossible.');
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});
