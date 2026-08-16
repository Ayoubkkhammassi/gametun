import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gt_scaffold.dart';

/// Écran de démarrage animé (logo néon pulsant + anneau LED + entrée en fondu).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _intro,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.3, 1, curve: Curves.easeIn),
  );

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GtBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo + anneau LED animé.
              AnimatedBuilder(
                animation: Listenable.merge([_intro, _loop]),
                builder: (context, _) {
                  final pulse = 0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi);
                  return Transform.scale(
                    scale: 0.4 + 0.6 * _scale.value.clamp(0.0, 1.0),
                    child: SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Anneau LED qui tourne.
                          Transform.rotate(
                            angle: _loop.value * 2 * math.pi,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: const [
                                    AppColors.primary,
                                    AppColors.magenta,
                                    AppColors.cyan,
                                    AppColors.primary,
                                  ],
                                  transform: GradientRotation(_loop.value * 6.28),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.bg,
                                ),
                              ),
                            ),
                          ),
                          // Logo central (effet 3D + glow pulsant).
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.4 + 0.4 * pulse),
                                  blurRadius: 30 + 20 * pulse,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  offset: const Offset(4, 6),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.sports_esports,
                                color: Colors.white, size: 52),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              // Wordmark dégradé en fondu.
              FadeTransition(
                opacity: _fade,
                child: ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.magentaGradient.createShader(b),
                  child: const Text(
                    'GameTun',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fade,
                child: const Text(
                  'La communauté gaming tunisienne',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fade,
                child: const SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
