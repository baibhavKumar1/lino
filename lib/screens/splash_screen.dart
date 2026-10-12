import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/animated_3d_mascot_widget.dart';
import '../widgets/interactive_mascot.dart';
import '../widgets/lino_logo.dart';

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
    /* PREVIOUS SCAFFOLD - COMMENTED OUT AS PER RULE
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(...),
    );
    */
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Interactive Welcoming Mascot Widget with Eased Scale & FadeIn
              const InteractiveMascot(
                size: 160,
                mood: MascotMood.waving,
              )
                  .animate()
                  .scale(
                    duration: 700.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 500.ms),

              /* PREVIOUS 3D RIBBON LOGO - COMMENTED OUT AS PER RULE
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
              */

              const SizedBox(height: 20),

              // Official Lino Vector Wordmark
              const Center(
                child: LinoWordmark(
                  height: 32,
                  color: AppColors.primaryDark,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

              /* PREVIOUS PLAIN TEXT LINO - COMMENTED OUT AS PER RULE
              Text(
                'LINO',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4.0,
                  color: AppColors.textPrimary,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
              */

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
                /* PREVIOUS GREEN ACCENT - COMMENTED OUT AS PER RULE
                style: const TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF059669),
                  letterSpacing: 0.3,
                ),
                */
                /* PREVIOUS FUNNEL DISPLAY ACCENT - COMMENTED OUT AS PER RULE
                style: const TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                  letterSpacing: 0.3,
                ),
                */
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                  letterSpacing: 0.2,
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
                  /* PREVIOUS GREEN SPINNER - COMMENTED OUT AS PER RULE
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  */
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
