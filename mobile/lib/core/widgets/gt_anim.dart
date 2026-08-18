import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animation d'apparition (fade + translateY + scale), avec délai optionnel
/// pour créer des effets « en cascade » (staggered).
class GTFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double fromScale;
  const GTFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = GT.normal,
    this.offsetY = 16,
    this.fromScale = 0.96,
  });

  @override
  State<GTFadeIn> createState() => _GTFadeInState();
}

class _GTFadeInState extends State<GTFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) {
        final v = _a.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - v)),
            child: Transform.scale(
              scale: widget.fromScale + (1 - widget.fromScale) * v,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Anneau dégradé rotatif autour d'un contenu circulaire (avatar premium).
class GTGradientRing extends StatefulWidget {
  final Widget child;
  final double size; // diamètre extérieur
  final double thickness;
  const GTGradientRing({
    super.key,
    required this.child,
    this.size = 108,
    this.thickness = 4,
  });

  @override
  State<GTGradientRing> createState() => _GTGradientRingState();
}

class _GTGradientRingState extends State<GTGradientRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inner = widget.size - widget.thickness * 2;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _c,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [
                  AppColors.cyan,
                  AppColors.primary,
                  AppColors.magenta,
                  AppColors.gold,
                  AppColors.cyan,
                ]),
              ),
            ),
          ),
          // Trou central (masque) + glow.
          Container(
            width: inner + 2,
            height: inner + 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20),
              ],
            ),
          ),
          SizedBox(width: inner, height: inner, child: widget.child),
        ],
      ),
    );
  }
}

/// Loader premium : arc lumineux qui tourne + halo pulsant.
class GTLoader extends StatefulWidget {
  final double size;
  const GTLoader({super.key, this.size = 44});

  @override
  State<GTLoader> createState() => _GTLoaderState();
}

class _GTLoaderState extends State<GTLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _LoaderPainter(_c.value),
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double t;
  _LoaderPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2);
    final radius = s.width / 2 - 3;
    // Piste discrète.
    c.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    // Arc lumineux dégradé.
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(colors: [
        AppColors.cyan,
        AppColors.primary,
        AppColors.magenta,
      ]).createShader(rect);
    c.drawArc(rect, t * 2 * pi, pi * 1.4, false, paint);
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter old) => old.t != t;
}

/// État vide élégant : icône dans un halo, message, action optionnelle.
class GTEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const GTEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return GTFadeIn(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.28),
                    Colors.transparent,
                  ]),
                ),
                child: Icon(icon, size: 42, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// État d'erreur élégant (jamais une erreur technique brute) + Réessayer.
class GTErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const GTErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GTEmptyState(
      icon: Icons.wifi_off_rounded,
      message: message,
      actionLabel: 'Réessayer',
      onAction: onRetry,
    );
  }
}
