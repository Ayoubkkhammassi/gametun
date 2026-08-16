import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/cloudinary.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_avatar.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';
import '../auth/application/auth_controller.dart';
import '../games/games_repository.dart';

/// Écran « Modifier mon profil » (sert aussi de setup après inscription) :
/// carte joueur complète — photos, jeux, niveau, style, infos et prompts.
class ProfileEditScreen extends ConsumerStatefulWidget {
  /// true = affiché juste après l'inscription (message de bienvenue).
  final bool isSetup;
  const ProfileEditScreen({super.key, this.isSetup = false});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _bio = TextEditingController();
  final _rank = TextEditingController();
  final Set<String> _games = {};
  final Set<String> _genres = {};
  final Set<String> _languages = {};
  final List<String> _photos = []; // galerie (URLs Cloudinary)
  final Map<String, TextEditingController> _funFacts = {};

  String _level = 'INTERMEDIATE';
  String _playStyle = 'TEAM_PLAYER';
  String? _platform;
  String? _playerType;
  bool _hasMic = false;
  int _years = 0;
  String? _avatarDataUri; // URL Cloudinary de la nouvelle photo principale
  String? _currentAvatar; // photo déjà enregistrée
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  bool _uploadingGallery = false;

  static const _levels = {
    'BEGINNER': 'Débutant',
    'INTERMEDIATE': 'Intermédiaire',
    'ADVANCED': 'Avancé',
    'EXPERT': 'Expert',
  };
  static const _styles = {
    'CASUAL': 'Décontracté',
    'COMPETITIVE': 'Compétitif',
    'TEAM_PLAYER': 'Team Player',
    'STRATEGIST': 'Stratège',
    'AGGRESSIVE': 'Agressif',
    'SUPPORT': 'Support',
  };
  static const _platforms = ['PC', 'PlayStation', 'Xbox', 'Mobile', 'Switch'];
  static const _playerTypes = ['Casual', 'Compétitif', 'Streamer', 'Créateur'];
  static const _allGenres = [
    'FPS', 'MOBA', 'Battle Royale', 'RPG', 'Sport', 'Course',
    'Aventure', 'Combat', 'Stratégie', 'Sandbox', 'Horreur',
  ];
  static const _allLanguages = [
    'Arabe (Derja)', 'Français', 'Anglais', 'Espagnol', 'Italien', 'Allemand',
  ];
  // Prompts « Pose-moi une question » adaptés gaming.
  static const _funFactQuestions = [
    'Mon jeu du moment',
    'Mon main / perso préféré',
    'Mon pire rage quit',
    'Ma plus grande victoire',
    'Je cherche des coéquipiers pour',
  ];

  @override
  void initState() {
    super.initState();
    for (final q in _funFactQuestions) {
      _funFacts[q] = TextEditingController();
    }
    _load();
  }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    _currentAvatar = ref.read(authControllerProvider).user?.avatarUrl;
    try {
      final profile = await api.get('/profile');
      final p = profile as Map<String, dynamic>;
      _level = (p['level'] ?? _level) as String;
      _playStyle = (p['playStyle'] ?? _playStyle) as String;
      _bio.text = (p['bio'] ?? '') as String;
      _rank.text = (p['rank'] ?? '') as String;
      _platform = p['platform'] as String?;
      _playerType = p['playerType'] as String?;
      _hasMic = (p['hasMic'] ?? false) as bool;
      _years = (p['yearsExperience'] ?? 0) as int;
      _photos.addAll(
          ((p['photoUrls'] ?? []) as List).map((e) => e.toString()));
      _genres.addAll(
          ((p['favoriteGenres'] ?? []) as List).map((e) => e.toString()));
      _languages.addAll(
          ((p['spokenLanguages'] ?? []) as List).map((e) => e.toString()));
      for (final f in ((p['funFacts'] ?? []) as List)) {
        final m = f as Map<String, dynamic>;
        final q = m['question']?.toString();
        if (q != null && _funFacts.containsKey(q)) {
          _funFacts[q]!.text = m['answer']?.toString() ?? '';
        }
      }
      final myGames = await api.get('/games/preferences');
      for (final g in (myGames as List)) {
        _games.add((g as Map<String, dynamic>)['slug'] as String);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<String?> _uploadPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      imageQuality: 82,
    );
    if (x == null) return null;
    return Cloudinary().upload(File(x.path), resourceType: 'image');
  }

  Future<void> _pickAvatar() async {
    try {
      setState(() => _uploadingPhoto = true);
      final url = await _uploadPhoto();
      if (url != null) {
        setState(() => _avatarDataUri = url);
      }
    } catch (_) {
      _snack('Impossible de charger la photo.');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _addGalleryPhoto() async {
    if (_photos.length >= 6) {
      _snack('Maximum 6 photos.');
      return;
    }
    try {
      setState(() => _uploadingGallery = true);
      final url = await _uploadPhoto();
      if (url != null) setState(() => _photos.add(url));
    } catch (_) {
      _snack('Upload échoué.');
    } finally {
      if (mounted) setState(() => _uploadingGallery = false);
    }
  }

  Future<void> _save() async {
    if (_games.isEmpty) {
      _snack('Choisis au moins un jeu favori.');
      return;
    }
    setState(() => _saving = true);
    try {
      final funFacts = _funFacts.entries
          .where((e) => e.value.text.trim().isNotEmpty)
          .map((e) => {'question': e.key, 'answer': e.value.text.trim()})
          .toList();
      await ref.read(apiClientProvider).put('/profile', body: {
        'level': _level,
        'playStyle': _playStyle,
        'bio': _bio.text.trim(),
        'favoriteGameSlugs': _games.toList(),
        'photoUrls': _photos,
        'favoriteGenres': _genres.toList(),
        'spokenLanguages': _languages.toList(),
        'hasMic': _hasMic,
        'yearsExperience': _years,
        'funFacts': funFacts,
        if (_platform != null) 'platform': _platform,
        if (_playerType != null) 'playerType': _playerType,
        if (_rank.text.trim().isNotEmpty) 'rank': _rank.text.trim(),
        if (_avatarDataUri != null) 'avatarUrl': _avatarDataUri,
      });
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil enregistré ✅')),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String t) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
    }
  }

  @override
  void dispose() {
    _bio.dispose();
    _rank.dispose();
    for (final c in _funFacts.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(gamesCatalogProvider);
    final pseudo = ref.watch(authControllerProvider).user?.pseudo ?? '';

    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.isSetup ? 'COMPLÈTE TON PROFIL' : 'MODIFIER LE PROFIL')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    if (widget.isSetup)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Bienvenue ! Monte ta carte joueur : photos, jeux, '
                          'infos et prompts pour un profil au top 🎮',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    // Photo principale.
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            GtAvatar(
                              avatarUrl: _avatarDataUri ?? _currentAvatar,
                              pseudo: pseudo,
                              radius: 52,
                            ),
                            if (_uploadingPhoto)
                              const Positioned.fill(
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundColor: Colors.black54,
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                ),
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text('Photo principale',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ),
                    const SizedBox(height: 24),
                    // Galerie de photos.
                    _label('Mes photos (${_photos.length}/6)'),
                    const SizedBox(height: 10),
                    _buildGallery(),
                    const SizedBox(height: 24),
                    // Jeux favoris.
                    _label('Tes jeux favoris'),
                    const SizedBox(height: 10),
                    catalog.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Erreur jeux : $e',
                          style: const TextStyle(color: AppColors.danger)),
                      data: (games) => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: games.map((g) {
                          final sel = _games.contains(g.slug);
                          return _pill(g.name, sel, () {
                            setState(() => sel
                                ? _games.remove(g.slug)
                                : _games.add(g.slug));
                          });
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _label('Genres préférés'),
                    const SizedBox(height: 10),
                    _multiChips(_allGenres, _genres),
                    const SizedBox(height: 22),
                    _label('Ton niveau'),
                    const SizedBox(height: 10),
                    _chips(_levels, _level, (v) => setState(() => _level = v)),
                    const SizedBox(height: 22),
                    _label('Ton style de jeu'),
                    const SizedBox(height: 10),
                    _chips(_styles, _playStyle,
                        (v) => setState(() => _playStyle = v)),
                    const SizedBox(height: 22),
                    _label('Plateforme'),
                    const SizedBox(height: 10),
                    _singleChips(_platforms, _platform,
                        (v) => setState(() => _platform = v)),
                    const SizedBox(height: 22),
                    _label('Type de joueur'),
                    const SizedBox(height: 10),
                    _singleChips(_playerTypes, _playerType,
                        (v) => setState(() => _playerType = v)),
                    const SizedBox(height: 22),
                    _label('Rang / Rank'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _rank,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ex : Diamant 2, Immortal, Global…',
                        fillColor: AppColors.surfaceAlt,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _label('Langues parlées'),
                    const SizedBox(height: 10),
                    _multiChips(_allLanguages, _languages),
                    const SizedBox(height: 22),
                    // Micro + expérience.
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SwitchListTile(
                        value: _hasMic,
                        onChanged: (v) => setState(() => _hasMic = v),
                        activeThumbColor: AppColors.green,
                        secondary: const Icon(Icons.mic, color: AppColors.cyan),
                        title: const Text('J\'ai un micro',
                            style: TextStyle(color: AppColors.textPrimary)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildYears(),
                    const SizedBox(height: 22),
                    _label('À propos de toi'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bio,
                      maxLines: 4,
                      maxLength: 500,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Passionné de jeux & toujours prêt…',
                        fillColor: AppColors.surfaceAlt,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _label('Pose-moi une question sur…'),
                    const SizedBox(height: 4),
                    const Text('Réponds aux prompts pour te démarquer',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 10),
                    ..._funFactQuestions.map(_buildFunFact),
                    const SizedBox(height: 16),
                    GtButton(
                      label:
                          widget.isSetup ? 'C\'EST PARTI 🎮' : 'ENREGISTRER',
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGallery() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._photos.asMap().entries.map((e) {
          return Stack(
            children: [
              GtAvatar(
                avatarUrl: e.value,
                pseudo: '',
                radius: 44,
              ),
              Positioned(
                right: -6,
                top: -6,
                child: IconButton(
                  onPressed: () => setState(() => _photos.removeAt(e.key)),
                  icon: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.black87,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }),
        if (_photos.length < 6)
          GestureDetector(
            onTap: _uploadingGallery ? null : _addGalleryPhoto,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.stroke),
              ),
              child: _uploadingGallery
                  ? const Center(child: CircularProgressIndicator())
                  : const Icon(Icons.add_a_photo,
                      color: AppColors.textMuted, size: 26),
            ),
          ),
      ],
    );
  }

  Widget _buildYears() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Expérience : $_years an${_years > 1 ? 's' : ''}',
                style: const TextStyle(color: AppColors.textPrimary)),
          ),
          IconButton(
            onPressed: _years > 0 ? () => setState(() => _years--) : null,
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.textSecondary),
          ),
          IconButton(
            onPressed: _years < 40 ? () => setState(() => _years++) : null,
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildFunFact(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _funFacts[question],
            maxLength: 120,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Ta réponse…',
              fillColor: AppColors.surfaceAlt,
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700));

  Widget _pill(String text, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: sel ? AppColors.primaryGradient : null,
          color: sel ? null : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: sel ? Colors.transparent : AppColors.stroke),
        ),
        child: Text(text,
            style: TextStyle(
                color: sel ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }

  Widget _multiChips(List<String> options, Set<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final sel = selected.contains(o);
        return _pill(o, sel, () {
          setState(() => sel ? selected.remove(o) : selected.add(o));
        });
      }).toList(),
    );
  }

  Widget _singleChips(
      List<String> options, String? value, ValueChanged<String?> onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final sel = o == value;
        return _pill(o, sel, () => onTap(sel ? null : o));
      }).toList(),
    );
  }

  Widget _chips(
      Map<String, String> options, String value, ValueChanged<String> onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final sel = e.key == value;
        return GestureDetector(
          onTap: () => onTap(e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: sel ? AppColors.primaryGradient : null,
              color: sel ? null : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: sel ? Colors.transparent : AppColors.stroke),
            ),
            child: Text(e.value,
                style: TextStyle(
                    color: sel ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }
}
