import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class DiscoverProfile {
  final String id;
  final String pseudo;
  final String? avatarUrl;
  final String region;
  final String ageGroup;
  final bool isOnline;
  final bool isPremium;
  final String level;
  final String playStyle;
  final String? bio;
  final List<String> games;

  const DiscoverProfile({
    required this.id,
    required this.pseudo,
    this.avatarUrl,
    required this.region,
    required this.ageGroup,
    required this.isOnline,
    this.isPremium = false,
    required this.level,
    required this.playStyle,
    this.bio,
    required this.games,
  });

  factory DiscoverProfile.fromJson(Map<String, dynamic> j) => DiscoverProfile(
        id: j['id'] as String,
        pseudo: j['pseudo'] as String,
        avatarUrl: j['avatarUrl'] as String?,
        region: (j['region'] ?? '') as String,
        ageGroup: (j['ageGroup'] ?? '') as String,
        isOnline: (j['isOnline'] ?? false) as bool,
        isPremium: (j['isPremium'] ?? false) as bool,
        level: (j['level'] ?? 'BEGINNER') as String,
        playStyle: (j['playStyle'] ?? 'CASUAL') as String,
        bio: j['bio'] as String?,
        games: ((j['games'] ?? []) as List).map((e) => e.toString()).toList(),
      );
}

/// Filtres de recherche avancés (réservés Premium).
class DiscoverFilters {
  final String? region;
  final String? level;
  final String? gameSlug;
  final bool onlineOnly;
  const DiscoverFilters({
    this.region,
    this.level,
    this.gameSlug,
    this.onlineOnly = false,
  });

  bool get isEmpty =>
      region == null && level == null && gameSlug == null && !onlineOnly;
}

/// Une personne qui m'a liké (identités visibles seulement en Premium).
class LikedMeResult {
  final int count;
  final bool isPremium;
  final List<DiscoverProfileLite> users;
  const LikedMeResult({
    required this.count,
    required this.isPremium,
    required this.users,
  });
}

class DiscoverProfileLite {
  final String id;
  final String pseudo;
  final String? avatarUrl;
  final String region;
  final bool isOnline;
  final bool isPremium;
  const DiscoverProfileLite({
    required this.id,
    required this.pseudo,
    this.avatarUrl,
    required this.region,
    required this.isOnline,
    required this.isPremium,
  });
  factory DiscoverProfileLite.fromJson(Map<String, dynamic> j) =>
      DiscoverProfileLite(
        id: j['id'] as String,
        pseudo: (j['pseudo'] ?? '?') as String,
        avatarUrl: j['avatarUrl'] as String?,
        region: (j['region'] ?? '') as String,
        isOnline: (j['isOnline'] ?? false) as bool,
        isPremium: (j['isPremium'] ?? false) as bool,
      );
}

class SwipeResult {
  final bool matched;
  final String? conversationId;
  const SwipeResult({required this.matched, this.conversationId});
}

class SocialRepository {
  final Ref _ref;
  SocialRepository(this._ref);

  Future<List<DiscoverProfile>> discover({DiscoverFilters? filters}) async {
    final q = <String, dynamic>{};
    if (filters != null) {
      if (filters.region != null) q['region'] = filters.region;
      if (filters.level != null) q['level'] = filters.level;
      if (filters.gameSlug != null) q['game'] = filters.gameSlug;
      if (filters.onlineOnly) q['onlineOnly'] = 'true';
    }
    final data = await _ref
        .read(apiClientProvider)
        .get('/social/discover', query: q.isEmpty ? null : q);
    return (data as List)
        .map((e) => DiscoverProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Qui m'a liké (identités seulement si Premium).
  Future<LikedMeResult> likedMe() async {
    final data = await _ref.read(apiClientProvider).get('/social/liked-me');
    final m = data as Map<String, dynamic>;
    return LikedMeResult(
      count: (m['count'] ?? 0) as int,
      isPremium: (m['isPremium'] ?? false) as bool,
      users: ((m['users'] ?? []) as List)
          .map((e) => DiscoverProfileLite.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<SwipeResult> swipe(String targetId, String type) async {
    final data = await _ref.read(apiClientProvider).post('/social/swipe',
        body: {'targetId': targetId, 'type': type});
    final m = data as Map<String, dynamic>;
    return SwipeResult(
      matched: (m['matched'] ?? false) as bool,
      conversationId: m['conversationId'] as String?,
    );
  }
}

final socialRepositoryProvider =
    Provider<SocialRepository>((ref) => SocialRepository(ref));
