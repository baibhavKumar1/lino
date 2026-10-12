import 'dart:math' as math;
import 'package:flutter/material.dart';

class Animated3DMascotWidget extends StatefulWidget {
  final double width;
  final double height;
  final String? subtitle;

  const Animated3DMascotWidget({
    super.key,
    this.width = 220,
    this.height = 240,
    this.subtitle,
  });

  @override
  State<Animated3DMascotWidget> createState() => _Animated3DMascotWidgetState();
}

class _Animated3DMascotWidgetState extends State<Animated3DMascotWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _shineController;
  late AnimationController _sparkleController;

  late Animation<double> _floatAnimation;
  late Animation<double> _shineAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();

    // Floating bobbing controller
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutCubic),
    );

    // Continuous diagonal shining light beam
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _shineAnimation = Tween<double>(begin: -1.2, end: 1.8).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOut),
    );

    // Twinkling sparkles controller
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _sparkleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shineController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: Listenable.merge([_floatAnimation, _shineAnimation, _sparkleAnimation]),
            builder: (context, child) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 1. Soft Ground Shadow
                  Positioned(
                    bottom: 0,
                    child: Transform.scale(
                      scale: 1.0 - (_floatAnimation.value / -35).clamp(0.0, 0.3),
                      child: Container(
                        width: widget.width * 0.55,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.12),
                          borderRadius: BorderRadius.all(
                            /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                            Radius.ellipse(widget.width * 0.55, 14),
                            */
                            Radius.elliptical(widget.width * 0.55, 14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Animated Floating Mascot Group
                  Positioned(
                    top: _floatAnimation.value,
                    child: CustomPaint(
                      size: Size(widget.width, widget.height - 20),
                      painter: _Mascot3DPainter(
                        shineProgress: _shineAnimation.value,
                        sparkleOpacity: _sparkleAnimation.value,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.subtitle!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _Mascot3DPainter extends CustomPainter {
  final double shineProgress;
  final double sparkleOpacity;

  _Mascot3DPainter({
    required this.shineProgress,
    required this.sparkleOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width * 0.65;
    final height = size.height * 0.72;

    final outlinePaint = Paint()
      ..color = const Color(0xFF0A2540)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    /* PREVIOUS CHEF CHARACTER & TOQUE HAT LOGIC - COMMENTED OUT AS PER RULE
    // 1. 3D Extruded Left Depth Wall
    // 2. Front 3D Mint Ribbon Face
    // 4. Resting Left Hand (On Hip)
    // 5. Raised Waving Right Hand
    // 6. Expressive 3D Face (Eyes, Cheeks, Smile)
    // 7. Unified 3D Pleated Chef Toque Hat
    */

    // ==========================================
    // MODERN EDITORIAL 3D LINO BRAND EMBLEM
    // Volumetric geometric ribbon 'L' emblem with specular shine
    // ==========================================

    final emblemLeft = center.dx - width * 0.40;
    final emblemRight = center.dx + width * 0.40;
    final emblemTop = center.dy - height * 0.42;
    final emblemBottom = center.dy + height * 0.42;
    const depthOffset = 18.0;

    // 1. 3D Extruded Depth Bevel for 'L' Monogram
    final depthPath = Path();
    depthPath.moveTo(emblemLeft - depthOffset, emblemTop + 20);
    depthPath.lineTo(emblemLeft, emblemTop);
    depthPath.lineTo(emblemLeft, emblemBottom - 24);
    depthPath.lineTo(emblemRight, emblemBottom - 24);
    depthPath.lineTo(emblemRight - depthOffset, emblemBottom);
    depthPath.lineTo(emblemLeft - depthOffset, emblemBottom);
    depthPath.close();

    final depthPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF051626), Color(0xFF0A2540), Color(0xFF003D99)],
      ).createShader(Rect.fromLTRB(emblemLeft - depthOffset, emblemTop, emblemRight, emblemBottom));

    canvas.drawPath(depthPath, depthPaint);

    // 2. Front Volumetric 'L' Ribbon Monogram
    final frontLPath = Path();
    const stemWidth = 38.0;
    const baseHeight = 36.0;
    const radius = 14.0;

    // Outer contour of 'L'
    frontLPath.moveTo(emblemLeft + radius, emblemTop);
    frontLPath.lineTo(emblemLeft + stemWidth, emblemTop);
    frontLPath.lineTo(emblemLeft + stemWidth, emblemBottom - baseHeight);
    frontLPath.lineTo(emblemRight - radius, emblemBottom - baseHeight);
    frontLPath.quadraticBezierTo(emblemRight, emblemBottom - baseHeight, emblemRight, emblemBottom - baseHeight + radius);
    frontLPath.lineTo(emblemRight, emblemBottom - radius);
    frontLPath.quadraticBezierTo(emblemRight, emblemBottom, emblemRight - radius, emblemBottom);
    frontLPath.lineTo(emblemLeft + radius, emblemBottom);
    frontLPath.quadraticBezierTo(emblemLeft, emblemBottom, emblemLeft, emblemBottom - radius);
    frontLPath.lineTo(emblemLeft, emblemTop + radius);
    frontLPath.quadraticBezierTo(emblemLeft, emblemTop, emblemLeft + radius, emblemTop);
    frontLPath.close();

    final frontLPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0066FF), // Electric Azure
          Color(0xFF0A2540), // Deep Aegean Navy
          Color(0xFF0052CC),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTRB(emblemLeft, emblemTop, emblemRight, emblemBottom))
      ..style = PaintingStyle.fill;

    canvas.drawPath(frontLPath, frontLPaint);

    // 3. Top / Inner Edge Chamfer Highlight
    final highlightPath = Path()
      ..moveTo(emblemLeft + radius, emblemTop + 3)
      ..lineTo(emblemLeft + stemWidth - 3, emblemTop + 3)
      ..lineTo(emblemLeft + stemWidth - 3, emblemBottom - baseHeight + 3)
      ..lineTo(emblemRight - radius, emblemBottom - baseHeight + 3);

    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = const Color(0xFF60A5FA).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // 4. Draw Outlines
    canvas.drawPath(frontLPath, outlinePaint);

    // ==========================================
    // 5. CONTINUOUS SPECULAR SHINING LIGHT BEAM
    // ==========================================
    canvas.save();
    canvas.clipPath(frontLPath);

    final shineWidth = width * 0.50;
    final currentShineX = emblemLeft + (width * 1.8 * shineProgress);

    final shinePath = Path()
      ..moveTo(currentShineX, emblemTop - 40)
      ..lineTo(currentShineX + shineWidth, emblemTop - 40)
      ..lineTo(currentShineX - 30, emblemBottom + 40)
      ..lineTo(currentShineX - 30 - shineWidth, emblemBottom + 40)
      ..close();

    final shinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(currentShineX - shineWidth, emblemTop, shineWidth * 2, height));

    canvas.drawPath(shinePath, shinePaint);
    canvas.restore();

    // ==========================================
    // 6. TWINKLING SPECULAR SPARKLING ACCENTS
    // ==========================================
    if (sparkleOpacity > 0.05) {
      _drawSparkle(canvas, Offset(emblemLeft + stemWidth * 0.5, emblemTop + 14), 10 * sparkleOpacity, const Color(0xFF60A5FA));
      _drawSparkle(canvas, Offset(emblemRight - 8, emblemBottom - 18), 12 * (1.1 - sparkleOpacity), const Color(0xFFF59E0B));
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    if (size <= 0) return;
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _Mascot3DPainter oldDelegate) {
    return oldDelegate.shineProgress != shineProgress ||
        oldDelegate.sparkleOpacity != sparkleOpacity;
  }
}
