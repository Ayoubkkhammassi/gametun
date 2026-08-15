import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class GameItem {
  final String slug;
  final String name;
  final String? category;
  const GameItem({required this.slug, required this.name, this.category});

  factory GameItem.fromJson(Map<String, dynamic> j) => GameItem(
        slug: j['slug'] as String,
        name: j['name'] as String,
        category: j['category'] as String?,
      );
}

class GamesRepository {
  final Ref _ref;
  GamesRepository(this._ref);

  Future<List<GameItem>> list() async {
    final data = await _ref.read(apiClientProvider).get('/games');
    return (data as List)
        .map((e) => GameItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setPreferences(List<String> slugs) async {
    await _ref
        .read(apiClientProvider)
        .post('/games/preferences', body: {'gameSlugs': slugs});
  }
}

final gamesRepositoryProvider =
    Provider<GamesRepository>((ref) => GamesRepository(ref));

/// Catalogue des jeux (mis en cache pour la session).
final gamesCatalogProvider = FutureProvider<List<GameItem>>((ref) {
  return ref.read(gamesRepositoryProvider).list();
});
