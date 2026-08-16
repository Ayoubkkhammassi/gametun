import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/cloudinary.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_scaffold.dart';
import '../../core/widgets/premium_badge.dart';
import '../auth/application/auth_controller.dart';
import '../multiplayer/multiplayer_game_screen.dart';
import '../profiles/user_profile_screen.dart';
import 'chat_repository.dart';
import 'chat_socket.dart';

const _emojiStrip = [
  '😀', '😂', '😍', '🔥', '👍', '❤️', '😎', '🎮',
  '😭', '🙏', '💪', '👀', '😅', '🥳', '😡', '✅',
];
const _reactionEmojis = ['❤️', '😂', '😮', '😢', '👍', '🔥'];

/// Thèmes de couleur des bulles (comme Insta), choisis par conversation.
const _chatThemes = <String, List<Color>>{
  'violet': [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  'magenta': [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  'cyan': [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
  'vert': [Color(0xFF10B981), Color(0xFF059669)],
  'or': [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  'rouge': [Color(0xFFEF4444), Color(0xFFB91C1C)],
};

/// Conversation façon Instagram : en-tête avatar+statut, bulles avec avatars,
/// double-tap ❤️, réactions, emojis, messages vocaux.
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String title;
  final bool isOnline;
  final bool isGroup;
  final List<String> memberNames;
  final String? otherUserId;
  final bool otherIsPremium;
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.isOnline = false,
    this.isGroup = false,
    this.memberNames = const [],
    this.otherUserId,
    this.otherIsPremium = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _socket = ChatSocket();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final List<ChatMessage> _messages = [];

  bool _loading = true;
  bool _sending = false;
  bool _showEmojis = false;
  bool _recording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  String? _playingId;
  String _themeKey = 'violet'; // thème de couleur de la conversation
  DateTime? _otherReadAt; // dernière lecture de l'autre (accusé "Vu")
  late bool _otherOnline = widget.isOnline; // statut en ligne temps réel

  String get _themePrefKey => 'chat_theme_${widget.conversationId}';

  LinearGradient get _mineGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _chatThemes[_themeKey] ?? _chatThemes['violet']!,
      );

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
    _loadTheme();
    _init();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themePrefKey);
    if (saved != null && _chatThemes.containsKey(saved)) {
      setState(() => _themeKey = saved);
    }
  }

  Future<void> _setTheme(String key) async {
    setState(() => _themeKey = key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, key);
  }

  Future<void> _init() async {
    try {
      final page = await ref
          .read(chatRepositoryProvider)
          .messages(widget.conversationId);
      setState(() {
        _messages
          ..clear()
          ..addAll(page.items);
        _otherReadAt = page.otherReadAt;
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _loading = false);
    }

    final token = await ref.read(tokenStorageProvider).accessToken;
    if (token != null) {
      _socket.connect(token);
      _socket.joinConversation(widget.conversationId);
      // J'ouvre la conversation → je la marque comme lue (accusé "Vu").
      _socket.sendRead(widget.conversationId);
      final myId = ref.read(authControllerProvider).user?.id;
      _socket.onMessage((data) {
        final msg = ChatMessage.fromJson(data);
        if (msg.conversationId != widget.conversationId) return;
        _addOrUpdate(msg);
        // Message reçu alors que la conv est ouverte → je le marque lu.
        if (msg.senderId != myId) _socket.sendRead(widget.conversationId);
      });
      _socket.onDeleted((id) {
        setState(() => _messages.removeWhere((m) => m.id == id));
      });
      // L'autre a lu → coche "Vu" sous mes messages.
      _socket.onRead((convId, userId, readAt) {
        if (convId != widget.conversationId || userId == myId) return;
        setState(() {
          if (_otherReadAt == null || readAt.isAfter(_otherReadAt!)) {
            _otherReadAt = readAt;
          }
        });
      });
      // Statut en ligne/hors ligne temps réel de l'autre joueur.
      _socket.onPresence((userId, isOnline) {
        if (userId == widget.otherUserId) {
          setState(() => _otherOnline = isOnline);
        }
      });
    }
  }

  Future<void> _deleteMessage(ChatMessage m) async {
    setState(() => _messages.removeWhere((x) => x.id == m.id));
    try {
      await ref.read(chatRepositoryProvider).deleteMessage(m.id);
    } catch (_) {
      _snack('Suppression impossible.');
    }
  }

  // ---- Texte -------------------------------------------------------------

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _showEmojis = false;
    });
    _controller.clear();
    try {
      final msg = await ref
          .read(chatRepositoryProvider)
          .send(widget.conversationId, text);
      _addOrUpdate(msg);
    } catch (_) {
      _snack('Message non envoyé (hors connexion).');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ---- Vocal -------------------------------------------------------------

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      _snack('Autorise le micro pour envoyer un vocal.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path);
    setState(() {
      _recording = true;
      _recordDuration = Duration.zero;
      _showEmojis = false;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    setState(() => _recording = false);
  }

  Future<void> _stopAndSend() async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    final seconds = _recordDuration.inSeconds;
    setState(() => _recording = false);
    if (path == null) return;
    try {
      setState(() => _sending = true);
      // Upload du vocal sur Cloudinary → on n'envoie que l'URL.
      final url = await Cloudinary().upload(File(path), resourceType: 'video');
      if (url == null) {
        _snack('Vocal non envoyé.');
        return;
      }
      final msg = await ref
          .read(chatRepositoryProvider)
          .sendVoice(widget.conversationId, url, seconds < 1 ? 1 : seconds);
      _addOrUpdate(msg);
    } catch (_) {
      _snack('Vocal non envoyé.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _playVoice(ChatMessage m) async {
    if (m.mediaData == null) return;
    if (_playingId == m.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    await _player.stop();
    if (m.mediaData!.startsWith('http')) {
      // Vocal hébergé sur Cloudinary.
      await _player.play(UrlSource(m.mediaData!));
    } else {
      // Ancien format base64 (compatibilité).
      final base64Part = m.mediaData!.contains(',')
          ? m.mediaData!.split(',').last
          : m.mediaData!;
      await _player.play(BytesSource(base64Decode(base64Part)));
    }
    setState(() => _playingId = m.id);
  }

  // ---- Réactions ---------------------------------------------------------

  Future<void> _react(ChatMessage m, String emoji) async {
    try {
      final updated =
          await ref.read(chatRepositoryProvider).react(m.id, emoji);
      _addOrUpdate(updated);
    } catch (_) {}
  }

  void _showReactionPicker(ChatMessage m) {
    final myId = ref.read(authControllerProvider).user?.id;
    final mine = m.senderId == myId;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _reactionEmojis
                  .map((e) => GestureDetector(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _react(m, e);
                        },
                        child: Text(e, style: const TextStyle(fontSize: 34)),
                      ))
                  .toList(),
            ),
            if (mine) ...[
              const Divider(height: 28, color: AppColors.stroke),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.danger),
                title: const Text('Supprimer le message',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteMessage(m);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---- Helpers -----------------------------------------------------------

  void _addOrUpdate(ChatMessage msg) {
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx >= 0) {
        _messages[idx] = msg;
      } else {
        _messages.add(msg);
      }
    });
    _scrollToBottom();
  }

  void _snack(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _socket.disconnect();
    _recorder.dispose();
    _player.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(authControllerProvider).user?.id;
    return Scaffold(
      appBar: _buildHeader(context),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final m = _messages[i];
                              final mine = m.senderId == myId;
                              // Regroupe : avatar affiché seulement au dernier
                              // message d'une série du même expéditeur.
                              final isLastOfGroup = i == _messages.length - 1 ||
                                  _messages[i + 1].senderId != m.senderId;
                              final read = mine &&
                                  _otherReadAt != null &&
                                  !m.createdAt.isAfter(_otherReadAt!);
                              return _Bubble(
                                message: m,
                                mine: mine,
                                read: read,
                                title: widget.title,
                                showAvatar: !mine && isLastOfGroup,
                                playing: _playingId == m.id,
                                mineGradient: _mineGradient,
                                onPlay: () => _playVoice(m),
                                onDoubleTap: () => _react(m, '❤️'),
                                onLongPress: () => _showReactionPicker(m),
                              );
                            },
                          ),
              ),
              if (_showEmojis) _EmojiStrip(onPick: _insertEmoji),
              _recording ? _buildRecordingBar() : _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    final subtitle = widget.isGroup
        ? '${widget.memberNames.length} membres'
        : (_otherOnline ? 'En ligne' : 'Hors ligne');
    return AppBar(
      titleSpacing: 0,
      title: InkWell(
        onTap: widget.isGroup
            ? _showMembers
            : (widget.otherUserId != null ? _openProfile : null),
        child: Row(
          children: [
            _Avatar(title: widget.title, radius: 18, online: _otherOnline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      if (widget.otherIsPremium) ...[
                        const SizedBox(width: 4),
                        const PremiumBadge(size: 14),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: _otherOnline && !widget.isGroup
                            ? AppColors.green
                            : AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Inviter à jouer à un mini-jeu à 2.
        IconButton(
          onPressed: _showGameChooser,
          icon: const Icon(Icons.videogame_asset),
          tooltip: 'Jouer à un mini-jeu',
        ),
        // Paramètres de la conversation (comme Insta).
        IconButton(
          onPressed: _showConversationSettings,
          icon: const Icon(Icons.more_vert),
          tooltip: 'Paramètres',
        ),
      ],
    );
  }

  /// Menu paramètres de la conversation (thème, membres) — style Insta.
  void _showConversationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(widget.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              const Text('Thème de la conversation',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _chatThemes.entries.map((e) {
                  final selected = e.key == _themeKey;
                  return GestureDetector(
                    onTap: () {
                      _setTheme(e.key);
                      setSheet(() {});
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: e.value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 22)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.group, color: AppColors.textPrimary),
                title: Text(
                    widget.isGroup
                        ? 'Membres (${widget.memberNames.length})'
                        : 'Voir le profil',
                    style: const TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  if (widget.isGroup) {
                    _showMembers();
                  } else {
                    _openProfile();
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.videogame_asset,
                    color: AppColors.textPrimary),
                title: const Text('Jouer à un mini-jeu',
                    style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showGameChooser();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ouvre le profil public de l'autre joueur (conversation directe).
  void _openProfile() {
    final id = widget.otherUserId;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: id)),
    );
  }

  /// Affiche la liste des membres du groupe (spec §11).
  void _showMembers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Membres (${widget.memberNames.length})',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ...widget.memberNames.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      _Avatar(title: n, radius: 18),
                      const SizedBox(width: 12),
                      Text(n,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Choix du mini-jeu à jouer à 2 dans cette conversation.
  void _showGameChooser() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jouer à un mini-jeu à 2',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Ton ami rejoint depuis la même conversation.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            _GameChoice(
              icon: Icons.grid_3x3,
              label: 'Tic-Tac-Toe 3D',
              onTap: () {
                Navigator.of(ctx).pop();
                _startGame('tic-tac-toe', 'Tic-Tac-Toe 3D');
              },
            ),
            const SizedBox(height: 10),
            _GameChoice(
              icon: Icons.back_hand,
              label: 'Pierre-Papier-Ciseaux',
              onTap: () {
                Navigator.of(ctx).pop();
                _startGame('rock-paper-scissors', 'Pierre-Papier-Ciseaux');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startGame(String game, String label) async {
    // Envoie une invitation dans le chat puis ouvre la partie.
    try {
      final msg = await ref
          .read(chatRepositoryProvider)
          .send(widget.conversationId, '🎮 Je t\'invite à jouer à $label !');
      _addOrUpdate(msg);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiplayerGameScreen(
        roomId: widget.conversationId,
        game: game,
        title: label,
      ),
    ));
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(title: widget.title, radius: 40, online: widget.isOnline),
          const SizedBox(height: 16),
          Text(widget.title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Envoie un message pour démarrer 👋',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  Widget _buildComposer() {
    final hasText = _controller.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: AppColors.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () =>
                        setState(() => _showEmojis = !_showEmojis),
                    icon: Icon(
                      _showEmojis
                          ? Icons.keyboard
                          : Icons.emoji_emotions_outlined,
                      color: _showEmojis
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textPrimary),
                      minLines: 1,
                      maxLines: 5,
                      onTap: () {
                        if (_showEmojis) setState(() => _showEmojis = false);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendMicButton(
            sending: _sending,
            hasText: hasText,
            onSend: _sendText,
            onMic: _startRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    final m = _recordDuration.inMinutes.remainder(60).toString();
    final s =
        _recordDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      color: AppColors.bg,
      child: Row(
        children: [
          const _PulsingDot(),
          const SizedBox(width: 12),
          Text('Enregistrement...  $m:$s',
              style: const TextStyle(color: AppColors.textPrimary)),
          const Spacer(),
          TextButton(
            onPressed: _cancelRecording,
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.danger)),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _stopAndSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar circulaire avec initiale + pastille "en ligne" (style Insta).
class _Avatar extends StatelessWidget {
  final String title;
  final double radius;
  final bool online;
  const _Avatar(
      {required this.title, required this.radius, this.online = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: const BoxDecoration(
            gradient: AppColors.magentaGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : '?',
            style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w800),
          ),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bg, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _SendMicButton extends StatelessWidget {
  final bool sending;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onMic;
  const _SendMicButton({
    required this.sending,
    required this.hasText,
    required this.onSend,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: sending ? null : (hasText ? onSend : onMic),
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: sending
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(hasText ? Icons.send : Icons.mic,
                color: Colors.white, size: 22),
      ),
    );
  }
}

class _GameChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GameChoice(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EmojiStrip extends StatelessWidget {
  final void Function(String) onPick;
  const _EmojiStrip({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: _emojiStrip
            .map((e) => InkWell(
                  onTap: () => onPick(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 26))),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final bool read;
  final String title;
  final bool showAvatar;
  final bool playing;
  final Gradient mineGradient;
  final VoidCallback onPlay;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;

  const _Bubble({
    required this.message,
    required this.mine,
    this.read = false,
    required this.title,
    required this.showAvatar,
    required this.playing,
    required this.mineGradient,
    required this.onPlay,
    required this.onDoubleTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = GestureDetector(
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: message.reactions.isNotEmpty ? 14 : 2),
            padding: message.isVoice
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.70),
            decoration: BoxDecoration(
              gradient: mine ? mineGradient : null,
              color: mine ? null : AppColors.surfaceAlt,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(mine ? 20 : 6),
                bottomRight: Radius.circular(mine ? 6 : 20),
              ),
            ),
            child: message.isVoice
                ? _VoiceContent(
                    playing: playing,
                    duration: message.mediaDuration ?? 0,
                    mine: mine,
                    onPlay: onPlay,
                  )
                : Text(message.body,
                    style: TextStyle(
                        color: mine ? Colors.white : AppColors.textPrimary,
                        fontSize: 15)),
          ),
          // Réactions collées en bas de la bulle (style Insta).
          if (message.reactions.isNotEmpty)
            Positioned(
              bottom: 0,
              right: mine ? 8 : null,
              left: mine ? null : 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.bg, width: 1.5),
                ),
                child: Text(
                  message.reactions.keys.join(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );

    final t = message.createdAt;
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    // Métadonnée sous la bulle : heure + double coche (lu) pour mes messages.
    final meta = Padding(
      padding: EdgeInsets.only(
          top: 2, left: mine ? 0 : 4, right: mine ? 4 : 0, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(time,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10)),
          if (mine) ...[
            const SizedBox(width: 4),
            // ✓ envoyé (gris) → ✓✓ vu (cyan) quand l'autre a lu.
            Icon(read ? Icons.done_all : Icons.check,
                size: 13,
                color: read ? AppColors.cyan : AppColors.textMuted),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine)
            SizedBox(
              width: 34,
              child: showAvatar
                  ? _Avatar(title: title, radius: 14)
                  : const SizedBox.shrink(),
            ),
          if (!mine) const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [bubble, meta],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceContent extends StatelessWidget {
  final bool playing;
  final int duration;
  final bool mine;
  final VoidCallback onPlay;
  const _VoiceContent({
    required this.playing,
    required this.duration,
    required this.mine,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final color = mine ? Colors.white : AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPlay,
          icon: Icon(playing ? Icons.stop_circle : Icons.play_circle_fill,
              color: color, size: 32),
        ),
        Icon(Icons.graphic_eq, color: color.withValues(alpha: 0.85)),
        const SizedBox(width: 8),
        Text('${duration}s',
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
            color: AppColors.danger, shape: BoxShape.circle),
      ),
    );
  }
}
