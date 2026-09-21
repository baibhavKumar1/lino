import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/animated_3d_mascot_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Increased duration slightly to enjoy 3D mascot shine & float animation
    await Future.delayed(const Duration(milliseconds: 2800));
    final loggedIn = await AuthService.isLoggedIn();
    if (mounted) {
      if (loggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3D Animated List-Ribbon Mascot Widget with Shining Sweep & Sparkles
              const Animated3DMascotWidget(
                width: 220,
                height: 240,
              )
                  .animate()
                  .scale(
                    duration: 700.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 24),

              // Title: KICHOOK in warm Fraunces
              Text(
                'KICHOOK',
                style: GoogleFonts.fraunces(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: const Color(0xFF0F172A),
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

              const SizedBox(height: 6),

              Text(
                'Smart Grocery Shopping, Simplified',
                /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                style: GoogleFonts.funnelDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF059669),
                  letterSpacing: 0.3,
                ),
                */
                style: const TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF059669),
                  letterSpacing: 0.3,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms),

              const SizedBox(height: 40),

              // Loading indicator
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
