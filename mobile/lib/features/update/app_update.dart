import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
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
    builder: (ctx) => _UpdateDialog(info: info),
  );
}

/// Dialogue de MAJ : télécharge l'APK dans l'app (barre de progression)
/// puis l'ouvre directement pour l'installer (zéro passage par le navigateur).
class _UpdateDialog extends StatefulWidget {
  final AppUpdateInfo info;
  const _UpdateDialog({required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _downloadAndInstall() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/gametun_v${widget.info.versionCode}.apk';
      await Dio().download(
        widget.info.url,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );
      // Ouvre l'APK → Android propose l'installation directement.
      final res = await OpenFilex.open(path);
      if (res.type != ResultType.done && mounted) {
        setState(() {
          _downloading = false;
          _error = "Impossible d'ouvrir l'installateur. Réessaie ou "
              'télécharge via le navigateur.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'Échec du téléchargement. Vérifie ta connexion et réessaie.';
        });
      }
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.info.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return Dialog(
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
            if (_downloading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text('Téléchargement… ${(_progress * 100).round()}%',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
            ] else ...[
              GtButton(
                label: 'METTRE À JOUR',
                icon: Icons.download,
                onPressed: _downloadAndInstall,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.magenta, fontSize: 12)),
                TextButton(
                  onPressed: _openInBrowser,
                  child: const Text('Ouvrir dans le navigateur',
                      style: TextStyle(color: AppColors.cyan)),
                ),
              ],
              if (!info.mandatory && _error == null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Plus tard',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
