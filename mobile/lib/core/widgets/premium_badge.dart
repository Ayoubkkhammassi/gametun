import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../features/premium/premium_screen.dart';
import 'gt_button.dart';

/// Petit badge doré ✨ affiché à côté du pseudo des membres Premium.
class PremiumBadge extends StatelessWidget {
  final double size;
  const PremiumBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold, Color(0xFFFFD86B)],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.workspace_premium,
          size: size, color: const Color(0xFF1A1400)),
    );
  }
}

/// Boîte de dialogue d'incitation à passer Premium (upsell), avec un
/// bouton menant à l'écran d'abonnement.
Future<void> showPremiumUpsell(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gold, Color(0xFFFFD86B)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium,
                  color: Color(0xFF1A1400), size: 34),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            GtButton(
              label: 'PASSER PREMIUM 💎',
              icon: Icons.workspace_premium,
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Plus tard',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    ),
  );
}
