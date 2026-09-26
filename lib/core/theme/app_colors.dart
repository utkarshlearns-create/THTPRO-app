import 'package:flutter/material.dart';

/// THT brand colors — derived from the Next.js frontend's CSS variables and
/// Tailwind config. The primary orange (#E1702E) is the hero color used across
/// buttons, active nav, and accent surfaces.
abstract final class AppColors {
  // ── Brand ──
  static const Color primaryOrange = Color(0xFFE1702E);
  static const Color primaryOrangeDark = Color(0xFFD45E1C);
  static const Color primaryOrangeLight = Color(0xFFFFF7ED); // orange-50
  static const Color primaryBlue = Color(0xFF3B82F6); // blue-500

  // ── Parent blue ──
  //
  // The action colour on parent surfaces. Note this is blue-600, not the
  // blue-500 above: white on #3B82F6 measures 3.68:1, which fails WCAG AA for
  // the 15px semibold label the button theme sets. #2563EB measures 5.17:1.
  static const Color primaryBlueDark = Color(0xFF2563EB); // blue-600
  static const Color primaryBlueDeep = Color(0xFF1D4ED8); // blue-700

  // ── Neutrals (Slate palette, matching Tailwind slate) ──
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // ── Semantic ──
  static const Color success = Color(0xFF10B981);  // emerald-500
  static const Color successBg = Color(0xFFECFDF5); // emerald-50
  static const Color warning = Color(0xFFF59E0B);  // amber-500
  static const Color warningBg = Color(0xFFFFFBEB); // amber-50
  static const Color error = Color(0xFFEF4444);    // red-500
  static const Color errorBg = Color(0xFFFEF2F2);  // red-50
  static const Color info = Color(0xFF3B82F6);     // blue-500
  static const Color infoBg = Color(0xFFEFF6FF);   // blue-50

  // ── Accent tints (used for badges, stat cards, etc.) ──
  static const Color violet = Color(0xFF8B5CF6);
  static const Color sky = Color(0xFF0EA5E9);
  static const Color rose = Color(0xFFF43F5E);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);

  // ── Dark mode surfaces ──
  static const Color darkSurface = Color(0xFF0F172A);     // slate-900
  static const Color darkCard = Color(0xFF1E293B);        // slate-800
  static const Color darkBorder = Color(0xFF334155);      // slate-700
  static const Color darkElevated = Color(0xFF1E293B);

  // ── Brand on dark ──
  //
  // #E1702E is the action colour, but as *type* on a slate-800 card it measures
  // 3.1:1 and fails AA. Orange-400 is the same family two steps lighter and
  // clears it, which is why every orange label on a dark surface uses this and
  // not the brand value itself.
  static const Color primaryOrangeOnDark = Color(0xFFFB923C); // orange-400

  /// The brand orange where it has to carry text.
  ///
  /// White on #E1702E measures 3.20:1 — exactly the failure [primaryBlue] had,
  /// in exactly the same place: the 15px semibold label the button theme sets,
  /// which WCAG treats as body text and holds to 4.5:1. Orange-700 measures
  /// 5.18:1 on white and 4.88:1 on the orange-50 chip tint, and white on it is
  /// 5.18:1 again.
  ///
  /// [primaryOrange] stays the brand value — icons, hairlines, borders, glows,
  /// decorative fills, the splash. This is the one that gets white text on it
  /// or is set as small type. The pair is the same arrangement as
  /// [primaryBlue] / [primaryBlueDark], for the same reason.
  static const Color primaryOrangeAction = Color(0xFFC2410C); // orange-700

  /// The parent blue as small type on a dark surface, matching
  /// [primaryOrangeOnDark]. [primaryBlueDark] on the dark card measures
  /// 2.83:1 — unreadable as type — where blue-300 measures 8.11:1.
  static const Color primaryBlueOnDark = Color(0xFF93C5FD); // blue-300

  /// Red-500 as type on a slate-800 card measures 3.4:1. Red-400 clears AA and
  /// stays unmistakably an error colour.
  static const Color errorOnDark = Color(0xFFF87171); // red-400

  // ── Warm surfaces ──
  //
  // The orange-tinted fills the auth screens and the quick-access panel sit on.
  // They live here rather than beside the widgets that use them because they are
  // brand values: three screens were each carrying their own slightly different
  // idea of "a warm off-white", and nothing kept them in step.
  static const Color warmTint = Color(0xFFFBE4D2);      // orange-100-ish disc fill
  static const Color warmTintDark = Color(0xFF3A2416);  // its dark counterpart
  static const Color warmVeil = Color(0xFFFDF4EC);      // a ring or hairline on white
  static const Color warmWash = Color(0xFFFFF6EE);      // a panel fill on white

  // ── Auth canvas ──
  //
  // The wash behind login and signup, and the two soft blooms floating in it.
  // The dark top stop is deliberately warm rather than the neutral slate-950
  // below it, so the gradient reads as light falling on the screen.
  static const Color authWashDark = Color(0xFF15121B);
  static const Color authWashWarm = Color(0xFFFCF0E6);
  static const Color authWashWarmMid = Color(0xFFFFF9F5);
  static const Color authWashWarmFaint = Color(0xFFFFFDFC);
  static const Color authBloomCool = Color(0xFFF3F8FF);
  static const Color authBloomWarm = Color(0xFFFFF9ED);

  /// The signup headings. A deep navy rather than slate-900: it is the one place
  /// in the app that sets display type over a tinted canvas, and pure slate read
  /// as grey against it.
  static const Color authHeading = Color(0xFF131D42);
}

/// Spacing constants following a 4px grid.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;
}

/// Border radius tokens.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;
}
