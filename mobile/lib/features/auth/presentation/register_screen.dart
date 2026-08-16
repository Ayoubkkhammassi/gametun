import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gt_button.dart';
import '../../../core/widgets/gt_scaffold.dart';
import '../../../core/widgets/gt_text_field.dart';
import '../application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pseudo = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  DateTime? _birthDate;
  String _language = 'FR';
  final _region = TextEditingController(text: 'Tunisie');
  bool _obscure = true;

  Timer? _pseudoDebounce;
  String? _pseudoStatus; // message affiché
  bool? _pseudoAvailable; // null=vérif en cours, true=libre, false=pris/invalide

  static const _languages = {'FR': 'Français', 'AR': 'العربية', 'EN': 'English'};

  /// Vérifie la disponibilité du pseudo en direct (avec anti-rebond).
  void _onPseudoChanged(String value) {
    _pseudoDebounce?.cancel();
    final t = value.trim();
    if (t.length < 3) {
      setState(() {
        _pseudoStatus = null;
        _pseudoAvailable = null;
      });
      return;
    }
    setState(() {
      _pseudoStatus = 'Vérification...';
      _pseudoAvailable = null;
    });
    _pseudoDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final res =
            await ref.read(authRepositoryProvider).checkPseudo(t);
        if (!mounted || _pseudo.text.trim() != t) return;
        setState(() {
          if (!res.valid) {
            _pseudoAvailable = false;
            _pseudoStatus = 'Pseudo invalide';
          } else if (res.available) {
            _pseudoAvailable = true;
            _pseudoStatus = 'Disponible ✓';
          } else {
            _pseudoAvailable = false;
            _pseudoStatus = 'Ce nom existe déjà';
          }
        });
      } catch (_) {
        if (mounted) setState(() => _pseudoStatus = null);
      }
    });
  }

  @override
  void dispose() {
    _pseudoDebounce?.cancel();
    _pseudo.dispose();
    _email.dispose();
    _password.dispose();
    _region.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 16, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Date de naissance',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis ta date de naissance.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final iso = _birthDate!.toIso8601String().split('T').first;
    await ref.read(authControllerProvider.notifier).register(
          email: _email.text.trim(),
          pseudo: _pseudo.text.trim(),
          password: _password.text,
          birthDate: iso,
          language: _language,
          region: _region.text.trim(),
        );
    // Redirection gérée par le routeur si succès.
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final birthLabel = _birthDate == null
        ? 'Choisir une date'
        : '${_birthDate!.day.toString().padLeft(2, '0')}/'
            '${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('CRÉER UN COMPTE')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Rejoins la communauté 🎮',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ta date de naissance reste privée — seule ta tranche d\'âge est visible.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  GtTextField(
                    controller: _pseudo,
                    label: 'Pseudo',
                    hint: 'ex: AYOUB',
                    icon: Icons.badge_outlined,
                    onChanged: _onPseudoChanged,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.length < 3) return 'Au moins 3 caractères';
                      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(t)) {
                        return 'Lettres, chiffres, _ et - uniquement';
                      }
                      if (_pseudoAvailable == false) return 'Pseudo déjà pris';
                      return null;
                    },
                  ),
                  if (_pseudoStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          Icon(
                            _pseudoAvailable == true
                                ? Icons.check_circle
                                : _pseudoAvailable == false
                                    ? Icons.cancel
                                    : Icons.hourglass_empty,
                            size: 15,
                            color: _pseudoAvailable == true
                                ? AppColors.green
                                : _pseudoAvailable == false
                                    ? AppColors.danger
                                    : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(_pseudoStatus!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _pseudoAvailable == true
                                    ? AppColors.green
                                    : _pseudoAvailable == false
                                        ? AppColors.danger
                                        : AppColors.textMuted,
                              )),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  GtTextField(
                    controller: _email,
                    label: 'Email',
                    hint: 'ex: ayoub@mail.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  GtTextField(
                    controller: _password,
                    label: 'Mot de passe',
                    hint: 'Au moins 8 caractères',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 8) ? 'Au moins 8 caractères' : null,
                  ),
                  const SizedBox(height: 18),
                  _DateField(label: birthLabel, onTap: _pickBirthDate),
                  const SizedBox(height: 18),
                  _LanguageSelector(
                    value: _language,
                    labels: _languages,
                    onChanged: (v) => setState(() => _language = v),
                  ),
                  const SizedBox(height: 18),
                  GtTextField(
                    controller: _region,
                    label: 'Région',
                    hint: 'ex: Tunis',
                    icon: Icons.location_on_outlined,
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 28),
                  GtButton(
                    label: 'CRÉER MON COMPTE',
                    loading: state.loading,
                    onPressed: _submit,
                    gradient: AppColors.magentaGradient,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tu pourras choisir tes jeux favoris et ton avatar juste après.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date de naissance',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined,
                    color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final String value;
  final Map<String, String> labels;
  final ValueChanged<String> onChanged;
  const _LanguageSelector({
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Langue',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: labels.entries.map((e) {
            final selected = e.key == value;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onChanged(e.key),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.primaryGradient : null,
                      color: selected ? null : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? Colors.transparent : AppColors.stroke,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
