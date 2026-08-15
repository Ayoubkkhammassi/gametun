import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_scaffold.dart';

/// Pierre-Papier-Ciseaux (spec §12) : contre l'app, premier à 5.
class RpsScreen extends StatefulWidget {
  const RpsScreen({super.key});

  @override
  State<RpsScreen> createState() => _RpsScreenState();
}

class _RpsScreenState extends State<RpsScreen> {
  final _rng = Random();
  int _me = 0;
  int _app = 0;
  int? _myChoice;
  int? _appChoice;
  String _result = 'Choisis ton coup !';

  static const _labels = ['Pierre', 'Papier', 'Ciseaux'];
  static const _emojis = ['✊', '✋', '✌️'];

  void _play(int choice) {
    final appChoice = _rng.nextInt(3);
    String res;
    if (choice == appChoice) {
      res = 'Égalité !';
    } else if ((choice == 0 && appChoice == 2) ||
        (choice == 1 && appChoice == 0) ||
        (choice == 2 && appChoice == 1)) {
      res = 'Tu gagnes ce round ! 🎉';
      _me++;
    } else {
      res = 'L\'app gagne ce round 🤖';
      _app++;
    }
    setState(() {
      _myChoice = choice;
      _appChoice = appChoice;
      if (_me >= 5) {
        _result = 'VICTOIRE ! Tu as gagné 🏆';
      } else if (_app >= 5) {
        _result = 'DÉFAITE ! L\'app a gagné 🤖';
      } else {
        _result = res;
      }
    });
  }

  void _reset() {
    setState(() {
      _me = 0;
      _app = 0;
      _myChoice = null;
      _appChoice = null;
      _result = 'Choisis ton coup !';
    });
  }

  bool get _over => _me >= 5 || _app >= 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PIERRE-PAPIER-CISEAUX')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ScoreBox(label: 'Toi', score: _me, color: AppColors.green),
                    const Text('VS',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800)),
                    _ScoreBox(
                        label: 'App', score: _app, color: AppColors.magenta),
                  ],
                ),
                const SizedBox(height: 32),
                // Coups joués
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ChoiceDisplay(
                        emoji: _myChoice != null ? _emojis[_myChoice!] : '❓'),
                    _ChoiceDisplay(
                        emoji: _appChoice != null ? _emojis[_appChoice!] : '❓'),
                  ],
                ),
                const SizedBox(height: 24),
                Text(_result,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_over)
                  ElevatedButton(
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text('REJOUER'),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (i) {
                      return GestureDetector(
                        onTap: () => _play(i),
                        child: Column(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.stroke),
                              ),
                              child: Center(
                                child: Text(_emojis[i],
                                    style: const TextStyle(fontSize: 40)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_labels[i],
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _ScoreBox(
      {required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('$score',
            style: TextStyle(
                color: color, fontSize: 36, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ChoiceDisplay extends StatelessWidget {
  final String emoji;
  const _ChoiceDisplay({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 52))),
    );
  }
}
