import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';
import '../features/auth/data/auth_repository.dart';

/// Fournisseurs de bas niveau, partagés dans toute l'app.
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Index de l'onglet actif — partagé pour que l'accueil et le profil
/// puissent changer d'onglet (spec §3).
final selectedTabProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  return ApiClient(tokens);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});
