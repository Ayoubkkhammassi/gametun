import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class Conversation {
  final String id;
  final String type;
  final String title;
  final bool isOnline;
  final String? lastMessage;
  final List<String> memberNames;
  final String? otherUserId; // id de l'autre joueur (conversation directe)
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.type,
    required this.title,
    required this.isOnline,
    this.lastMessage,
    this.memberNames = const [],
    this.otherUserId,
    required this.updatedAt,
  });

  bool get isGroup => type != 'DIRECT';

  factory Conversation.fromJson(Map<String, dynamic> j) {
    final participants = (j['participants'] ?? []) as List;
    final names = participants
        .map((p) => (p as Map<String, dynamic>)['pseudo']?.toString() ?? '?')
        .toList();
    final first = participants.isNotEmpty
        ? participants.first as Map<String, dynamic>
        : null;
    final last = j['lastMessage'] as Map<String, dynamic>?;
    final type = (j['type'] ?? 'DIRECT') as String;
    return Conversation(
      id: j['conversationId'] as String,
      type: type,
      title: type == 'DIRECT'
          ? (first?['pseudo'] ?? 'Discussion') as String
          : (names.isNotEmpty ? names.join(', ') : 'Groupe'),
      isOnline: (first?['isOnline'] ?? false) as bool,
      lastMessage: last?['body'] as String?,
      memberNames: names,
      otherUserId: first?['id'] as String?,
      updatedAt: DateTime.tryParse(j['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String type; // TEXT | VOICE
  final String body;
  final String? mediaData; // data URI base64 audio
  final int? mediaDuration;
  final Map<String, List<String>> reactions;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.body,
    this.mediaData,
    this.mediaDuration,
    this.reactions = const {},
    required this.createdAt,
  });

  bool get isVoice => type == 'VOICE';

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    final rawReactions = j['reactions'];
    final reactions = <String, List<String>>{};
    if (rawReactions is Map) {
      rawReactions.forEach((k, v) {
        if (v is List) reactions[k.toString()] = v.map((e) => e.toString()).toList();
      });
    }
    return ChatMessage(
      id: j['id'] as String,
      conversationId: j['conversationId'] as String,
      senderId: j['senderId'] as String,
      type: (j['type'] ?? 'TEXT') as String,
      body: (j['body'] ?? '') as String,
      mediaData: j['mediaData'] as String?,
      mediaDuration: j['mediaDuration'] as int?,
      reactions: reactions,
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ChatRepository {
  final Ref _ref;
  ChatRepository(this._ref);

  Future<List<Conversation>> listConversations() async {
    final data = await _ref.read(apiClientProvider).get('/conversations');
    return (data as List)
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> messages(String conversationId) async {
    final data = await _ref
        .read(apiClientProvider)
        .get('/conversations/$conversationId/messages');
    final items = (data as Map<String, dynamic>)['items'] as List;
    return items
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> send(String conversationId, String body) async {
    final data = await _ref
        .read(apiClientProvider)
        .post('/conversations/$conversationId/messages', body: {'body': body});
    return ChatMessage.fromJson(data as Map<String, dynamic>);
  }

  /// Envoie un message vocal (audio encodé en data URI base64).
  Future<ChatMessage> sendVoice(
    String conversationId,
    String mediaData,
    int durationSeconds,
  ) async {
    final data = await _ref
        .read(apiClientProvider)
        .post('/conversations/$conversationId/messages', body: {
      'type': 'VOICE',
      'mediaData': mediaData,
      'mediaDuration': durationSeconds,
    });
    return ChatMessage.fromJson(data as Map<String, dynamic>);
  }

  /// Supprime un de mes messages.
  Future<void> deleteMessage(String messageId) async {
    await _ref.read(apiClientProvider).delete('/messages/$messageId');
  }

  /// Ajoute/retire une réaction emoji sur un message.
  Future<ChatMessage> react(String messageId, String emoji) async {
    final data = await _ref
        .read(apiClientProvider)
        .post('/messages/$messageId/react', body: {'emoji': emoji});
    return ChatMessage.fromJson(data as Map<String, dynamic>);
  }
}

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ChatRepository(ref));
