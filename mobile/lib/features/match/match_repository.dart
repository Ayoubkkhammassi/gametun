import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class RankedPlayer {
  final String id;
  final String pseudo;
  final String? avatarUrl;
  final String level;
  final int compatibility;
  final List<String> games;

  const RankedPlayer({
    required this.id,
    required this.pseudo,
    this.avatarUrl,
    required this.level,
    required this.compatibility,
    required this.games,
  });

  factory RankedPlayer.fromJson(Map<String, dynamic> j) => RankedPlayer(
        id: j['id'] as String,
        pseudo: j['pseudo'] as String,
        avatarUrl: j['avatarUrl'] as String?,
        level: (j['level'] ?? 'BEGINNER') as String,
        compatibility: (j['compatibility'] ?? 0) as int,
        games: ((j['games'] ?? []) as List).map((e) => e.toString()).toList(),
      );
}

class MatchSearchResult {
  final List<RankedPlayer> results;
  final List<RankedPlayer> proposedTeam;
  final int averageCompatibility;
  final int totalFound;

  const MatchSearchResult({
    required this.results,
    required this.proposedTeam,
    required this.averageCompatibility,
    required this.totalFound,
  });

  factory MatchSearchResult.fromJson(Map<String, dynamic> j) => MatchSearchResult(
        results: ((j['results'] ?? []) as List)
            .map((e) => RankedPlayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        proposedTeam: ((j['proposedTeam'] ?? []) as List)
            .map((e) => RankedPlayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        averageCompatibility: (j['averageCompatibility'] ?? 0) as int,
        totalFound: (j['totalFound'] ?? 0) as int,
      );
}

class MatchRepository {
  final Ref _ref;
  MatchRepository(this._ref);

  Future<MatchSearchResult> search({
    required List<String> gameSlugs,
    String? mode,
    String? level,
    String? language,
    String? availabilityFrom,
    String? availabilityTo,
    int? players,
  }) async {
    final data = await _ref.read(apiClientProvider).post('/match/search', body: {
      'gameSlugs': gameSlugs,
      'mode': ?mode,
      'level': ?level,
      'language': ?language,
      'availabilityFrom': ?availabilityFrom,
      'availabilityTo': ?availabilityTo,
      'players': ?players,
    });
    return MatchSearchResult.fromJson(data as Map<String, dynamic>);
  }

  Future<void> accept(String targetId) =>
      _ref.read(apiClientProvider).post('/match/accept', body: {'targetId': targetId});

  Future<void> pass(String targetId) =>
      _ref.read(apiClientProvider).post('/match/pass', body: {'targetId': targetId});
}

final matchRepositoryProvider =
    Provider<MatchRepository>((ref) => MatchRepository(ref));
