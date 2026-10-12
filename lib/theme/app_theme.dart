import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ===========================================================================
  // PALETTE OPTION 1: DEEP AEGEAN NAVY & ELECTRIC AZURE (ACTIVE DEFAULT)
  // Sophisticated, editorial, premium contrast with high-energy azure accent.
  // ===========================================================================
  // static const Color primary = Color(0xFF0A2540);
  // static const Color primaryDark = Color(0xFF051626);
  // static const Color primaryLight = Color(0xFFE8F1FB);
  // static const Color primarySubtle = Color(0xFFF2F7FD);

  // static const Color background = Color(0xFFFBFBFA);
  // static const Color surface = Color(0xFFFFFFFF);
  // static const Color surfaceMuted = Color(0xFFF3F2EE);
  // static const Color surfaceElevated = Color(0xFFFFFFFF);

  // static const Color textPrimary = Color(0xFF0A192F);
  // static const Color textSecondary = Color(0xFF4A5568);
  // static const Color textMuted = Color(0xFF8C9BAE);
  // static const Color textWhite = Color(0xFFFFFFFF);

  // static const Color border = Color(0xFFE2E8F0);
  // static const Color borderLight = Color(0xFFEEF2F6);
  // static const Color borderDark = Color(0xFFCBD5E1);

  // // Spotlight Accents & Action Highlights
  // static const Color accentBlue = Color(0xFF0066FF);
  // static const Color accentBlueLight = Color(0xFFE0ECFF);
  // static const Color accentIndigo = Color(0xFF4F46E5);
  // static const Color accentCoral = Color(0xFFFF6B6B);
  // static const Color accentCoralText = Color(0xFFE04848);

  // // Status & Feedback Colors
  // static const Color danger = Color(0xFFEF4444);
  // static const Color dangerDark = Color(0xFFDC2626);
  // static const Color dangerLight = Color(0xFFFEE2E2);
  // static const Color dangerSubtle = Color(0xFFFFF1F2);

  // static const Color warning = Color(0xFFF59E0B);
  // static const Color warningDark = Color(0xFFD97706);
  // static const Color warningLight = Color(0xFFFEF3F2);

  // static const Color success = Color(0xFF10B981);
  // static const Color successLight = Color(0xFFDCFCE7);

  
  
  /*
  // ===========================================================================
  // PALETTE OPTION 2: VIBRANT COBALT & ROYAL SAPPHIRE (PRESET)
  // High clarity, modern tech-forward cobalt blue with warm white ground.
  // ===========================================================================
  static const Color primary = Color(0xFF1E40AF);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color primarySubtle = Color(0xFFF5F7FF);

  static const Color background = Color(0xFFFAFAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F3F9);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFFCBD5E1);

  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentBlueLight = Color(0xFFDBEAFE);
  */

  // ===========================================================================
  // PALETTE OPTION 3: NORDIC SLATE & MEDITERRANEAN AZURE (ACTIVE)
  // Calm, architectural, refined deep slate with warm ivory ground.
  // ===========================================================================
  static const Color primary = Color(0xFF1E293B);
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFFE0F2FE);
  static const Color primarySubtle = Color(0xFFF0F9FF);

  static const Color background = Color(0xFFFDFBF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4F1EA);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF525E75);
  static const Color textMuted = Color(0xFF8D99AE);
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE2E0D8);
  static const Color borderLight = Color(0xFFEFECE5);
  static const Color borderDark = Color(0xFFCBC7BC);

  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentBlueLight = Color(0xFFDBEAFE);
  static const Color accentIndigo = Color(0xFF4F46E5);
  static const Color accentCoral = Color(0xFFFF6B6B);
  static const Color accentCoralText = Color(0xFFE04848);

  // Status & Feedback Colors
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color dangerSubtle = Color(0xFFFFF1F2);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3F2);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFDCFCE7);

  // Hero & Authentication Sky Theme Palette
  static const Color authSkyTop = Color.fromARGB(255, 61, 57, 139);
  static const Color authSkyBottom = Color(0xFF5BA6F6);
  static const Color authBackground = Color(0xFF60ACFC);

  /*
  // ===========================================================================
  // PALETTE OPTION 4: MIDNIGHT CYAN & RICH CERULEAN (PRESET)
  // Deep ocean contrast, contemporary clean lines, crisp pearl surfaces.
  // ===========================================================================
  static const Color primary = Color(0xFF0B192C);
  static const Color primaryDark = Color(0xFF060E18);
  static const Color primaryLight = Color(0xFFE0F4FF);
  static const Color primarySubtle = Color(0xFFF0F9FF);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF1F6);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0B192C);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);

  static const Color accentBlue = Color(0xFF0077B6);
  static const Color accentBlueLight = Color(0xFFCAF0F8);
  */

  /*
  // ===========================================================================
  // PREVIOUS BOTANICAL MINT / GREEN PALETTE (PRESERVED)
  // ===========================================================================
  static const Color primaryMint = Color(0xFF00A86B);
  static const Color primaryDarkMint = Color(0xFF00754A);
  static const Color primaryLightMint = Color(0xFFE6F7F0);
  static const Color primarySubtleMint = Color(0xFFF0FDF4);
  */
}

class AppGradients {
  // Option 3 Gradient (Nordic Slate to Mediterranean Azure)
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Authentication & Onboarding Sky Gradient
  static const LinearGradient authSky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.authSkyTop, AppColors.authSkyBottom],
  );

  /*
  // Option 1 Gradient (Deep Aegean to Navy Steel)
  static const LinearGradient primaryAegean = LinearGradient(
    colors: [Color(0xFF0A2540), Color(0xFF0066FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Option 2 Gradient (Vibrant Cobalt to Sapphire)
  static const LinearGradient primaryCobalt = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Option 4 Gradient (Midnight to Cerulean)
  static const LinearGradient primaryMidnight = LinearGradient(
    colors: [Color(0xFF0B192C), Color(0xFF0077B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  */

  static const LinearGradient warm = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coral = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFE04848)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppDateUtils {
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const List<String> _shortWeekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  static String formatMonthYear(DateTime date) {
    final m = (date.month >= 1 && date.month <= 12) ? _months[date.month - 1] : 'Month';
    return '$m ${date.year}';
  }

  static String formatFullDate(DateTime date) {
    final w = (date.weekday >= 1 && date.weekday <= 7) ? _weekdays[date.weekday - 1] : 'Day';
    final m = (date.month >= 1 && date.month <= 12) ? _shortMonths[date.month - 1] : 'M';
    return '$w, $m ${date.day}';
  }

  static String formatShortDate(DateTime date) {
    final w = (date.weekday >= 1 && date.weekday <= 7) ? _shortWeekdays[date.weekday - 1] : 'Day';
    final m = (date.month >= 1 && date.month <= 12) ? _shortMonths[date.month - 1] : 'M';
    return '$w, $m ${date.day}';
  }

  static String formatShortWeekday(DateTime date) {
    final w = (date.weekday >= 1 && date.weekday <= 7) ? _shortWeekdays[date.weekday - 1] : 'D';
    return w.toUpperCase();
  }
}

class AppRadii {
  static const Radius sm = Radius.circular(8);
  static const Radius md = Radius.circular(12);
  static const Radius lg = Radius.circular(16);
  static const Radius xl = Radius.circular(20);
  static const Radius xxl = Radius.circular(24);

  static const BorderRadius smBorder = BorderRadius.all(sm);
  static const BorderRadius mdBorder = BorderRadius.all(md);
  static const BorderRadius lgBorder = BorderRadius.all(lg);
  static const BorderRadius xlBorder = BorderRadius.all(xl);
  static const BorderRadius xxlBorder = BorderRadius.all(xxl);
}

class AppShadows {
  /* PREVIOUS SINGLE-LAYER SHADOWS - COMMENTED OUT AS PER RULE
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> modal = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, -6),
    ),
  ];
  */

  // ===========================================================================
  // BEAUTIFUL SHADOWS SYSTEM (Exact multi-layer neutral elevations)
  // ===========================================================================

  /// Beautiful sm: 3-layer refined neutral elevation for compact cards, pills,
  /// form controls, action buttons, and quiet surfaces.
  static final List<BoxShadow> sm = [
    const BoxShadow(
      color: Color(0x1A000000), // rgba(0,0,0,0.10)
      offset: Offset(0, 2),
      blurRadius: 3,
      spreadRadius: -1,
    ),
    const BoxShadow(
      color: Color(0x05191C21), // rgba(25,28,33,0.02)
      offset: Offset(0, 1),
      blurRadius: 0,
      spreadRadius: 0,
    ),
    const BoxShadow(
      color: Color(0x14191C21), // rgba(25,28,33,0.08)
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
    ),
  ];

  /// Beautiful md: 6-layer smooth natural ambient diffusion for standard cards,
  /// panels, popovers, and default elevated surface styles.
  static final List<BoxShadow> md = [
    const BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
    ),
    const BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      offset: Offset(0, 1),
      blurRadius: 1,
      spreadRadius: -0.5,
    ),
    const BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      offset: Offset(0, 3),
      blurRadius: 3,
      spreadRadius: -1.5,
    ),
    const BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      offset: Offset(0, 6),
      blurRadius: 6,
      spreadRadius: -3,
    ),
    const BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      offset: Offset(0, 12),
      blurRadius: 12,
      spreadRadius: -6,
    ),
    const BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      offset: Offset(0, 24),
      blurRadius: 24,
      spreadRadius: -12,
    ),
  ];

  /// Beautiful lg: 6-layer silky realistic depth for hero media, feature callouts,
  /// modal-like containers, floating docks, and strongest lift.
  static final List<BoxShadow> lg = [
    const BoxShadow(
      color: Color(0x09000000), // rgba(0,0,0,0.034)
      offset: Offset(0, 2.8),
      blurRadius: 2.2,
    ),
    const BoxShadow(
      color: Color(0x0C000000), // rgba(0,0,0,0.048)
      offset: Offset(0, 6.7),
      blurRadius: 5.3,
    ),
    const BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.060)
      offset: Offset(0, 12.5),
      blurRadius: 10.0,
    ),
    const BoxShadow(
      color: Color(0x12000000), // rgba(0,0,0,0.072)
      offset: Offset(0, 22.3),
      blurRadius: 17.9,
    ),
    const BoxShadow(
      color: Color(0x16000000), // rgba(0,0,0,0.086)
      offset: Offset(0, 41.8),
      blurRadius: 33.4,
    ),
    const BoxShadow(
      color: Color(0x1F000000), // rgba(0,0,0,0.120)
      offset: Offset(0, 100.0),
      blurRadius: 80.0,
    ),
  ];

  // Backward-compatible semantic aliases
  static List<BoxShadow> get soft => sm;
  static List<BoxShadow> get card => md;
  static List<BoxShadow> get modal => lg;
}

class AppTypography {
  /* PREVIOUS TYPOGRAPHY (FRAUNCES & PLUS JAKARTA SANS) - COMMENTED OUT AS PER RULE
  static TextStyle displayLarge({Color? color, double? fontSize}) => GoogleFonts.fraunces(
        fontSize: fontSize ?? 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle displayMedium({Color? color, double? fontSize}) => GoogleFonts.fraunces(
        fontSize: fontSize ?? 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle displaySmall({Color? color, double? fontSize}) => GoogleFonts.fraunces(
        fontSize: fontSize ?? 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: fontWeight ?? FontWeight.w500,
        letterSpacing: -0.1,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: fontWeight ?? FontWeight.w500,
        letterSpacing: 0.0,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: fontWeight ?? FontWeight.w500,
        letterSpacing: 0.2,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle label({Color? color, FontWeight? fontWeight, double? letterSpacing}) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: fontWeight ?? FontWeight.w700,
        letterSpacing: letterSpacing ?? 0.6,
        color: color ?? AppColors.textSecondary,
      );
  */

  // ===========================================================================
  // UNIFIED POPPINS TYPOGRAPHY SYSTEM
  // Clean geometric forms, modern proportions, and balanced optical weights
  // ===========================================================================
  static TextStyle displayLarge({Color? color, double? fontSize}) => GoogleFonts.poppins(
        fontSize: fontSize ?? 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle displayMedium({Color? color, double? fontSize}) => GoogleFonts.poppins(
        fontSize: fontSize ?? 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle displaySmall({Color? color, double? fontSize}) => GoogleFonts.poppins(
        fontSize: fontSize ?? 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color ?? AppColors.textPrimary,
      );

  // Body & UI (Poppins)
  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: fontWeight ?? FontWeight.w500,
        letterSpacing: -0.1,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: fontWeight ?? FontWeight.w500,
        letterSpacing: 0.0,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: fontWeight ?? FontWeight.w400,
        letterSpacing: 0.1,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle label({Color? color, FontWeight? fontWeight, double? letterSpacing}) => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: letterSpacing ?? 0.4,
        color: color ?? AppColors.textSecondary,
      );
}

class AppTheme {
  static ThemeData get lightTheme {
    /* PREVIOUS TEXT THEME (PLUS JAKARTA SANS BASE) - COMMENTED OUT AS PER RULE
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    */

    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    final customTextTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: AppColors.textMuted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.warning,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: customTextTheme,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdBorder),
          textStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
