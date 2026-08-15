import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class Squad {
  final String id;
  final String name;
  final String gameName;
  final String mode;
  final int maxPlayers;
  final int memberCount;
  final String requiredLevel;
  final String language;
  final String? description;

  const Squad({
    required this.id,
    required this.name,
    required this.gameName,
    required this.mode,
    required this.maxPlayers,
    required this.memberCount,
    required this.requiredLevel,
    required this.language,
    this.description,
  });

  factory Squad.fromJson(Map<String, dynamic> j) {
    final game = j['game'] as Map<String, dynamic>?;
    return Squad(
      id: j['id'] as String,
      name: j['name'] as String,
      gameName: (game?['name'] ?? '') as String,
      mode: (j['mode'] ?? '') as String,
      maxPlayers: (j['maxPlayers'] ?? 0) as int,
      memberCount: (j['memberCount'] ?? 0) as int,
      requiredLevel: (j['requiredLevel'] ?? 'BEGINNER') as String,
      language: (j['language'] ?? 'FR') as String,
      description: j['description'] as String?,
    );
  }
}

class SquadRepository {
  final Ref _ref;
  SquadRepository(this._ref);

  Future<List<Squad>> list({required bool discover}) async {
    final data = await _ref
        .read(apiClientProvider)
        .get('/squads', query: {'scope': discover ? 'discover' : 'mine'});
    return (data as List)
        .map((e) => Squad.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String name,
    required String gameSlug,
    required String mode,
    required int maxPlayers,
    required String requiredLevel,
    required String language,
    String? description,
  }) async {
    await _ref.read(apiClientProvider).post('/squads', body: {
      'name': name,
      'gameSlug': gameSlug,
      'mode': mode,
      'maxPlayers': maxPlayers,
      'requiredLevel': requiredLevel,
      'language': language,
      'description': ?description,
    });
  }

  Future<void> join(String squadId) =>
      _ref.read(apiClientProvider).post('/squads/$squadId/join');

  Future<void> leave(String squadId) =>
      _ref.read(apiClientProvider).post('/squads/$squadId/leave');

  Future<Map<String, dynamic>> detail(String squadId) async {
    final data = await _ref.read(apiClientProvider).get('/squads/$squadId');
    return data as Map<String, dynamic>;
  }

  /// Smart Squad : joueurs suggérés pour compléter l'équipe (capitaine).
  Future<Map<String, dynamic>> smartComplete(String squadId) async {
    final data =
        await _ref.read(apiClientProvider).get('/squads/$squadId/smart-complete');
    return data as Map<String, dynamic>;
  }
}

final squadRepositoryProvider =
    Provider<SquadRepository>((ref) => SquadRepository(ref));
