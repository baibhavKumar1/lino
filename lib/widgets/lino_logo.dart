import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'lino_logo_path_data.dart';

/// Production-ready Lino Pinterest-aesthetic Brand Logo widget.
/// Renders the signature 3D Golden Brioche Chef mascot cleanly across
/// multiple standard sizes (AppBar, Header, Splash, Cards).
class LinoLogo extends StatelessWidget {
  const LinoLogo({
    super.key,
    this.size = 48.0,
    this.borderRadius,
    this.withContainer = true,
    this.elevation = false,
    this.color,
  });

  /// The width and height of the logo
  final double size;

  /// Optional custom border radius. Defaults to 24% of size.
  final BorderRadius? borderRadius;

  /// Whether to frame the logo in a subtle container badge
  final bool withContainer;

  /// Whether to add a soft ambient elevation shadow
  final bool elevation;

  /// Vector stroke color
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(size * 0.26);
    final effectiveColor = color ?? const Color(0xFF2A2421);

    if (!withContainer) {
      return LinoVectorMark(
        color: effectiveColor,
        width: size * 1.8,
        height: size,
      );
    }

    final brandMark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: effectiveRadius,
        boxShadow: elevation ? AppShadows.sm : null,
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.14),
          child: LinoVectorMark(
            color: effectiveColor,
            width: size * 0.72,
            height: size * 0.42,
          ),
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.04),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: elevation ? AppShadows.sm : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius.topLeft.x * 0.85),
        child: brandMark,
      ),
    );
  }
}

/// Official clean Lino vector wordmark widget (SVG continuous line path, no tagline)
class LinoWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final double letterSpacing;
  final double? height;
  final double? width;

  const LinoWordmark({
    super.key,
    this.fontSize = 24.0,
    this.color,
    this.letterSpacing = -0.5,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? fontSize * 1.1;
    final effectiveWidth = width ?? effectiveHeight * 2.16;

    return LinoVectorMark(
      color: color ?? AppColors.textPrimary,
      width: effectiveWidth,
      height: effectiveHeight,
    );
  }
}

/// Native Canvas Vector Renderer for the official Lino continuous-ribbon wordmark
class LinoVectorMark extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  /* PREVIOUS CONSTRUCTOR - COMMENTED OUT AS PER RULE
  const LinoVectorMark({
    super.key,
    this.color = const Color(0xFF2A2421),
    this.width = 100,
    this.height = 46,
  });
  */

  const LinoVectorMark({
    super.key,
    this.color = const Color(0xFF2A2421),
    double? size,
    double? width,
    double? height,
  })  : width = width ?? (size != null ? size * 1.8 : 100),
        height = height ?? (size ?? 46);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: LinoLogoVectorPainter(color: color),
      ),
    );
  }
}

/// Exact Bézier vector painter replicating the 1:1 contour of 'lino' from logo.jpg
class LinoLogoVectorPainter extends CustomPainter {
  final Color color;

  const LinoLogoVectorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Reference original dimensions: 551 x 227
    final scaleX = size.width / LinoLogoPathData.originalWidth;
    final scaleY = size.height / LinoLogoPathData.originalHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final dx = (size.width - LinoLogoPathData.originalWidth * scale) / 2.0;
    final dy = (size.height - LinoLogoPathData.originalHeight * scale) / 2.0;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = LinoLogoPathData.buildPath();
    canvas.drawPath(path, fillPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LinoLogoVectorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

