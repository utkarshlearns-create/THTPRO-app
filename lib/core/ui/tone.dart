import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';

/// What a piece of state *means*, independent of the brand accent.
///
/// Orange is the brand, so it can't also carry "warning" — a pending KYC and a
/// primary button would read as the same thing. Semantic colour lives here and
/// stays separate from [AppColors.primaryOrange].
enum Tone { neutral, success, warning, critical, info, accent }

extension ToneColors on Tone {
  /// The colour of the text and icon.
  Color foreground(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (this) {
      case Tone.neutral:
        return dark ? AppColors.slate300 : AppColors.slate600;
      case Tone.success:
        return dark ? const Color(0xFF34D399) : const Color(0xFF047857);
      case Tone.warning:
        return dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      case Tone.critical:
        return dark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
      case Tone.info:
        return dark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
      case Tone.accent:
        return dark ? const Color(0xFFFB923C) : AppColors.primaryOrangeDark;
    }
  }

  /// The tinted surface behind it.
  Color background(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (this) {
      case Tone.neutral:
        return dark ? AppColors.slate800 : AppColors.slate100;
      case Tone.success:
        return dark ? const Color(0x2610B981) : AppColors.successBg;
      case Tone.warning:
        return dark ? const Color(0x26F59E0B) : AppColors.warningBg;
      case Tone.critical:
        return dark ? const Color(0x26EF4444) : AppColors.errorBg;
      case Tone.info:
        return dark ? const Color(0x263B82F6) : AppColors.infoBg;
      case Tone.accent:
        return dark ? const Color(0x26E1702E) : AppColors.primaryOrangeLight;
    }
  }

  /// A hairline that reads as the same family as the fill.
  Color border(Brightness brightness) =>
      foreground(brightness).withValues(alpha: brightness == Brightness.dark ? 0.35 : 0.22);
}

/// Maps a backend status string onto the tone it should be shown in.
///
/// Every list in the app leans on this, so a `HIRED` badge looks identical
/// whether it appears on a job card, an application row or a dashboard tile.
Tone toneForStatus(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case 'HIRED':
    case 'PAID':
    case 'APPROVED':
    case 'ACTIVE':
    case 'VERIFIED':
    case 'PRESENT':
    case 'COMPLETED':
      return Tone.success;
    case 'PENDING':
    case 'APPLIED':
    case 'ON_HOLD':
    case 'AWAITING':
    case 'UNPAID':
    case 'ONGOING':
    case 'RESCHEDULED':
      return Tone.warning;
    case 'REJECTED':
    case 'NOT_SELECTED':
    case 'CANCELLED':
    case 'ABSENT':
    case 'EXPIRED':
    case 'CLOSED':
      return Tone.critical;
    case 'DEMO':
    case 'SCHEDULED':
    case 'ACCEPTED':
      return Tone.info;
    default:
      return Tone.neutral;
  }
}
