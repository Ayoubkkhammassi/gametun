import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Logo GameTun : icône manette dans un halo + wordmark dégradé.
class GtLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  const GtLogo({super.key, this.size = 64, this.showWordmark = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.sports_esports,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.magentaGradient.createShader(bounds),
            child: Text(
              'GameTun',
              style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
