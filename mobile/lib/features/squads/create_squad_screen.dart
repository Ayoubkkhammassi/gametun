import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';
import '../../core/widgets/gt_text_field.dart';
import '../games/games_repository.dart';
import 'squad_repository.dart';

class CreateSquadScreen extends ConsumerStatefulWidget {
  const CreateSquadScreen({super.key});

  @override
  ConsumerState<CreateSquadScreen> createState() => _CreateSquadScreenState();
}

class _CreateSquadScreenState extends ConsumerState<CreateSquadScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String? _gameSlug;
  String _mode = 'RANKED';
  String _level = 'INTERMEDIATE';
  String _language = 'FR';
  int _maxPlayers = 5;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 3) {
      setState(() => _error = 'Le nom doit faire au moins 3 caractères.');
      return;
    }
    if (_gameSlug == null) {
      setState(() => _error = 'Choisis un jeu.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(squadRepositoryProvider).create(
            name: _name.text.trim(),
            gameSlug: _gameSlug!,
            mode: _mode,
            maxPlayers: _maxPlayers,
            requiredLevel: _level,
            language: _language,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(gamesCatalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('CRÉER UNE SQUAD')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              GtTextField(
                controller: _name,
                label: 'Nom de la squad',
                hint: 'ex: Valorant Tunisia',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              catalog.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erreur jeux : $e',
                    style: const TextStyle(color: AppColors.danger)),
                data: (games) => _Field(
                  label: 'Jeu',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _gameSlug,
                      hint: const Text('Choisir un jeu',
                          style: TextStyle(color: AppColors.textMuted)),
                      dropdownColor: AppColors.surfaceAlt,
                      style: const TextStyle(color: AppColors.textPrimary),
                      items: games
                          .map((g) => DropdownMenuItem(
                              value: g.slug, child: Text(g.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _gameSlug = v),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Chips(
                label: 'Mode',
                value: _mode,
                options: const {
                  'RANKED': 'Classé',
                  'CASUAL': 'Décontracté',
                  'COMPETITIVE': 'Compétitif',
                  'CO_OP': 'Coopératif',
                },
                onChanged: (v) => setState(() => _mode = v),
              ),
              const SizedBox(height: 16),
              _Chips(
                label: 'Niveau requis',
                value: _level,
                options: const {
                  'BEGINNER': 'Débutant',
                  'INTERMEDIATE': 'Intermédiaire',
                  'ADVANCED': 'Avancé',
                  'EXPERT': 'Expert',
                },
                onChanged: (v) => setState(() => _level = v),
              ),
              const SizedBox(height: 16),
              _Chips(
                label: 'Langue',
                value: _language,
                options: const {'FR': 'Français', 'AR': 'العربية', 'EN': 'English'},
                onChanged: (v) => setState(() => _language = v),
              ),
              const SizedBox(height: 16),
              _Field(
                label: 'Nombre max de joueurs : $_maxPlayers',
                child: Slider(
                  value: _maxPlayers.toDouble(),
                  min: 2,
                  max: 10,
                  divisions: 8,
                  label: '$_maxPlayers',
                  onChanged: (v) => setState(() => _maxPlayers = v.round()),
                ),
              ),
              const SizedBox(height: 8),
              GtTextField(
                controller: _description,
                label: 'Description',
                hint: 'Cherche des joueurs sérieux pour push !',
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              GtButton(
                label: 'CRÉER LA SQUAD',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.stroke),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  const _Chips({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((e) {
            final selected = e.key == value;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(e.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected ? null : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? Colors.transparent : AppColors.stroke),
                ),
                child: Text(e.value,
                    style: TextStyle(
                        color:
                            selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
