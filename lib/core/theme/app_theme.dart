import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App-wide ThemeData for light and dark modes.
abstract final class AppTheme {
  /// Plus Jakarta Sans — the same face the website sets in `globals.css`.
  static const String fontFamily = 'PlusJakartaSans';

  /// Plus Jakarta Sans has no glyph for ₹ (U+20B9), and this app shows a fee or
  /// a balance on nearly every screen. Without a fallback the engine hunts for a
  /// Noto font it cannot find and draws tofu boxes where the money should be.
  /// These are the system faces that do carry the rupee sign on each platform.
  static const List<String> fontFallback = [
    'Roboto', // Android
    'SF Pro Text', // iOS / macOS
    'Segoe UI', // Windows
    'Noto Sans',
  ];

  /// The smallest a themed button or icon button is allowed to be.
  ///
  /// Material's defaults are under both platforms' published minimum — a text
  /// button is 36dp tall and an icon button is effectively the size of its own
  /// glyph box — which showed up most on the icon-only actions in an app bar.
  /// Stated once here so it holds everywhere instead of being remembered on each
  /// screen that happens to need it.
  static const double minTapTarget = 48;

  /// Radii and paddings below come from [AppRadius] and [AppSpacing], never
  /// from a literal. The tokens existed before this theme did and the theme
  /// wrote the numbers anyway, which is how a Card and a ThtCard could drift
  /// apart without anybody changing a card.
  ///
  /// The two brightnesses hold different orange values on purpose, and neither
  /// is [AppColors.primaryOrange]: light uses [AppColors.primaryOrangeAction]
  /// because white has to be readable on it, dark uses
  /// [AppColors.primaryOrangeOnDark] with slate900 on top because on a slate
  /// card the light orange is the readable one. The brand orange stays on
  /// borders, focus rings and decoration, where 3:1 is the bar it has to clear.

  // ── Light ──
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryOrange,
          brightness: Brightness.light,
          primary: AppColors.primaryOrangeAction,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.slate900,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.slate50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.slate900,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.slate200),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrangeAction,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
            minimumSize: const Size(0, minTapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.slate700,
            side: const BorderSide(color: AppColors.slate200),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
            minimumSize: const Size(0, minTapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryOrangeAction,
            textStyle: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.slate50,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.slate200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.slate200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.primaryOrange, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: const TextStyle(
            color: AppColors.slate400,
            fontSize: 14,
          ),
          labelStyle: const TextStyle(
            color: AppColors.slate500,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(minTapTarget, minTapTarget),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryOrangeAction,
          unselectedItemColor: AppColors.slate400,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.slate200,
          thickness: 1,
          space: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.slate100,
          selectedColor: AppColors.primaryOrangeLight,
          // Colours stated outright. Left to Material's defaults these resolved
          // to a grey close enough to the chip's own fill that the labels in
          // the requirement wizard were barely readable.
          labelStyle: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.slate700,
          ),
          secondaryLabelStyle: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryOrangeAction,
          ),
          checkmarkColor: AppColors.primaryOrangeAction,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.slate800,
          contentTextStyle: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: Colors.white,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ── Dark ──
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryOrange,
          brightness: Brightness.dark,
          primary: AppColors.primaryOrangeOnDark,
          onPrimary: AppColors.slate900,
          surface: AppColors.darkSurface,
          onSurface: AppColors.slate100,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.slate950,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkCard,
          foregroundColor: AppColors.slate100,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.slate100,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.darkBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrangeOnDark,
            foregroundColor: AppColors.slate900,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
            minimumSize: const Size(0, minTapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.slate300,
            side: const BorderSide(color: AppColors.darkBorder),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
            minimumSize: const Size(0, minTapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.primaryOrange, width: 2),
          ),
          hintStyle: const TextStyle(color: AppColors.slate500, fontSize: 14),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(minTapTarget, minTapTarget),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkCard,
          selectedItemColor: AppColors.primaryOrangeOnDark,
          unselectedItemColor: AppColors.slate500,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 1,
          space: 0,
        ),
        // Dark had no chip theme at all, so chips fell back to Material's
        // defaults and drifted away from the rest of the surface.
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.slate800,
          selectedColor: AppColors.primaryOrange.withValues(alpha: 0.22),
          labelStyle: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.slate200,
          ),
          secondaryLabelStyle: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryOrangeOnDark,
          ),
          checkmarkColor: AppColors.primaryOrangeOnDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.slate700,
          contentTextStyle: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: Colors.white,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
