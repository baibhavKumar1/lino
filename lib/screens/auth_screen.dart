import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/tactile_tap.dart';
import '../widgets/lino_logo.dart';
import '../widgets/google_logo.dart';
import '../widgets/interactive_mascot.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _currentStage = 0; // 0: Stage 1, 1: Stage 2, 2: Stage 3 (Auth)
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  MascotMood _mascotMood = MascotMood.celebrating;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_handleFocusChange);
    _passwordFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      if (_passwordFocusNode.hasFocus) {
        _mascotMood = MascotMood.peekaboo;
      } else if (_emailFocusNode.hasFocus) {
        _mascotMood = MascotMood.curious;
      } else {
        _mascotMood = _currentStage == 1
            ? MascotMood.curious
            : (_currentStage == 2 ? MascotMood.celebrating : MascotMood.waving);
      }
    });
  }

  void _goToStage(int index) {
    if (index >= 0 && index <= 2) {
      setState(() {
        _currentStage = index;
        if (!_emailFocusNode.hasFocus && !_passwordFocusNode.hasFocus) {
          _mascotMood = index == 1
              ? MascotMood.curious
              : (index == 2 ? MascotMood.celebrating : MascotMood.waving);
        }
      });
    }
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_handleFocusChange);
    _passwordFocusNode.removeListener(_handleFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUnifiedAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await AuthService.continueWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result.isSuccess) {
        if (result.isNewUser) {
          Navigator.pushReplacementNamed(context, '/onboarding', arguments: {
            'googleEmail': result.email,
            'googleName': result.fullName,
            'googlePhotoUrl': result.photoUrl,
          });
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Authentication failed. Please check your details.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.signInWithGoogle();
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result.isSuccess) {
        if (result.isNewUser) {
          Navigator.pushReplacementNamed(context, '/onboarding', arguments: {
            'googleEmail': result.email,
            'googleName': result.fullName,
            'googlePhotoUrl': result.photoUrl,
          });
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Google Sign-In was canceled'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        /* PREVIOUS HARDCODED COLOR - COMMENTED OUT AS PER RULE
        backgroundColor: const Color(0xFF60ACFC),
        */
        backgroundColor: AppColors.authBackground,
        body: Container(
          /* PREVIOUS HARDCODED GRADIENT - COMMENTED OUT AS PER RULE
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8CD4FE), Color(0xFF5BA6F6)],
            ),
          ),
          */
          decoration: const BoxDecoration(
            gradient: AppGradients.authSky,
          ),
          child: SafeArea(
            top: true,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  // physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Hero Header & Centered Mascot (Larger Hero Presentation)
                          Container(
                            padding: const EdgeInsets.only(top: 12, bottom: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Center(
                                  child: LinoWordmark(
                                    height: 28,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: screenHeight * 0.28,
                                  child: Center(
                                    child: InteractiveMascot(
                                      size: 195,
                                      mood: _mascotMood,
                                      enableTapReaction: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Curved White Bottom Sheet with Overlapping Center Badge
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              fit: StackFit.expand,
                              alignment: Alignment.topCenter,
                              children: [
                                /* PREVIOUS DUAL-LAYER POSITIONED BACKDROP - COMMENTED OUT AS PER RULE
                                Positioned(
                                  top: 34,
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.elliptical(constraints.maxWidth / 2, 48.0),
                                      ),
                                    ),
                                  ),
                                ),
                                */

                                // Direct White Bottom Sheet Container (Stretches 100% flush to bottom edge)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 34),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.elliptical(constraints.maxWidth / 2, 48.0),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x180F172A),
                                        offset: Offset(0, -6),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: SafeArea(
                                    top: false,
                                    bottom: true,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(26, 44, 26, 24),
                                      child: _buildAuthCard(),
                                    ),
                                  ),
                                ),

                                // Overlapping Center Badge (Enlarged & Mathematically Centered on Dome Apex)
                                Positioned(
                                  top: 0,
                                  child: Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0F172A).withValues(alpha: 0.32),
                                          offset: const Offset(0, 8),
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: LinoVectorMark(
                                        width: 44,
                                        height: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // UNIFIED AUTHENTICATION CARD (EMAIL + PASSWORD + GOOGLE)
  // ===========================================================================
  Widget _buildAuthCard() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'For Smart Kitchens',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.5,
              wordSpacing: 1.8,
              height: 1.50,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Buy, manage, and cook, all in one place.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w400,
              height: 1.35,
              wordSpacing: 1.0,
              color: const Color(0xFF64748B),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
              wordSpacing: 0.8,
            ),
            decoration: _inputDecoration(
              label: 'Email Address',
              hint: 'you@example.com',
              icon: Icons.alternate_email_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter your email';
              if (!value.contains('@') || !value.contains('.')) return 'Please enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
              wordSpacing: 0.8,
            ),
            decoration: _inputDecoration(
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 16,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a password';
              if (value.length < 4) return 'Password must be at least 4 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildPrimaryButton(
            title: 'Get Started',
            isLoading: _isLoading,
            onTap: _isLoading ? null : _handleUnifiedAuth,
          ),
          const SizedBox(height: 8),
          TactileTap(
            onTap: _isLoading ? null : _handleGoogleSignIn,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleLogo(size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                      wordSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({required String title, VoidCallback? onTap, bool isLoading = false}) {
    return TactileTap(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.25),
              offset: const Offset(0, 5),
              blurRadius: 16,
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                      wordSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12, wordSpacing: 0.8),
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12, wordSpacing: 0.8),
      prefixIcon: Icon(icon, color: const Color(0xFF3B82F6), size: 16),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
    );
  }
}
