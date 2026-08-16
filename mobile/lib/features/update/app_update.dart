import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/env.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';

class AppUpdateInfo {
  final int versionCode;
  final String versionName;
  final String message;
  final String url;
  final bool mandatory;
  const AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.message,
    required this.url,
    required this.mandatory,
  });
}

/// Vérifie la dernière version publiée. Renvoie l'info SEULEMENT si une
/// mise à jour est disponible (version serveur > version de l'app).
final appUpdateProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  try {
    final data = await ref.read(apiClientProvider).get('/app/version');
    final m = data as Map<String, dynamic>;
    final serverCode = (m['versionCode'] ?? 0) as int;
    if (serverCode <= Env.appVersionCode) return null;
    return AppUpdateInfo(
      versionCode: serverCode,
      versionName: (m['versionName'] ?? '') as String,
      message: (m['message'] ?? 'Nouvelle version disponible') as String,
      url: (m['url'] ?? '') as String,
      mandatory: (m['mandatory'] ?? false) as bool,
    );
  } catch (_) {
    return null; // silencieux si hors-ligne
  }
});

/// Affiche une boîte de dialogue de mise à jour (une seule fois).
Future<void> showUpdateDialog(BuildContext context, AppUpdateInfo info) {
  return showDialog(
    context: context,
    barrierDismissible: !info.mandatory,
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
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.system_update,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Mise à jour disponible 🎮',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(info.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            GtButton(
              label: 'TÉLÉCHARGER',
              icon: Icons.download,
              onPressed: () async {
                final uri = Uri.parse(info.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            if (!info.mandatory) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Plus tard',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
