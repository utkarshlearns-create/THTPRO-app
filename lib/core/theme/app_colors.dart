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
