import 'package:flutter/material.dart';

/// Palette GameTun — sombre, gaming, néon (réf. mockup).
class AppColors {
  AppColors._();

  // Fonds — presque noir
  static const Color bg = Color(0xFF07060D);
  static const Color surface = Color(0xFF12101C);
  static const Color surfaceAlt = Color(0xFF1A1726);
  static const Color card = Color(0xFF161326);
  static const Color stroke = Color(0xFF272235);

  // Néons de marque
  static const Color primary = Color(0xFF8B5CF6); // violet néon
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color magenta = Color(0xFFEC4899); // rose/magenta
  static const Color cyan = Color(0xFF22D3EE); // cyan
  static const Color green = Color(0xFF34D399); // vert (en ligne / succès)
  static const Color gold = Color(0xFFFBBF24); // premium

  // Texte
  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textSecondary = Color(0xFFA7A3B8);
  static const Color textMuted = Color(0xFF6E6980);

  // États
  static const Color danger = Color(0xFFEF4444);
  static const Color online = green;

  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  );

  static const LinearGradient magentaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B1D6E), Color(0xFF1E1145)],
  );
}
