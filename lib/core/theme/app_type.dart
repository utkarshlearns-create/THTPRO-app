import 'package:flutter/material.dart';

/// The app's type scale: ten sizes, and nothing in between.
///
/// Before this file the app set a font size 487 times across 33 different
/// values, fourteen of which sat inside the seven pixels between 11 and 18.
/// Nobody can see the difference between 12.5 and 13 on one screen; everybody
/// can feel it across forty-two of them, as a kind of blur where a hierarchy
/// should be. A scale is the fix: fewer sizes, each clearly apart from its
/// neighbours, so a heading reads as a heading rather than as slightly larger
/// body text.
///
/// The steps are named for the job, not the number, because the number is the
/// part that should be free to change. Sizes derived from a container — the
/// initials inside an avatar, say — are deliberately not on the scale: they
/// answer to their box, not to this hierarchy.
abstract final class ThtType {
  /// Badges, overlines, timestamps. Small enough that it must stay short.
  static const double micro = 10;

  /// Secondary and supporting text: metadata, helper lines, chip labels.
  static const double caption = 12;

  /// The workhorse. Most sentences in the app are this size.
  static const double body = 13;

  /// Body text that carries weight — button labels, a row's primary line.
  static const double bodyStrong = 14;

  /// The heading on a card or a sheet.
  static const double subtitle = 16;

  /// The heading on a section within a screen.
  static const double title = 18;

  /// The heading a screen is named by.
  static const double headline = 22;

  /// A number in a small tile, where several sit side by side.
  static const double display = 28;

  /// A number a card is built around.
  static const double figure = 34;

  /// The single number a whole screen exists to show — a score, a balance.
  static const double hero = 48;

  /// Every step, ascending.
  ///
  /// `test/core/type_scale_test.dart` reads this to prove the app uses these
  /// and only these, so the list is the scale's definition rather than a
  /// convenience copy of it.
  static const List<double> steps = <double>[
    micro,
    caption,
    body,
    bodyStrong,
    subtitle,
    title,
    headline,
    display,
    figure,
    hero,
  ];
}

/// Material's own text slots, expressed in the scale above.
///
/// Without this, `Theme.of(context).textTheme.headlineMedium` falls through to
/// Material's defaults — sized for Roboto and for a denser app than this one —
/// which is how four auth headings ended up at a size nobody chose. Colour is
/// deliberately left null so `ThemeData` still fills it per brightness.
TextTheme thtTextTheme() => const TextTheme(
      displayLarge: TextStyle(
          fontSize: ThtType.hero, fontWeight: FontWeight.w800, height: 1),
      displayMedium: TextStyle(
          fontSize: ThtType.figure, fontWeight: FontWeight.w800, height: 1),
      displaySmall: TextStyle(
          fontSize: ThtType.display, fontWeight: FontWeight.w800, height: 1.1),
      headlineLarge: TextStyle(
          fontSize: ThtType.display, fontWeight: FontWeight.w800, height: 1.15),
      headlineMedium: TextStyle(
          fontSize: ThtType.display, fontWeight: FontWeight.w800, height: 1.2),
      headlineSmall: TextStyle(
          fontSize: ThtType.headline, fontWeight: FontWeight.w800, height: 1.2),
      titleLarge: TextStyle(
          fontSize: ThtType.title, fontWeight: FontWeight.w700, height: 1.25),
      titleMedium: TextStyle(
          fontSize: ThtType.subtitle, fontWeight: FontWeight.w700, height: 1.3),
      titleSmall: TextStyle(
          fontSize: ThtType.bodyStrong,
          fontWeight: FontWeight.w600,
          height: 1.3),
      bodyLarge: TextStyle(
          fontSize: ThtType.bodyStrong,
          fontWeight: FontWeight.w500,
          height: 1.4),
      bodyMedium: TextStyle(
          fontSize: ThtType.body, fontWeight: FontWeight.w500, height: 1.45),
      bodySmall: TextStyle(
          fontSize: ThtType.caption, fontWeight: FontWeight.w500, height: 1.4),
      labelLarge: TextStyle(
          fontSize: ThtType.bodyStrong,
          fontWeight: FontWeight.w700,
          height: 1.2),
      labelMedium: TextStyle(
          fontSize: ThtType.caption, fontWeight: FontWeight.w600, height: 1.2),
      labelSmall: TextStyle(
          fontSize: ThtType.micro, fontWeight: FontWeight.w600, height: 1.2),
    );
