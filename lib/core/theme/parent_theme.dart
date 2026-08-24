import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme.dart';

/// The app, in blue, for signed-in parents.
///
/// Parents and teachers are two audiences sharing one binary, and the parent
/// side reads as a consumer product where the teacher side reads as a work
/// tool. Blue carries that difference without forking a screen.
///
/// It is applied at `MaterialApp.builder` keyed on the signed-in role rather
/// than wrapped around the parent shell, and that placement is the whole point:
/// `/post-requirement`, `/packages` and `/tutors/:id` are declared at the root
/// of the router, so a shell-level wrapper would drop back to orange the moment
/// a parent tapped "Post a requirement". The builder sits above the Navigator,
/// so it covers every route and every sheet and dialog pushed onto it.
///
/// Everything else — teachers, institutes, and anyone signed out — keeps the
/// orange [AppTheme] untouched.
abstract final class ParentTheme {
  /// Built once. `MaterialApp.builder` runs on every route change, and a
  /// `copyWith` over a full ThemeData on each of those is measurable.
  static final ThemeData light = _tint(AppTheme.light, Brightness.light);
  static final ThemeData dark = _tint(AppTheme.dark, Brightness.dark);

  /// Overrides only the places [AppTheme] hardcodes orange instead of reading
  /// from `colorScheme`. Anything that already resolves through the scheme —
  /// switches, sliders, progress indicators, text selection — follows from the
  /// `primary` override alone.
  static ThemeData _tint(ThemeData base, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const primary = AppColors.primaryBlueDark;

    return base.copyWith(
      // Reseeded from blue, not `copyWith(primary:)`. Material derives the
      // whole neutral ramp from the seed, so overriding `primary` alone left
      // every surface tone orange-tinted — most visibly on bottom sheets and
      // dialogs, which came up peach behind a blue form. The explicit values
      // below mirror what AppTheme pins so nothing else shifts.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        surface: base.colorScheme.surface,
        onSurface: base.colorScheme.onSurface,
        error: base.colorScheme.error,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          backgroundColor: const WidgetStatePropertyAll(primary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          foregroundColor: const WidgetStatePropertyAll(primary),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      bottomNavigationBarTheme:
          base.bottomNavigationBarTheme.copyWith(selectedItemColor: primary),
      chipTheme: base.chipTheme.copyWith(
        selectedColor:
            isDark ? primary.withValues(alpha: 0.22) : AppColors.infoBg,
        // The selected label and tick are orange in the base theme; without
        // these a selected chip on a parent screen kept a brand-orange tick.
        secondaryLabelStyle: base.chipTheme.secondaryLabelStyle?.copyWith(
          color: isDark ? const Color(0xFF93C5FD) : primary,
        ),
        checkmarkColor: isDark ? const Color(0xFF93C5FD) : primary,
      ),
    );
  }
}
