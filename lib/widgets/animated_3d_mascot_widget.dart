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
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ==========================================
    // 1. 3D EXTRUDED LEFT DEPTH WALL (Isometric Fold)
    // ==========================================
    final depthPath = Path();
    final frontLeft = center.dx - width * 0.35;
    final frontRight = center.dx + width * 0.45;
    final frontTop = center.dy - height * 0.32;
    final frontBottom = center.dy + height * 0.48;
    final notchY = center.dy + height * 0.32;
    final depthOffset = 30.0;

    depthPath.moveTo(frontLeft - depthOffset, frontTop + 24);
    depthPath.quadraticBezierTo(frontLeft - depthOffset, frontTop, frontLeft, frontTop);
    depthPath.lineTo(frontLeft, frontBottom);
    depthPath.lineTo(frontLeft - depthOffset, frontBottom - 18);
    depthPath.close();

    final depthPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF008A56), Color(0xFF006C43), Color(0xFF004A2D)],
      ).createShader(Rect.fromLTWH(frontLeft - depthOffset, frontTop, depthOffset * 2, height));

    canvas.drawPath(depthPath, depthPaint);
    canvas.drawPath(depthPath, outlinePaint);

    // ==========================================
    // 2. FRONT 3D MINT RIBBON FACE
    // ==========================================
    final bodyPath = Path();
    final notchCenterX = (frontLeft + frontRight) / 2;

    bodyPath.moveTo(frontLeft + 18, frontTop);
    bodyPath.quadraticBezierTo(frontLeft, frontTop, frontLeft, frontTop + 18);
    bodyPath.lineTo(frontLeft, frontBottom);
    bodyPath.lineTo(notchCenterX, notchY);
    bodyPath.lineTo(frontRight, frontBottom);
    bodyPath.lineTo(frontRight, frontTop + 18);
    bodyPath.quadraticBezierTo(frontRight, frontTop, frontRight - 18, frontTop);
    bodyPath.close();

    final bodyRect = Rect.fromLTRB(frontLeft, frontTop, frontRight, frontBottom);

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF14E39B), // Mint Highlight
          Color(0xFF00C77F),
          Color(0xFF00A86B), // Base Mint
          Color(0xFF008F5A), // Soft Rim Shade
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(bodyRect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(bodyPath, bodyPaint);

    // Front Inner Rim Highlight Bevel
    final rimBevel = Path()
      ..moveTo(frontLeft + 14, frontTop + 8)
      ..lineTo(frontRight - 14, frontTop + 8);

    canvas.drawPath(
      rimBevel,
      Paint()
        ..color = const Color(0xFFA7F3D0).withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    /* PREVIOUS BODY-ONLY SHINE LOGIC - COMMENTED OUT AS PER RULE
    // ==========================================
    // 3. CONTINUOUS SHINING LIGHT BEAM SWEEP
    // ==========================================
    canvas.save();
    canvas.clipPath(bodyPath);

    final shineWidth = width * 0.48;
    final currentShineX = frontLeft + (width * 1.6 * shineProgress);

    final shinePath = Path()
      ..moveTo(currentShineX, frontTop - 50)
      ..lineTo(currentShineX + shineWidth, frontTop - 50)
      ..lineTo(currentShineX - 35, frontBottom + 50)
      ..lineTo(currentShineX - 35 - shineWidth, frontBottom + 50)
      ..close();

    final shinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(currentShineX - shineWidth, frontTop, shineWidth * 2, height));

    canvas.drawPath(shinePath, shinePaint);
    canvas.restore();
    */

    // Draw Front Body Outline
    canvas.drawPath(bodyPath, outlinePaint);

    // ==========================================
    // 4. RESTING LEFT HAND (ON HIP)
    // ==========================================
    final glovePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 0.75,
        colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 25));

    final leftHipPos = Offset(frontLeft - 8, center.dy + 35);
    canvas.drawCircle(leftHipPos, 16, glovePaint);
    canvas.drawCircle(leftHipPos, 16, outlinePaint);

    // ==========================================
    // 5. RAISED WAVING RIGHT HAND (4 FINGERS)
    // ==========================================
    final rightHandPos = Offset(frontRight + 24, center.dy - 25);
    canvas.drawCircle(rightHandPos, 18, glovePaint);
    canvas.drawCircle(rightHandPos, 18, outlinePaint);

    // Finger Nodule 1
    canvas.drawCircle(Offset(rightHandPos.dx + 4, rightHandPos.dy - 12), 7, glovePaint);
    canvas.drawCircle(Offset(rightHandPos.dx + 4, rightHandPos.dy - 12), 7, outlinePaint);
    // Finger Nodule 2
    canvas.drawCircle(Offset(rightHandPos.dx + 12, rightHandPos.dy - 5), 7, glovePaint);
    canvas.drawCircle(Offset(rightHandPos.dx + 12, rightHandPos.dy - 5), 7, outlinePaint);

    // ==========================================
    // 6. EXPRESSIVE 3D FACE
    // ==========================================
    final faceCenterY = center.dy - 8;
    final eyePaint = Paint()..color = const Color(0xFF111827);
    final sparkleEyePaint = Paint()..color = Colors.white;

    // Left Pill-Eye
    final leftEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(notchCenterX - 22, faceCenterY), width: 11, height: 22),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(leftEyeRect, eyePaint);
    canvas.drawCircle(Offset(notchCenterX - 24, faceCenterY - 4), 2.8, sparkleEyePaint);

    // Right Pill-Eye
    final rightEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(notchCenterX + 22, faceCenterY - 3), width: 11, height: 22),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(rightEyeRect, eyePaint);
    canvas.drawCircle(Offset(notchCenterX + 20, faceCenterY - 7), 2.8, sparkleEyePaint);

    // Smile Line
    final smile = Path()
      ..moveTo(notchCenterX - 10, faceCenterY + 14)
      ..quadraticBezierTo(notchCenterX, faceCenterY + 24, notchCenterX + 12, faceCenterY + 13);

    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF111827)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    // Coral Cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFF645A).withOpacity(0.4);
    canvas.drawOval(Rect.fromCenter(center: Offset(notchCenterX - 36, faceCenterY + 12), width: 13, height: 7), cheekPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(notchCenterX + 36, faceCenterY + 10), width: 13, height: 7), cheekPaint);

    // ==========================================
    // 7. UNIFIED 3D PLEATED CHEF TOQUE HAT (Jaunty Tilted ~ -12 deg)
    // ==========================================
    final hatCenter = Offset(notchCenterX - 4, frontTop - 12);
    final toqueGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
      stops: [0.0, 0.65, 1.0],
    );

    final hatLeft = hatCenter.dx - width * 0.48;
    final hatRight = hatCenter.dx + width * 0.48;
    final hatTop = hatCenter.dy - 65;
    final hatBaseY = hatCenter.dy + 8;

    canvas.save();
    canvas.translate(hatCenter.dx, hatCenter.dy);
    canvas.rotate(-12 * math.pi / 180);
    canvas.translate(-hatCenter.dx, -hatCenter.dy);

    // Single Unified Billowing Cloud Contour
    final hatCrownPath = Path()
      ..moveTo(hatLeft, hatBaseY - 12)
      ..cubicTo(hatLeft - 18, hatCenter.dy - 35, hatLeft + 5, hatTop, hatCenter.dx - 45, hatTop - 8)
      ..cubicTo(hatCenter.dx - 25, hatTop - 20, hatCenter.dx + 25, hatTop - 20, hatCenter.dx + 45, hatTop - 8)
      ..cubicTo(hatRight - 5, hatTop, hatRight + 18, hatCenter.dy - 35, hatRight, hatBaseY - 12)
      ..close();

    canvas.drawPath(
      hatCrownPath,
      Paint()
        ..shader = toqueGradient.createShader(Rect.fromLTRB(hatLeft, hatTop - 20, hatRight, hatBaseY))
        ..style = PaintingStyle.fill,
    );

    /* PREVIOUS VERTICAL PLEAT LINES - COMMENTED OUT AS PER RULE
    // ELEGANT VERTICAL TOQUE PLEAT LINES
    final pleatPaint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final pleatHighlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Pleat 1 (Left)
    canvas.drawPath(
      Path()
        ..moveTo(hatCenter.dx - 36, hatBaseY - 10)
        ..quadraticBezierTo(hatCenter.dx - 40, hatCenter.dy - 25, hatCenter.dx - 46, hatTop + 8),
      pleatPaint,
    );
    // Pleat 2 (Center-Left)
    canvas.drawPath(
      Path()
        ..moveTo(hatCenter.dx - 12, hatBaseY - 10)
        ..quadraticBezierTo(hatCenter.dx - 14, hatCenter.dy - 30, hatCenter.dx - 18, hatTop - 4),
      pleatPaint,
    );
    // Pleat 3 (Center-Right)
    canvas.drawPath(
      Path()
        ..moveTo(hatCenter.dx + 12, hatBaseY - 10)
        ..quadraticBezierTo(hatCenter.dx + 14, hatCenter.dy - 30, hatCenter.dx + 18, hatTop - 4),
      pleatPaint,
    );
    // Pleat 4 (Right)
    canvas.drawPath(
      Path()
        ..moveTo(hatCenter.dx + 36, hatBaseY - 10)
        ..quadraticBezierTo(hatCenter.dx + 40, hatCenter.dy - 25, hatCenter.dx + 46, hatTop + 8),
      pleatPaint,
    );

    // White Flute Highlights between lines
    canvas.drawLine(Offset(hatCenter.dx - 26, hatBaseY - 12), Offset(hatCenter.dx - 32, hatTop + 14), pleatHighlightPaint);
    canvas.drawLine(Offset(hatCenter.dx, hatBaseY - 12), Offset(hatCenter.dx, hatTop - 6), pleatHighlightPaint);
    canvas.drawLine(Offset(hatCenter.dx + 26, hatBaseY - 12), Offset(hatCenter.dx + 32, hatTop + 14), pleatHighlightPaint);
    */

    // NEW VOLUMETRIC 3D CLOUD LOBE SHADING (Soft ambient contours, no harsh lines)
    final cloudShadowPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final cloudHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Soft lobe crevices
    canvas.drawPath(
      Path()
        ..moveTo(hatCenter.dx - 25, hatBaseY - 10)
        ..quadraticBezierTo(hatCenter.dx - 28, hatCenter.dy - 24, hatCenter.dx - 35, hatTop + 12),
      cloudShadowPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(hatCenter.dx + 25, hatBaseY - 10)
        ..quadraticBezierTo(hatCenter.dx + 28, hatCenter.dy - 24, hatCenter.dx + 35, hatTop + 12),
      cloudShadowPaint,
    );

    // Soft top cloud highlights
    canvas.drawPath(
      Path()
        ..moveTo(hatCenter.dx - 30, hatTop - 4)
        ..quadraticBezierTo(hatCenter.dx, hatTop - 16, hatCenter.dx + 30, hatTop - 4),
      cloudHighlightPaint,
    );

    // Crown Outline
    canvas.drawPath(hatCrownPath, outlinePaint);

    // Cylindrical Toque Band
    final bandRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(hatCenter.dx, hatBaseY), width: width * 0.96, height: 24),
      const Radius.circular(8),
    );

    final bandGradient = const LinearGradient(
      colors: [Color(0xFFCBD5E1), Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
      stops: [0.0, 0.25, 0.75, 1.0],
    );

    canvas.drawRRect(bandRect, Paint()..shader = bandGradient.createShader(bandRect.outerRect));
    canvas.drawRRect(bandRect, outlinePaint);

    // Toque Band Top Highlight
    canvas.drawLine(
      Offset(hatCenter.dx - width * 0.40, hatBaseY - 6),
      Offset(hatCenter.dx + width * 0.40, hatBaseY - 6),
      Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    // ==========================================
    // UNIFIED GLOBAL SPECULAR SHINING LIGHT BEAM
    // Sweeps across the entire unified mascot silhouette
    // ==========================================
    final unifiedMascotPath = Path()
      ..addPath(depthPath, Offset.zero)
      ..addPath(bodyPath, Offset.zero);

    canvas.save();
    canvas.clipPath(unifiedMascotPath);

    final globalShineWidth = width * 0.55;
    final currentGlobalShineX = (frontLeft - 30) + (width * 1.8 * shineProgress);

    final globalShinePath = Path()
      ..moveTo(currentGlobalShineX, frontTop - 90)
      ..lineTo(currentGlobalShineX + globalShineWidth, frontTop - 90)
      ..lineTo(currentGlobalShineX - 45, frontBottom + 70)
      ..lineTo(currentGlobalShineX - 45 - globalShineWidth, frontBottom + 70)
      ..close();

    final globalShinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(currentGlobalShineX - globalShineWidth, frontTop - 90, globalShineWidth * 2, height + 160));

    canvas.drawPath(globalShinePath, globalShinePaint);
    canvas.restore();

    // ==========================================
    // 8. SIGNATURE CORAL ENERGY RAYS
    // ==========================================
    final rayPaint = Paint()
      ..color = const Color(0xFFFF645A)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(hatCenter.dx + 65, hatCenter.dy - 42), Offset(hatCenter.dx + 82, hatCenter.dy - 54), rayPaint);
    canvas.drawLine(Offset(hatCenter.dx + 76, hatCenter.dy - 22), Offset(hatCenter.dx + 96, hatCenter.dy - 26), rayPaint);
    canvas.drawLine(Offset(hatCenter.dx + 74, hatCenter.dy - 2), Offset(hatCenter.dx + 93, hatCenter.dy + 4), rayPaint);

    // ==========================================
    // 9. TWINKLING SPECULAR STAR SPARKLES
    // ==========================================
    if (sparkleOpacity > 0.05) {
      _drawSparkle(canvas, Offset(hatCenter.dx - 60, hatCenter.dy + 40), 12 * sparkleOpacity, const Color(0xFFFFD700));
      _drawSparkle(canvas, Offset(frontRight + 12, center.dy + 20), 10 * (1.1 - sparkleOpacity), const Color(0xFF14E39B));
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
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF111827)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _Mascot3DPainter oldDelegate) {
    return oldDelegate.shineProgress != shineProgress ||
        oldDelegate.sparkleOpacity != sparkleOpacity;
  }
}
