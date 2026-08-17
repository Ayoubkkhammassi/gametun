import 'dart:math';
import 'package:flutter/material.dart';
import 'cb_models.dart';

/// Illustration procédurale d'une carte, par élément.
/// Scène stylée dessinée en code (gratuit, hors-ligne, original).
/// [seed] varie le motif d'une carte à l'autre.
class CbCardArt extends StatelessWidget {
  final CbElement element;
  final int seed;
  const CbCardArt({super.key, required this.element, this.seed = 0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArtPainter(element, seed),
      child: const SizedBox.expand(),
    );
  }
}

class _ArtPainter extends CustomPainter {
  final CbElement element;
  final int seed;
  _ArtPainter(this.element, this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed * 97 + element.index * 13 + 7);
    final c = element.color;
    // Fond dégradé sombre teinté élément.
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(Colors.black, c, 0.35)!,
          Color.lerp(Colors.black, c, 0.12)!,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    switch (element) {
      case CbElement.braise:
        _braise(canvas, size, rng, c);
        break;
      case CbElement.flots:
        _flots(canvas, size, rng, c);
        break;
      case CbElement.verdant:
        _verdant(canvas, size, rng, c);
        break;
      case CbElement.orage:
        _orage(canvas, size, rng, c);
        break;
      case CbElement.vide:
        _vide(canvas, size, rng, c);
        break;
      case CbElement.lumiere:
        _lumiere(canvas, size, rng, c);
        break;
    }
  }

  // ---- Scènes par élément ------------------------------------------------

  void _braise(Canvas cv, Size s, Random r, Color c) {
    // Arcs de flammes en bas + braises qui montent.
    final flame = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 4; i++) {
      final x = s.width * (0.15 + 0.24 * i);
      final h = s.height * (0.35 + r.nextDouble() * 0.3);
      final path = Path()
        ..moveTo(x - 14, s.height)
        ..quadraticBezierTo(x - 6, s.height - h * 0.6, x, s.height - h)
        ..quadraticBezierTo(x + 6, s.height - h * 0.6, x + 14, s.height)
        ..close();
      flame.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [c, Colors.orangeAccent.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(x - 14, s.height - h, 28, h));
      cv.drawPath(path, flame);
    }
    _sparks(cv, s, r, Colors.orangeAccent, 14);
  }

  void _flots(Canvas cv, Size s, Random r, Color c) {
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = c.withValues(alpha: 0.5);
    for (var i = 0; i < 4; i++) {
      final y = s.height * (0.45 + i * 0.14);
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= s.width; x += s.width / 6) {
        path.relativeQuadraticBezierTo(
            s.width / 12, (i.isEven ? -1 : 1) * 6, s.width / 6, 0);
      }
      cv.drawPath(path, wave);
    }
    _sparks(cv, s, r, Colors.white, 8);
  }

  void _verdant(Canvas cv, Size s, Random r, Color c) {
    // Tiges + feuilles.
    final stem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = c.withValues(alpha: 0.7);
    final leaf = Paint()..color = c.withValues(alpha: 0.55);
    for (var i = 0; i < 3; i++) {
      final x = s.width * (0.25 + i * 0.25);
      cv.drawLine(Offset(x, s.height), Offset(x, s.height * 0.4), stem);
      for (var j = 0; j < 3; j++) {
        final y = s.height * (0.5 + j * 0.14);
        final dir = j.isEven ? 1 : -1;
        final path = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + dir * 16, y - 8, x + dir * 22, y)
          ..quadraticBezierTo(x + dir * 16, y + 6, x, y)
          ..close();
        cv.drawPath(path, leaf);
      }
    }
  }

  void _orage(Canvas cv, Size s, Random r, Color c) {
    final bolt = Paint()
      ..color = c
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 2; i++) {
      final x = s.width * (0.3 + i * 0.4);
      final path = Path()
        ..moveTo(x, s.height * 0.1)
        ..lineTo(x - 10, s.height * 0.5)
        ..lineTo(x - 2, s.height * 0.5)
        ..lineTo(x - 12, s.height * 0.92)
        ..lineTo(x + 10, s.height * 0.42)
        ..lineTo(x + 2, s.height * 0.42)
        ..close();
      cv.drawPath(
          path,
          bolt
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6));
    }
    _sparks(cv, s, r, c, 10);
  }

  void _vide(Canvas cv, Size s, Random r, Color c) {
    // Anneaux concentriques + étoiles.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final center = Offset(s.width / 2, s.height * 0.5);
    for (var i = 0; i < 4; i++) {
      ring.color = c.withValues(alpha: 0.5 - i * 0.1);
      cv.drawCircle(center, 10.0 + i * 12, ring);
    }
    _sparks(cv, s, r, Colors.white, 16);
  }

  void _lumiere(Canvas cv, Size s, Random r, Color c) {
    // Rayons depuis le haut.
    final center = Offset(s.width / 2, s.height * 0.28);
    final ray = Paint()..color = c.withValues(alpha: 0.28);
    for (var i = 0; i < 10; i++) {
      final a = pi / 2 + (i - 5) * 0.16;
      final p = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + cos(a - 0.05) * s.height,
            center.dy + sin(a - 0.05) * s.height)
        ..lineTo(center.dx + cos(a + 0.05) * s.height,
            center.dy + sin(a + 0.05) * s.height)
        ..close();
      cv.drawPath(p, ray);
    }
    cv.drawCircle(center, 10, Paint()..color = c);
  }

  void _sparks(Canvas cv, Size s, Random r, Color c, int n) {
    final p = Paint();
    for (var i = 0; i < n; i++) {
      p.color = c.withValues(alpha: 0.25 + r.nextDouble() * 0.5);
      cv.drawCircle(
        Offset(r.nextDouble() * s.width, r.nextDouble() * s.height),
        r.nextDouble() * 1.8 + 0.5,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArtPainter old) =>
      old.element != element || old.seed != seed;
}
