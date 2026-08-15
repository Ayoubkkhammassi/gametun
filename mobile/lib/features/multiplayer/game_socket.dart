import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/config/env.dart';

/// Connexion WebSocket au namespace /games (mini-jeux à 2, temps réel).
class GameSocket {
  io.Socket? _socket;

  static String get _origin {
    final uri = Uri.parse(Env.apiBaseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  void connect(String accessToken) {
    disconnect();
    _socket = io.io(
      '$_origin/games',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': accessToken})
          .build(),
    );
    _socket!.connect();
  }

  void join(String roomId, String game) {
    _socket?.emit('game:join', {'roomId': roomId, 'game': game});
  }

  void move(String roomId, String game, int index) {
    _socket?.emit('game:move', {'roomId': roomId, 'game': game, 'index': index});
  }

  void reset(String roomId, String game) {
    _socket?.emit('game:reset', {'roomId': roomId, 'game': game});
  }

  void onState(void Function(Map<String, dynamic>) handler) {
    _socket?.on('game:state', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
