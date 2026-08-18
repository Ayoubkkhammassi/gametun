import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Bouton principal à dégradé néon : micro-interaction (scale au press),
/// glow teinté, reflet, retour haptique. API compatible.
class GtButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Gradient gradient;
  final IconData? icon;

  const GtButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.gradient = AppColors.primaryGradient,
    this.icon,
  });

  @override
  State<GtButton> createState() => _GtButtonState();
}

class _GtButtonState extends State<GtButton> {
  bool _down = false;

  Color get _glow {
    final g = widget.gradient;
    if (g is LinearGradient && g.colors.isNotEmpty) return g.colors.first;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: GT.fast,
          curve: Curves.easeOut,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(GT.rMd),
              boxShadow: [
                BoxShadow(
                  color: _glow.withValues(alpha: 0.28),
                  blurRadius: 12,
                  spreadRadius: -6,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: widget.loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Bouton secondaire (verre + contour lumineux), pour actions moins prioritaires.
class GtOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GtOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onPressed!();
            },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        side: BorderSide(color: GT.glassStroke),
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GT.rMd),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
