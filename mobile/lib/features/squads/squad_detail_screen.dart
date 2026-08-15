import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';
import 'squad_repository.dart';

/// Détail d'une squad (réf. mockup « ÉQUIPE TROUVÉE ») : membres + Smart Squad.
class SquadDetailScreen extends ConsumerStatefulWidget {
  final String squadId;
  const SquadDetailScreen({super.key, required this.squadId});

  @override
  ConsumerState<SquadDetailScreen> createState() => _SquadDetailScreenState();
}

class _SquadDetailScreenState extends ConsumerState<SquadDetailScreen> {
  Map<String, dynamic>? _squad;
  bool _loading = true;
  String? _error;
  bool _smartLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(squadRepositoryProvider).detail(widget.squadId);
      setState(() => _squad = data);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _smartComplete() async {
    setState(() => _smartLoading = true);
    try {
      final res =
          await ref.read(squadRepositoryProvider).smartComplete(widget.squadId);
      final suggestions = (res['suggestions'] ?? []) as List;
      if (mounted) _showSuggestions(suggestions);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _smartLoading = false);
    }
  }

  void _showSuggestions(List suggestions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Squad — joueurs suggérés',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Classés par compatibilité pour compléter ton équipe.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            if (suggestions.isEmpty)
              const Text('Aucune suggestion pour l\'instant.',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              ...suggestions.map((s) {
                final m = s as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.surfaceAlt,
                        child: Text(
                          (m['pseudo'] as String).isNotEmpty
                              ? (m['pseudo'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(m['pseudo'] as String,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text('${m['compatibility']}%',
                          style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SQUAD')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppColors.textSecondary)))
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final s = _squad!;
    final game = s['game'] as Map<String, dynamic>?;
    final members = (s['members'] ?? []) as List;
    final maxPlayers = s['maxPlayers'] as int;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.groups, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(s['name'] as String,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                '${game?['name'] ?? ''} • ${s['mode']} • ${s['requiredLevel']}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text('${members.length}/$maxPlayers joueurs',
                  style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
        if (s['description'] != null &&
            (s['description'] as String).isNotEmpty) ...[
          const SizedBox(height: 16),
          GtCard(
            child: Text(s['description'] as String,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
        const SizedBox(height: 20),
        const Text('Membres',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...members.map((m) {
          final mm = m as Map<String, dynamic>;
          final isCaptain = mm['role'] == 'CAPTAIN';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GtCard(
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.surfaceAlt,
                        child: Text(
                          (mm['pseudo'] as String).isNotEmpty
                              ? (mm['pseudo'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      if (mm['isOnline'] == true)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: AppColors.online,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppColors.card, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(mm['pseudo'] as String,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                  ),
                  if (isCaptain)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Capitaine',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        // Smart Squad — compléter automatiquement l'équipe.
        if (members.length < maxPlayers)
          GtButton(
            label: 'SMART SQUAD — COMPLÉTER L\'ÉQUIPE',
            icon: Icons.auto_awesome,
            gradient: AppColors.magentaGradient,
            loading: _smartLoading,
            onPressed: _smartComplete,
          ),
      ],
    );
  }
}
