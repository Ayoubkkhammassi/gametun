import 'package:flutter/material.dart';
import '../../../core/widgets/gt_logo.dart';
import '../../../core/widgets/gt_scaffold.dart';

/// Écran de démarrage — affiché pendant la restauration de session.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GtBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              GtLogo(size: 84),
              SizedBox(height: 28),
              SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
