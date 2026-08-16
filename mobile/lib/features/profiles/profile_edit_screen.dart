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
/// photo de profil + jeux favoris + niveau + style de jeu + à propos.
class ProfileEditScreen extends ConsumerStatefulWidget {
  /// true = affiché juste après l'inscription (message de bienvenue).
  final bool isSetup;
  const ProfileEditScreen({super.key, this.isSetup = false});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _bio = TextEditingController();
  final Set<String> _games = {};
  String _level = 'INTERMEDIATE';
  String _playStyle = 'TEAM_PLAYER';
  String? _avatarDataUri; // URL Cloudinary de la nouvelle photo
  String? _currentAvatar; // photo déjà enregistrée
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

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

  @override
  void initState() {
    super.initState();
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
      final myGames = await api.get('/games/preferences');
      for (final g in (myGames as List)) {
        _games.add((g as Map<String, dynamic>)['slug'] as String);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickPhoto() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 700,
        imageQuality: 80,
      );
      if (x == null) return;
      setState(() => _uploadingPhoto = true);
      // Upload sur Cloudinary → on stocke seulement l'URL (pas l'image).
      final url = await Cloudinary().upload(File(x.path), resourceType: 'image');
      if (url != null) {
        setState(() => _avatarDataUri = url);
      } else {
        _snack('Upload de la photo échoué.');
      }
    } catch (_) {
      _snack('Impossible de charger la photo.');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (_games.isEmpty) {
      _snack('Choisis au moins un jeu favori.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).put('/profile', body: {
        'level': _level,
        'playStyle': _playStyle,
        'bio': _bio.text.trim(),
        'favoriteGameSlugs': _games.toList(),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(gamesCatalogProvider);
    final pseudo = ref.watch(authControllerProvider).user?.pseudo ?? '';

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isSetup ? 'COMPLÈTE TON PROFIL' : 'MODIFIER LE PROFIL')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    if (widget.isSetup)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Bienvenue ! Ajoute ta photo et réponds à quelques '
                          'questions pour un profil au top 🎮',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    // Photo de profil.
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
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
                      child: Text('Touche pour changer la photo',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ),
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
                          return GestureDetector(
                            onTap: () => setState(() =>
                                sel ? _games.remove(g.slug) : _games.add(g.slug)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                gradient:
                                    sel ? AppColors.primaryGradient : null,
                                color: sel ? null : AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: sel
                                        ? Colors.transparent
                                        : AppColors.stroke),
                              ),
                              child: Text(g.name,
                                  style: TextStyle(
                                      color: sel
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
                    _label('À propos de toi'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bio,
                      maxLines: 3,
                      maxLength: 300,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Passionné de jeux & toujours prêt…',
                        fillColor: AppColors.surfaceAlt,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GtButton(
                      label: widget.isSetup ? 'C\'EST PARTI 🎮' : 'ENREGISTRER',
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700));

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
              border:
                  Border.all(color: sel ? Colors.transparent : AppColors.stroke),
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
