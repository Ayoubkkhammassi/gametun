import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_scaffold.dart';

enum _Phase { idle, waiting, go, tooSoon, result }

/// Reaction Time (spec §12) : touche l'écran dès qu'il devient vert.
class ReactionScreen extends StatefulWidget {
  const ReactionScreen({super.key});

  @override
  State<ReactionScreen> createState() => _ReactionScreenState();
}

class _ReactionScreenState extends State<ReactionScreen> {
  _Phase _phase = _Phase.idle;
  Timer? _timer;
  int? _startMs;
  int? _reactionMs;
  int? _best;

  void _start() {
    setState(() => _phase = _Phase.waiting);
    // Délai aléatoire 1.5-4s avant le "GO".
    final delay = 1500 + Random().nextInt(2500);
    _timer = Timer(Duration(milliseconds: delay), () {
      setState(() {
        _phase = _Phase.go;
        _startMs = DateTime.now().millisecondsSinceEpoch;
      });
    });
  }

  void _tap() {
    switch (_phase) {
      case _Phase.idle:
      case _Phase.result:
      case _Phase.tooSoon:
        _start();
        break;
      case _Phase.waiting:
        // Touché trop tôt !
        _timer?.cancel();
        setState(() => _phase = _Phase.tooSoon);
        break;
      case _Phase.go:
        final ms = DateTime.now().millisecondsSinceEpoch - _startMs!;
        setState(() {
          _reactionMs = ms;
          if (_best == null || ms < _best!) _best = ms;
          _phase = _Phase.result;
        });
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _bg {
    switch (_phase) {
      case _Phase.go:
        return AppColors.green;
      case _Phase.waiting:
        return AppColors.danger;
      case _Phase.tooSoon:
        return AppColors.gold;
      default:
        return AppColors.surface;
    }
  }

  String get _text {
    switch (_phase) {
      case _Phase.idle:
        return 'Touche pour commencer';
      case _Phase.waiting:
        return 'Attends le vert...';
      case _Phase.go:
        return 'MAINTENANT !';
      case _Phase.tooSoon:
        return 'Trop tôt ! Touche pour réessayer';
      case _Phase.result:
        return '$_reactionMs ms\nTouche pour rejouer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REACTION TIME')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              if (_best != null)
                Text('Meilleur : $_best ms',
                    style: const TextStyle(
                        color: AppColors.gold, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _tap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Center(
                        child: Text(
                          _text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _phase == _Phase.idle ||
                                    _phase == _Phase.result
                                ? AppColors.textPrimary
                                : Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
