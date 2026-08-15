import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class DiscoverProfile {
  final String id;
  final String pseudo;
  final String? avatarUrl;
  final String region;
  final String ageGroup;
  final bool isOnline;
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
        level: (j['level'] ?? 'BEGINNER') as String,
        playStyle: (j['playStyle'] ?? 'CASUAL') as String,
        bio: j['bio'] as String?,
        games: ((j['games'] ?? []) as List).map((e) => e.toString()).toList(),
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

  Future<List<DiscoverProfile>> discover() async {
    final data = await _ref.read(apiClientProvider).get('/social/discover');
    return (data as List)
        .map((e) => DiscoverProfile.fromJson(e as Map<String, dynamic>))
        .toList();
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
