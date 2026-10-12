import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Expressive moods supported by the interactive Lino Mascot state machine
enum MascotMood {
  idle,
  waving,
  thinking,
  celebrating,
  peekaboo, // Shy / eyes covered for password entry
  curious, // Focus on text fields
  emptyPantry,
  cooking,
}

/// A production-ready, GPU-accelerated interactive vector mascot widget.
/// Features smooth spring physics, natural eye-blinking, focus-based gaze tracking,
/// specular light sweeps, and tactile tap reactions.
class InteractiveMascot extends StatefulWidget {
  final double size;
  final MascotMood mood;
  final Offset? lookAtOffset; // Normalized gaze target (-1.0 to 1.0)
  final VoidCallback? onTap;
  final String? caption;
  final bool enableTapReaction;

  const InteractiveMascot({
    super.key,
    this.size = 120,
    this.mood = MascotMood.idle,
    this.lookAtOffset,
    this.onTap,
    this.caption,
    this.enableTapReaction = true,
  });

  @override
  State<InteractiveMascot> createState() => _InteractiveMascotState();
}

class _InteractiveMascotState extends State<InteractiveMascot>
    with TickerProviderStateMixin {
  late AnimationController _idleFloatController;
  late AnimationController _blinkController;
  late AnimationController _waveController;
  late AnimationController _shineController;
  late AnimationController _tapSquashController;

  late Animation<double> _idleFloatAnim;
  late Animation<double> _blinkAnim;
  late Animation<double> _waveAnim;
  late Animation<double> _shineAnim;
  late Animation<double> _tapSquashAnim;

  Timer? _blinkTimer;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // 1. Ambient Floating / Breathing Cycle - DISABLED AS REQUESTED (NO BOUNCING)
    /* PREVIOUS BOUNCING CONTROLLER - COMMENTED OUT AS PER RULE
    _idleFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _idleFloatAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _idleFloatController,
        curve: Curves.easeInOutCubic,
      ),
    );
    */
    _idleFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
    );
    _idleFloatAnim = const AlwaysStoppedAnimation<double>(0.0);

    // 2. Natural Random Eye Blink Cycle
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    _blinkAnim = Tween<double>(begin: 1.0, end: 0.05).animate(
      CurvedAnimation(
        parent: _blinkController,
        curve: Curves.easeInOutQuad,
      ),
    );

    _scheduleNextBlink();

    // 3. Waving Hand Controller
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _waveAnim = const AlwaysStoppedAnimation<double>(0.0);

    // 4. Specular Highlight Sweep
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _shineAnim = const AlwaysStoppedAnimation<double>(0.0);

    // 5. Tactile Tap Spring Squash - DISABLED TO PREVENT BOUNCING AND TWEENSEQUENCE ASSERTION
    /* PREVIOUS TWEENSEQUENCE WITH EASEOUTBACK - COMMENTED OUT AS PER RULE
    _tapSquashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _tapSquashAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.08), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(
        parent: _tapSquashController,
        curve: Curves.easeOutBack,
      ),
    );
    */
    _tapSquashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
    );
    _tapSquashAnim = const AlwaysStoppedAnimation<double>(1.0);
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    final delayMs = 2400 + _random.nextInt(3200);
    _blinkTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _blinkController.forward().then((_) {
        if (mounted) {
          _blinkController.reverse().then((_) {
            if (mounted) _scheduleNextBlink();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idleFloatController.dispose();
    _blinkController.dispose();
    _waveController.dispose();
    _shineController.dispose();
    _tapSquashController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enableTapReaction) {
      _tapSquashController.forward(from: 0.0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    /* PREVIOUS UNBOUNDED SIZING - COMMENTED OUT AS PER RULE
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          child: SizedBox(
            width: widget.size * 1.15,
            height: widget.size * 1.25,
            ...
    */
    final mascotWidget = GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _idleFloatAnim,
              _blinkAnim,
              _waveAnim,
              _shineAnim,
              _tapSquashAnim,
            ]),
            builder: (context, child) {
              final floatVal = _idleFloatAnim.value;
              final squashVal = _tapSquashAnim.value;

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 1. Soft Dynamic Ground Shadow
                  Positioned(
                    bottom: 2,
                    child: Transform.scale(
                      scaleX: (1.0 - (floatVal / -30)).clamp(0.6, 1.1) * squashVal,
                      scaleY: 0.85,
                      child: Container(
                        width: widget.size * 0.48,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.all(
                            Radius.elliptical(widget.size * 0.48, 10),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Animated Character Body (3D Asset with Perspective Tilt & Vector Fallback)
                  Positioned(
                    top: 0 + floatVal,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015) // Subtle 3D perspective
                        ..rotateX(
                          widget.mood == MascotMood.thinking
                              ? -0.08
                              : widget.mood == MascotMood.curious
                                  ? 0.08
                                  : 0.0,
                        )
                        ..rotateY(
                          (widget.lookAtOffset?.dx ?? 0.0) * 0.15 +
                              (widget.mood == MascotMood.waving ? _waveAnim.value * 0.4 : 0.0),
                        )
                        ..rotateZ(
                          widget.mood == MascotMood.peekaboo
                              ? -0.06
                              : (widget.mood == MascotMood.waving ? _waveAnim.value * 0.25 : 0.0),
                        ),
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scaleX: (2.0 - squashVal) * (widget.mood == MascotMood.thinking ? 0.96 : 1.0),
                        scaleY: squashVal,
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: widget.size,
                          height: widget.size,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Primary: Authentic Photorealistic 3D Matte Clay Render
                              ClipRRect(
                                borderRadius: BorderRadius.circular(widget.size * 0.28),
                                child: Image.asset(
                                  'assets/images/lino_mascot.png',
                                  width: widget.size,
                                  height: widget.size,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Direct file path fallback for desktop/dev mode
                                    return Image.file(
                                      File(
                                        r'C:\Users\hireb\.gemini\antigravity-cli\brain\7a9c5706-817f-44f5-8b23-aca094cc3278\lino_hero_mascot_brioche_proportional_hat_1791142133590.jpg',
                                      ),
                                      width: widget.size,
                                      height: widget.size,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, st) {
                                        // Fallback to logo.png
                                        return Image.asset(
                                          'assets/images/logo.png',
                                          width: widget.size,
                                          height: widget.size,
                                          fit: BoxFit.contain,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              // Ambient Specular Sweep Flare
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(widget.size * 0.28),
                                  child: CustomPaint(
                                    painter: _SpecularSweepPainter(
                                      progress: _shineAnim.value,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (widget.caption != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mascotWidget,
          const SizedBox(height: 6),
          Text(
            widget.caption!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return mascotWidget;
  }
}

class _LinoMascotPainter extends CustomPainter {
  final MascotMood mood;
  final double blinkScale;
  final double waveAngle;
  final double shineProgress;
  final Offset gazeOffset;

  _LinoMascotPainter({
    required this.mood,
    required this.blinkScale,
    required this.waveAngle,
    required this.shineProgress,
    required this.gazeOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2 + 4);

    // ==========================================
    // 1. MASCOT BODY (Volumetric Golden Brioche Squircle)
    // ==========================================
    final bodyRect = Rect.fromCenter(
      center: center,
      width: w * 0.72,
      height: h * 0.76,
    );
    final bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(w * 0.30),
    );

    // Deep Ambient Back Shadow / Bevel
    final shadowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF92400E), // Warm deep amber shadow
          Color(0xFF78350F),
        ],
      ).createShader(bodyRect.shift(const Offset(0, 6)));
    canvas.drawRRect(bodyRRect.shift(const Offset(0, 4)), shadowPaint);

    /* PREVIOUS AZURE / NAVY SLATE SHADER - COMMENTED OUT AS PER RULE
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3B82F6), // Vibrant Azure
          Color(0xFF1E293B), // Nordic Slate
          Color(0xFF0F172A), // Deep Aegean
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(bodyRect);
    */

    // Golden Brioche Loaf Gradient
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFDE68A), // Warm Golden Crumb Highlight
          Color(0xFFF59E0B), // Golden Honey Amber
          Color(0xFFD97706), // Baked Crust Amber
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(bodyRect);
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Body Outline
    final outlinePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(bodyRRect, outlinePaint);

    // ==========================================
    // 2. SPECULAR LIGHT SWEEP (Clipped to body)
    // ==========================================
    canvas.save();
    canvas.clipRRect(bodyRRect);

    final shineWidth = w * 0.45;
    final shineX = bodyRect.left + (bodyRect.width * 1.8 * shineProgress);

    final shinePath = Path()
      ..moveTo(shineX, bodyRect.top - 20)
      ..lineTo(shineX + shineWidth, bodyRect.top - 20)
      ..lineTo(shineX - 20, bodyRect.bottom + 20)
      ..lineTo(shineX - 20 - shineWidth, bodyRect.bottom + 20)
      ..close();

    final shinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(shineX - shineWidth, bodyRect.top, shineWidth * 2, bodyRect.height));

    canvas.drawPath(shinePath, shinePaint);
    canvas.restore();

    // ==========================================
    // 3. ELECTRIC BLUE CHEF TOQUE (3/4 of head width)
    // ==========================================
    final hatCenter = Offset(center.dx, bodyRect.top - 6);
    /* PREVIOUS SMALLER HAT SIZE - COMMENTED OUT AS PER RULE
    _drawChefHat(canvas, hatCenter, w * 0.44);
    */
    final prominentHatWidth = bodyRect.width * 0.75; // 3/4 of head width
    _drawChefHat(canvas, hatCenter, prominentHatWidth);

    // ==========================================
    // 4. HANDS & ARMS
    // ==========================================
    _drawHands(canvas, bodyRect, w);

    // ==========================================
    // 5. EXPRESSIVE EYES & CHEEKS
    // ==========================================
    _drawFace(canvas, center, w, h);
  }

  void _drawChefHat(Canvas canvas, Offset topCenter, double hatWidth) {
    final hatHeight = hatWidth * 0.62;
    final hatRect = Rect.fromCenter(
      center: Offset(topCenter.dx, topCenter.dy - hatHeight * 0.38),
      width: hatWidth,
      height: hatHeight,
    );

    // Hat base band
    final bandRect = Rect.fromCenter(
      center: Offset(topCenter.dx, topCenter.dy - 2),
      width: hatWidth * 0.78,
      height: 12,
    );
    final bandRRect = RRect.fromRectAndRadius(bandRect, const Radius.circular(6));
    /* PREVIOUS WHITE BAND - COMMENTED OUT AS PER RULE
    final bandPaint = Paint()..color = const Color(0xFFF1F5F9);
    */
    final bandPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
      ).createShader(bandRect);
    canvas.drawRRect(bandRRect, bandPaint);

    // Hat Pleated Puffs (Prominent, voluptuous 3-lobe chef toque)
    final puffPath = Path();
    puffPath.moveTo(bandRect.left, bandRect.top);
    puffPath.cubicTo(
      bandRect.left - 16,
      hatRect.top + 6,
      hatRect.left + 2,
      hatRect.top - 16,
      topCenter.dx - hatWidth * 0.24,
      hatRect.top - 8,
    );
    puffPath.cubicTo(
      topCenter.dx - hatWidth * 0.12,
      hatRect.top - 22,
      topCenter.dx + hatWidth * 0.12,
      hatRect.top - 22,
      topCenter.dx + hatWidth * 0.24,
      hatRect.top - 8,
    );
    puffPath.cubicTo(
      hatRect.right - 2,
      hatRect.top - 16,
      bandRect.right + 16,
      hatRect.top + 6,
      bandRect.right,
      bandRect.top,
    );
    puffPath.close();

    /* PREVIOUS WHITE HAT SHADER - COMMENTED OUT AS PER RULE
    final hatPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFE2E8F0),
        ],
      ).createShader(hatRect);
    */

    // Electric Blue Chef Toque
    final hatPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF60A5FA), // Light Azure Highlight
          Color(0xFF3B82F6), // Electric Azure
          Color(0xFF1D4ED8), // Deep Royal Blue Base
        ],
      ).createShader(hatRect);

    canvas.drawPath(puffPath, hatPaint);
    canvas.drawPath(
      puffPath,
      Paint()
        ..color = const Color(0xFF1E3A8A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawHands(Canvas canvas, Rect bodyRect, double w) {
    /* PREVIOUS SLATE HANDS - COMMENTED OUT AS PER RULE
    final handPaint = Paint()..color = const Color(0xFFE2E8F0);
    final handOutline = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    */
    final handPaint = Paint()..color = const Color(0xFFF59E0B);
    final handOutline = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    switch (mood) {
      case MascotMood.waving:
        // Left hand on hip
        canvas.drawCircle(Offset(bodyRect.left + 2, bodyRect.center.dy + 8), 7, handPaint);
        canvas.drawCircle(Offset(bodyRect.left + 2, bodyRect.center.dy + 8), 7, handOutline);

        // Right hand waving above
        canvas.save();
        canvas.translate(bodyRect.right + 2, bodyRect.top + 10);
        canvas.rotate(waveAngle);
        final wavingHand = Path()
          ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -14, 12, 14), const Radius.circular(6)));
        canvas.drawPath(wavingHand, handPaint);
        canvas.drawPath(wavingHand, handOutline);
        canvas.restore();
        break;

      case MascotMood.peekaboo:
        // Both hands covering eyes playfully
        canvas.drawCircle(Offset(bodyRect.center.dx - 14, bodyRect.center.dy - 6), 9, handPaint);
        canvas.drawCircle(Offset(bodyRect.center.dx - 14, bodyRect.center.dy - 6), 9, handOutline);
        canvas.drawCircle(Offset(bodyRect.center.dx + 14, bodyRect.center.dy - 6), 9, handPaint);
        canvas.drawCircle(Offset(bodyRect.center.dx + 14, bodyRect.center.dy - 6), 9, handOutline);
        break;

      case MascotMood.celebrating:
        // Both hands raised high
        canvas.drawCircle(Offset(bodyRect.left - 4, bodyRect.top + 6), 8, handPaint);
        canvas.drawCircle(Offset(bodyRect.left - 4, bodyRect.top + 6), 8, handOutline);
        canvas.drawCircle(Offset(bodyRect.right + 4, bodyRect.top + 6), 8, handPaint);
        canvas.drawCircle(Offset(bodyRect.right + 4, bodyRect.top + 6), 8, handOutline);
        break;

      case MascotMood.thinking:
        // One hand on chin
        canvas.drawCircle(Offset(bodyRect.center.dx + 8, bodyRect.center.dy + 16), 8, handPaint);
        canvas.drawCircle(Offset(bodyRect.center.dx + 8, bodyRect.center.dy + 16), 8, handOutline);
        break;

      case MascotMood.cooking:
        // Holding a spoon
        canvas.drawCircle(Offset(bodyRect.right + 2, bodyRect.center.dy + 4), 8, handPaint);
        canvas.drawCircle(Offset(bodyRect.right + 2, bodyRect.center.dy + 4), 8, handOutline);
        // Spoon stem
        canvas.drawLine(
          Offset(bodyRect.right + 2, bodyRect.center.dy - 12),
          Offset(bodyRect.right + 2, bodyRect.center.dy + 14),
          Paint()
            ..color = const Color(0xFFCBD5E1)
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round,
        );
        break;

      default:
        // Resting hands
        canvas.drawCircle(Offset(bodyRect.left + 4, bodyRect.center.dy + 12), 6.5, handPaint);
        canvas.drawCircle(Offset(bodyRect.left + 4, bodyRect.center.dy + 12), 6.5, handOutline);
        canvas.drawCircle(Offset(bodyRect.right - 4, bodyRect.center.dy + 12), 6.5, handPaint);
        canvas.drawCircle(Offset(bodyRect.right - 4, bodyRect.center.dy + 12), 6.5, handOutline);
    }
  }

  void _drawFace(Canvas canvas, Offset center, double w, double h) {
    if (mood == MascotMood.peekaboo) {
      // Eyes covered, draw small blush cheeks
      final cheekPaint = Paint()..color = const Color(0xFFFF6B6B).withValues(alpha: 0.55);
      canvas.drawCircle(Offset(center.dx - 22, center.dy + 10), 5, cheekPaint);
      canvas.drawCircle(Offset(center.dx + 22, center.dy + 10), 5, cheekPaint);
      return;
    }

    final eyeSpacing = w * 0.16;
    final eyeY = center.dy - 6;

    final gazeX = (gazeOffset.dx * 3.5).clamp(-3.5, 3.5);
    final gazeY = (gazeOffset.dy * 2.5).clamp(-2.5, 2.5);

    // Left Eye & Right Eye Positions
    final leftEyeCenter = Offset(center.dx - eyeSpacing, eyeY);
    final rightEyeCenter = Offset(center.dx + eyeSpacing, eyeY);

    if (mood == MascotMood.celebrating || mood == MascotMood.waving) {
      // Joyful upward arc eyes
      final arcPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;

      final leftArc = Path()
        ..moveTo(leftEyeCenter.dx - 6, leftEyeCenter.dy + 2)
        ..quadraticBezierTo(leftEyeCenter.dx, leftEyeCenter.dy - 5, leftEyeCenter.dx + 6, leftEyeCenter.dy + 2);
      final rightArc = Path()
        ..moveTo(rightEyeCenter.dx - 6, rightEyeCenter.dy + 2)
        ..quadraticBezierTo(rightEyeCenter.dx, rightEyeCenter.dy - 5, rightEyeCenter.dx + 6, rightEyeCenter.dy + 2);

      canvas.drawPath(leftArc, arcPaint);
      canvas.drawPath(rightArc, arcPaint);
    } else {
      // Big expressive round eyes with dynamic blink scaling
      final eyeHeight = 12.0 * blinkScale;
      final eyeWidth = 8.5;

      // Eye White Sclera
      final leftEyeRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftEyeCenter, width: eyeWidth * 2, height: eyeHeight * 2),
        Radius.circular(eyeWidth),
      );
      final rightEyeRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: rightEyeCenter, width: eyeWidth * 2, height: eyeHeight * 2),
        Radius.circular(eyeWidth),
      );

      final eyeWhitePaint = Paint()..color = Colors.white;
      canvas.drawRRect(leftEyeRRect, eyeWhitePaint);
      canvas.drawRRect(rightEyeRRect, eyeWhitePaint);

      // Pupils with gaze tracking
      if (blinkScale > 0.3) {
        final pupilPaint = Paint()..color = const Color(0xFF0F172A);
        final pupilRadius = 4.2;

        final leftPupilPos = Offset(leftEyeCenter.dx + gazeX, leftEyeCenter.dy + gazeY);
        final rightPupilPos = Offset(rightEyeCenter.dx + gazeX, rightEyeCenter.dy + gazeY);

        canvas.drawCircle(leftPupilPos, pupilRadius, pupilPaint);
        canvas.drawCircle(rightPupilPos, pupilRadius, pupilPaint);

        // Specular glint in pupils
        final glintPaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(leftPupilPos.dx - 1.5, leftPupilPos.dy - 1.5), 1.5, glintPaint);
        canvas.drawCircle(Offset(rightPupilPos.dx - 1.5, rightPupilPos.dy - 1.5), 1.5, glintPaint);
      }
    }

    // Cheerful Rosy Cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFF6B6B).withValues(alpha: 0.45);
    canvas.drawCircle(Offset(leftEyeCenter.dx - 8, eyeY + 12), 4.5, cheekPaint);
    canvas.drawCircle(Offset(rightEyeCenter.dx + 8, eyeY + 12), 4.5, cheekPaint);

    // Warm Smile
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    if (mood == MascotMood.thinking) {
      // Curious 'O' or questioning smirk
      mouthPath.moveTo(center.dx - 3, center.dy + 12);
      mouthPath.quadraticBezierTo(center.dx + 4, center.dy + 10, center.dx + 6, center.dy + 14);
    } else {
      mouthPath.moveTo(center.dx - 6, center.dy + 12);
      mouthPath.quadraticBezierTo(center.dx, center.dy + 17, center.dx + 6, center.dy + 12);
    }
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _LinoMascotPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.blinkScale != blinkScale ||
        oldDelegate.waveAngle != waveAngle ||
        oldDelegate.shineProgress != shineProgress ||
        oldDelegate.gazeOffset != gazeOffset;
  }
}

class _SpecularSweepPainter extends CustomPainter {
  final double progress;

  _SpecularSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < -0.8 || progress > 1.8) return;

    final w = size.width;
    final h = size.height;
    final shineWidth = w * 0.40;
    final currentX = w * progress;

    final path = Path()
      ..moveTo(currentX - shineWidth, -10)
      ..lineTo(currentX, -10)
      ..lineTo(currentX + shineWidth - 20, h + 10)
      ..lineTo(currentX - 20, h + 10)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(currentX - shineWidth, 0, shineWidth * 2, h));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpecularSweepPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
