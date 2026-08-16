import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/config/env.dart';

/// Connexion WebSocket (socket.io) au namespace /chat du backend.
/// Authentifiée par le JWT passé dans `auth.token`.
class ChatSocket {
  io.Socket? _socket;

  /// Origine du serveur (sans le préfixe /api/v1) pour le namespace socket.io.
  static String get _origin {
    final uri = Uri.parse(Env.apiBaseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  void connect(String accessToken) {
    disconnect();
    _socket = io.io(
      '$_origin/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': accessToken})
          .build(),
    );
    _socket!.connect();
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join', {'conversationId': conversationId});
  }

  void sendTyping(String conversationId) {
    _socket?.emit('typing', {'conversationId': conversationId});
  }

  /// Écoute les nouveaux messages temps réel.
  void onMessage(void Function(Map<String, dynamic>) handler) {
    _socket?.on('message', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  /// Écoute les suppressions de messages temps réel.
  void onDeleted(void Function(String id) handler) {
    _socket?.on('message:deleted', (data) {
      if (data is Map && data['id'] != null) handler(data['id'].toString());
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
