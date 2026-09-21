import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable tactile paper background component.
/// Layers a seamless, subtle 300gsm cold-press unbleached cotton paper grain
/// over the theme background color for physical editorial depth.
class TexturedBackground extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double noiseOpacity;

  const TexturedBackground({
    super.key,
    required this.child,
    this.backgroundColor,
    this.noiseOpacity = 0.09,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackground = backgroundColor ?? AppColors.background;

    return Container(
      color: effectiveBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background paper noise grain overlay (Non-interactive)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: noiseOpacity,
                child: Image.asset(
                  'assets/images/paper_noise.png',
                  repeat: ImageRepeat.repeat,
                  fit: BoxFit.none,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          // Content layer
          child,
        ],
      ),
    );
  }
}
