import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Fond dégradé sombre avec halos néon discrets (réf. mockup).
class GtBackground extends StatelessWidget {
  final Widget child;
  const GtBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.bg),
      child: Stack(
        children: [
          // Halo violet en haut
          Positioned(
            top: -120,
            left: -80,
            child: _Glow(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          // Halo magenta en bas
          Positioned(
            bottom: -140,
            right: -60,
            child: _Glow(color: AppColors.magenta.withValues(alpha: 0.18)),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  const _Glow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

/// Carte arrondie avec bordure subtile — brique de base de l'UI.
class GtCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback? onTap;
  final Border? border;

  const GtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.color,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: border ?? Border.all(color: AppColors.stroke),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
