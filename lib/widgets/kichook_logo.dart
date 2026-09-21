import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Production-ready Kichook Pinterest-aesthetic Brand Logo widget.
/// Renders the signature List-Ribbon Chef mascot mark cleanly across
/// multiple standard sizes (AppBar, Header, Splash, Cards).
class KichookLogo extends StatelessWidget {
  const KichookLogo({
    super.key,
    this.size = 48.0,
    this.borderRadius,
    this.withContainer = true,
    this.elevation = false,
  });

  /// The width and height of the logo
  final double size;

  /// Optional custom border radius. Defaults to 24% of size.
  final BorderRadius? borderRadius;

  /// Whether to frame the logo in a subtle warm ivory container badge
  final bool withContainer;

  /// Whether to add a soft ambient elevation shadow
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(size * 0.24);

    final imageWidget = ClipRRect(
      borderRadius: effectiveRadius,
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to iconic kitchen mark if asset cannot be resolved
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: effectiveRadius,
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.primary,
              size: size * 0.55,
            ),
          );
        },
      ),
    );

    if (!withContainer) {
      return imageWidget;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: elevation
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: imageWidget,
    );
  }
}
