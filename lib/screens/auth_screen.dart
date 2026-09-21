import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/tactile_tap.dart';
import '../widgets/kichook_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
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

  // /* MOCK DEVELOPMENT LOGIC - COMMENTED OUT FOR PRODUCTION
  // void _showQuickLoginSheet(String reason) { ... }
  // */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Branding Header
                  /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 52,
                      height: 52,
                      errorBuilder: (_, __, ___) => const Icon(Icons.kitchen_rounded, color: AppColors.primary, size: 38),
                    ),
                  ),
                  */
                  const KichookLogo(
                    size: 72,
                    elevation: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kichook',
                    style: AppTypography.displayLarge(fontSize: 28),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Zero-Waste Smart Kitchen & Meal Planner',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // UNIFIED AUTH CARD
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.xlBorder,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Get Started',
                          style: AppTypography.displaySmall(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Enter your email to sign in or create your kitchen profile',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: 20),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'you@example.com',
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 18),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: const OutlineInputBorder(
                              borderRadius: AppRadii.mdBorder,
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: AppRadii.mdBorder,
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: const OutlineInputBorder(
                              borderRadius: AppRadii.mdBorder,
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: AppRadii.mdBorder,
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 4) {
                              return 'Password must be at least 4 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // SINGLE PROMINENT CONTINUE BUTTON (Tactile Spring scale 0.96)
                        TactileTap(
                          onTap: _isLoading ? null : _handleUnifiedAuth,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppRadii.mdBorder,
                              boxShadow: AppShadows.soft,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'CONTINUE',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Divider OR
                        Row(
                          children: const [
                            Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Google Sign-In Button
                        TactileTap(
                          onTap: _isLoading ? null : _handleGoogleSignIn,
                          child: Container(
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadii.mdBorder,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.g_mobiledata_rounded, size: 24, color: Color(0xFFEA4335)),
                                SizedBox(width: 6),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // const SizedBox(height: 20),
                  // // Quick Demo Chef Access (Commented out for production)
                  // TextButton.icon(
                  //   onPressed: () => _showQuickLoginSheet('Developer & Testing Mode'),
                  //   icon: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.textSecondary),
                  //   label: const Text(
                  //     '1-Tap Quick Chef Sign-In',
                  //     style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
