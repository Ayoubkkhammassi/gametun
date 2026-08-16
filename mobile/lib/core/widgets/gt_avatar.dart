import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Avatar : affiche la photo de profil si dispo (data URI base64 ou URL),
/// sinon l'initiale du pseudo dans un cercle dégradé.
class GtAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String pseudo;
  final double radius;
  final bool online;

  const GtAvatar({
    super.key,
    required this.avatarUrl,
    required this.pseudo,
    this.radius = 24,
    this.online = false,
  });

  Uint8List? get _bytes {
    final url = avatarUrl;
    if (url == null || !url.startsWith('data:')) return null;
    try {
      return base64Decode(url.split(',').last);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final isNetwork = avatarUrl != null && avatarUrl!.startsWith('http');

    Widget avatar;
    if (bytes != null) {
      avatar = CircleAvatar(radius: radius, backgroundImage: MemoryImage(bytes));
    } else if (isNetwork) {
      avatar =
          CircleAvatar(radius: radius, backgroundImage: NetworkImage(avatarUrl!));
    } else {
      avatar = Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          gradient: AppColors.magentaGradient,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          pseudo.isNotEmpty ? pseudo[0].toUpperCase() : '?',
          style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.9,
              fontWeight: FontWeight.w800),
        ),
      );
    }

    if (!online) return avatar;
    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: radius * 0.5,
            height: radius * 0.5,
            decoration: BoxDecoration(
              color: AppColors.online,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bg, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
