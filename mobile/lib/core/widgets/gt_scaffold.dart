import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Fond « aurora » animé : dégradé sombre + halos néon qui dérivent lentement
/// + particules flottantes. Un seul painter, isolé par RepaintBoundary (60 FPS).
class GtBackground extends StatefulWidget {
  final Widget child;
  const GtBackground({super.key, required this.child});

  @override
  State<GtBackground> createState() => _GtBackgroundState();
}

class _GtBackgroundState extends State<GtBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    final rng = Random(7);
    _particles = List.generate(
      16,
      (_) => _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        r: rng.nextDouble() * 1.6 + 0.6,
        speed: rng.nextDouble() * 0.4 + 0.15,
        phase: rng.nextDouble() * pi * 2,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(
                  painter: _AuroraPainter(_c.value, _particles),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Particle {
  final double x, y, r, speed, phase;
  _Particle({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
  });
}

class _AuroraPainter extends CustomPainter {
  final double t; // 0..1
  final List<_Particle> particles;
  _AuroraPainter(this.t, this.particles);

  void _blob(Canvas c, Size s, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, Colors.transparent])
          .createShader(Rect.fromCircle(center: center, radius: radius));
    c.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas c, Size s) {
    final a = t * 2 * pi;
    // 3 halos qui dérivent doucement.
    _blob(
      c,
      s,
      Offset(s.width * (0.2 + 0.12 * sin(a)), s.height * (0.12 + 0.05 * cos(a))),
      s.width * 0.7,
      AppColors.primary.withValues(alpha: 0.22),
    );
    _blob(
      c,
      s,
      Offset(s.width * (0.85 + 0.08 * cos(a * 0.8)),
          s.height * (0.8 + 0.06 * sin(a * 0.8))),
      s.width * 0.7,
      AppColors.magenta.withValues(alpha: 0.16),
    );
    _blob(
      c,
      s,
      Offset(s.width * (0.1 + 0.06 * cos(a * 1.2)),
          s.height * (0.95 + 0.04 * sin(a))),
      s.width * 0.55,
      AppColors.cyan.withValues(alpha: 0.10),
    );
    // Particules flottantes.
    final pp = Paint();
    for (final p in particles) {
      final py = (p.y - (t * p.speed)) % 1.0;
      final drift = sin(a + p.phase) * 6;
      final pos = Offset(p.x * s.width + drift, py * s.height);
      pp.color = Colors.white.withValues(alpha: 0.06 + 0.06 * sin(a + p.phase));
      c.drawCircle(pos, p.r, pp);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}

/// Carte « verre » : fond translucide, reflet supérieur, bordure lumineuse,
/// ombre douce. API compatible avec l'ancienne GtCard.
class GtCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final Border? border;
  final double radius;
  final Color? glow;

  const GtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.color,
    this.onTap,
    this.border,
    this.radius = GT.rLg,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final useCustom = gradient != null || color != null;

    final decoration = BoxDecoration(
      borderRadius: br,
      // Fond : soit personnalisé (compat), soit verre translucide.
      color: useCustom ? color : null,
      gradient: gradient ??
          (useCustom
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                )),
      border: border ??
          Border.all(color: GT.glassStroke, width: 1),
      boxShadow: [
        BoxShadow(
          color: (glow ?? Colors.black).withValues(alpha: glow != null ? 0.35 : 0.28),
          blurRadius: glow != null ? 22 : 16,
          offset: const Offset(0, 8),
        ),
      ],
    );

    // Reflet lumineux en haut (fin liseré).
    final content = DecoratedBox(
      decoration: decoration,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 14,
            right: 14,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  GT.glassHighlight,
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (onTap == null) {
      return ClipRRect(borderRadius: br, child: content);
    }
    return ClipRRect(
      borderRadius: br,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: br,
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}

/// Enveloppe « glass » réutilisable avec vrai backdrop blur (pour nav, modales,
/// bottom sheets — usages ponctuels, performants).
class GtGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry padding;
  const GtGlass({
    super.key,
    required this.child,
    this.radius = GT.rLg,
    this.blur = GT.blurMd,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: GT.glassStroke),
          ),
          child: child,
        ),
      ),
    );
  }
}
