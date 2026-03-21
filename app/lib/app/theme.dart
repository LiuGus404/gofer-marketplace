import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand — Claude-like aesthetics
  static const primary = Color(0xFF1E1E1E); // Deep charcoal
  static const primaryDark = Color(0xFF000000);
  static const primaryLight = Color(0xFF4A4A4A);
  static const accent = Color(0xFFD4BFA7); // Warm beige/gold touch
  static const accentLight = Color(0xFFEBE0D3);
  static const accentMuted = Color(0xFFF5EFE8);

  // Backgrounds - Off-white paper feel
  static const background = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF6B6B70);
  static const textMuted = Color(0xFFA1A1A6);

  // Status
  static const online = Color(0xFF34C759);
  static const offline = Color(0xFFA1A1A6);
  static const busy = Color(0xFFFF9500);
  static const error = Color(0xFFFF3B30);

  // Legacy aliases — keep existing screens compiling
  static const coral = accent;
  static const coralLight = accentLight;
  static const coralMuted = accentMuted;
  static const brown = Color(0xFF1C1C1E);
  static const brownLight = Color(0xFF6B6B70);
  static const brownDark = Color(0xFF000000);
}

class AppTheme {
  // Default text theme with Inter
  static TextTheme get _baseTextTheme => GoogleFonts.interTextTheme();

  // Headings with Newsreader (serif)
  static TextStyle get _headingStyle => GoogleFonts.newsreader(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          onSecondary: AppColors.textPrimary,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: _baseTextTheme.copyWith(
          displayLarge: _headingStyle.copyWith(
            fontSize: 32,
            letterSpacing: -0.5,
          ),
          titleLarge: _headingStyle.copyWith(
            fontSize: 22,
          ),
          titleMedium: _baseTextTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          bodyLarge: _baseTextTheme.bodyLarge?.copyWith(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          bodyMedium: _baseTextTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          labelLarge: _baseTextTheme.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background.withOpacity(0.8),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: _headingStyle.copyWith(
            fontSize: 22,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.textMuted.withOpacity(0.1)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface.withOpacity(0.9),
          indicatorColor: AppColors.accentMuted,
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              );
            }
            return GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 24);
            }
            return const IconThemeData(color: AppColors.textMuted, size: 24);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
          ),
          labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.accentMuted,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide.none,
        ),
      );

  // Keep darkTheme as alias for now
  static ThemeData get darkTheme => lightTheme;
}

/// Reusable warm card shadow decoration
BoxDecoration warmCardDecoration({double radius = 16}) => BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: AppColors.brownDark.withOpacity(0.03),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
