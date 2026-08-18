import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animation d'apparition (fade + translateY + scale), avec délai optionnel
/// pour créer des effets « en cascade » (staggered).
class GTFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double fromScale;
  const GTFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = GT.normal,
    this.offsetY = 16,
    this.fromScale = 0.96,
  });

  @override
  State<GTFadeIn> createState() => _GTFadeInState();
}

class _GTFadeInState extends State<GTFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) {
        final v = _a.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - v)),
            child: Transform.scale(
              scale: widget.fromScale + (1 - widget.fromScale) * v,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
