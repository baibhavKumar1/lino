import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Brand (Cobalt / Royal Blue #0F4DA2)
  /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFDCFCE7);
  static const Color primarySubtle = Color(0xFFF0FDF4);
  */
  static const Color primary = Color(0xFF0F4DA2);
  static const Color primaryDark = Color(0xFF0A3778);
  static const Color primaryLight = Color(0xFFE0ECFB);
  static const Color primarySubtle = Color(0xFFF0F6FE);

  // Background & Surfaces (Mineral Cotton Cardstock Gray & Warm Ivory)
  /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
  static const Color background = Color(0xFFFAF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4EFE8);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Typography & Text
  static const Color textPrimary = Color(0xFF1C1917); // Warm Stone-900
  static const Color textSecondary = Color(0xFF57534E); // Warm Stone-600
  static const Color textMuted = Color(0xFFA8A29E); // Warm Stone-400
  static const Color textWhite = Color(0xFFFFFFFF);

  // Borders & Dividers (Warm Stone & Parchment)
  static const Color border = Color(0xFFE7E0D8);
  static const Color borderLight = Color(0xFFF2ECE4);
  static const Color borderDark = Color(0xFFD6CCC2);
  */
  static const Color background = Color(0xFFE8E5DF);
  static const Color surface = Color(0xFFFAF8F5);
  static const Color surfaceMuted = Color(0xFFDFDACF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Typography & Text (Printer's Ink & Warm Stone)
  static const Color textPrimary = Color(0xFF141312);
  static const Color textSecondary = Color(0xFF5A5752);
  static const Color textMuted = Color(0xFF948F87);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Borders & Dividers (Cardstock Fiber)
  static const Color border = Color(0xFFD5CFBF);
  static const Color borderLight = Color(0xFFE0DDD5);
  static const Color borderDark = Color(0xFFC8C2B3);

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

  // Secondary Accents
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentBlueLight = Color(0xFFDBEAFE);
  static const Color accentIndigo = Color(0xFF4F46E5);
}

class AppGradients {
  /* PREVIOUS LOGIC - COMMENTED OUT AS PER RULE
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  */
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF0F4DA2), Color(0xFF0A3778)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warm = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
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
}

class AppTypography {
  // Apple Design Principle §15: Size-specific optical tracking
  // Large headings require subtle negative tracking (-0.02em / -0.5px)
  // Small UI labels require positive tracking (+0.4px to +0.8px) for legibility
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

  // Body & UI (Plus Jakarta Sans)
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
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    final customTextTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.fraunces(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.fraunces(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.textMuted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.warning,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: customTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
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
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
