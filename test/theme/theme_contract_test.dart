import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_theme.dart';
import 'package:tht_app/core/theme/parent_theme.dart';

/// The promises the design system makes, asserted rather than assumed.
///
/// Before this the app had four themes — light, dark, parent light, parent dark
/// — and not one test that looked at any of them. Three of the four are
/// unreachable on a light-mode phone with a teacher account, which is every
/// device a developer here actually runs, so a change that broke the dark chip
/// or reseeded a parent surface orange could ship and no suite would notice.
void main() {
  /// WCAG 2.1 relative luminance.
  double luminance(Color c) {
    double channel(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  double? cardRadius(ThemeData theme) {
    final shape = theme.cardTheme.shape;
    if (shape is! RoundedRectangleBorder) return null;
    final radius = shape.borderRadius;
    return radius is BorderRadius ? radius.topLeft.x : null;
  }

  double? buttonRadius(ThemeData theme) {
    final shape = theme.elevatedButtonTheme.style?.shape
        ?.resolve(const <WidgetState>{});
    if (shape is! RoundedRectangleBorder) return null;
    final radius = shape.borderRadius;
    return radius is BorderRadius ? radius.topLeft.x : null;
  }

  final themes = <String, ThemeData>{
    'light': AppTheme.light,
    'dark': AppTheme.dark,
    'parent light': ParentTheme.light,
    'parent dark': ParentTheme.dark,
  };

  group('radii come from the tokens, not from literals', () {
    themes.forEach((name, theme) {
      test('$name cards are AppRadius.lg and buttons AppRadius.md', () {
        expect(cardRadius(theme), AppRadius.lg,
            reason: '$name cards must match the website\'s rounded-2xl');
        expect(buttonRadius(theme), AppRadius.md,
            reason: '$name buttons must match rounded-xl');
      });
    });
  });

  group('tap targets clear 48dp', () {
    themes.forEach((name, theme) {
      test('$name buttons and icon buttons', () {
        final button = theme.elevatedButtonTheme.style?.minimumSize
            ?.resolve(const <WidgetState>{});
        expect(button, isNotNull, reason: '$name sets no minimum button size');
        expect(button!.height, greaterThanOrEqualTo(AppTheme.minTapTarget));

        final icon = theme.iconButtonTheme.style?.minimumSize
            ?.resolve(const <WidgetState>{});
        expect(icon, isNotNull, reason: '$name sets no minimum icon size');
        expect(icon!.width, greaterThanOrEqualTo(AppTheme.minTapTarget));
        expect(icon.height, greaterThanOrEqualTo(AppTheme.minTapTarget));
      });
    });
  });

  group('a label on a primary button is readable', () {
    // The button theme sets 15px semibold, which WCAG treats as body text and
    // holds to 4.5:1 — the exact reason the parent blue is blue-600 and not the
    // blue-500 sitting next to it in AppColors.
    themes.forEach((name, theme) {
      test('$name clears AA', () {
        final scheme = theme.colorScheme;
        expect(contrast(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5),
            reason: '$name: white on ${scheme.primary} is too faint');
      });
    });
  });

  group('every themed text colour is readable on its own surface', () {
    themes.forEach((name, theme) {
      test('$name body text on the card colour', () {
        final card = theme.cardTheme.color ?? theme.colorScheme.surface;
        expect(contrast(theme.colorScheme.onSurface, card),
            greaterThanOrEqualTo(4.5),
            reason: '$name onSurface on the card surface');
      });

      test('$name chip label on the chip fill', () {
        final chip = theme.chipTheme;
        final label = chip.labelStyle?.color;
        final fill = chip.backgroundColor;
        expect(label, isNotNull, reason: '$name states no chip label colour');
        expect(fill, isNotNull, reason: '$name states no chip fill');
        // The requirement wizard is wall-to-wall chips; Material's default grey
        // label on these fills was what made it unreadable in the first place.
        expect(contrast(label!, fill!), greaterThanOrEqualTo(4.5),
            reason: '$name chip label on its own fill');
      });

      test('$name selected chip label on the selected fill', () {
        final chip = theme.chipTheme;
        final label = chip.secondaryLabelStyle?.color;
        var fill = chip.selectedColor;
        expect(label, isNotNull);
        expect(fill, isNotNull);
        // The dark selected fill is translucent, so it is the card behind it
        // that the label is actually read against.
        if (fill!.a < 1) {
          fill = Color.alphaBlend(
            fill,
            theme.cardTheme.color ?? theme.colorScheme.surface,
          );
        }
        expect(contrast(label!, fill), greaterThanOrEqualTo(4.5),
            reason: '$name selected chip label on its fill');
      });
    });
  });

  group('dark is a real second theme, not an inverted first', () {
    test('it uses the slate surfaces rather than Material defaults', () {
      expect(AppTheme.dark.colorScheme.surface, AppColors.darkSurface);
      expect(AppTheme.dark.cardTheme.color, AppColors.darkCard);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.slate950);
      expect(AppTheme.dark.dividerTheme.color, AppColors.darkBorder);
    });

    test('it carries its own chip theme', () {
      // Dark had none at all once, so chips fell back to Material and drifted
      // away from every other surface on the screen.
      expect(AppTheme.dark.chipTheme.backgroundColor, isNotNull);
      expect(AppTheme.dark.chipTheme.labelStyle?.color, AppColors.slate200);
    });

    test('both brightnesses set the bundled face and the rupee fallback', () {
      for (final theme in themes.values) {
        expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
        expect(theme.textTheme.bodyMedium?.fontFamilyFallback,
            containsAll(AppTheme.fontFallback));
      }
    });
  });

  group('ParentTheme tints without repainting the room', () {
    test('the action colour is the parent blue in both brightnesses', () {
      expect(ParentTheme.light.colorScheme.primary, AppColors.primaryBlueDark);
      expect(ParentTheme.dark.colorScheme.primary, AppColors.primaryBlueDark);
      expect(ParentTheme.light.bottomNavigationBarTheme.selectedItemColor,
          AppColors.primaryBlueDark);
    });

    test('surfaces stay the base theme, not a blue-seeded guess', () {
      // Overriding `primary` alone left every surface tinted, and bottom sheets
      // and dialogs came up peach behind a blue form. Reseeding the scheme is
      // what fixed it, and this is the assertion that keeps it fixed.
      expect(ParentTheme.light.colorScheme.surface,
          AppTheme.light.colorScheme.surface);
      expect(ParentTheme.dark.colorScheme.surface,
          AppTheme.dark.colorScheme.surface);
      expect(ParentTheme.dark.cardTheme.color, AppTheme.dark.cardTheme.color);
    });

    test('nothing orange survives on a parent surface', () {
      for (final theme in [ParentTheme.light, ParentTheme.dark]) {
        expect(theme.colorScheme.primary, isNot(AppColors.primaryOrange));
        expect(theme.elevatedButtonTheme.style?.backgroundColor
            ?.resolve(const <WidgetState>{}), isNot(AppColors.primaryOrange));
        expect(theme.bottomNavigationBarTheme.selectedItemColor,
            isNot(AppColors.primaryOrange));
      }
    });

    test('it is built once, not per route change', () {
      // MaterialApp.builder runs on every navigation, so these are `static
      // final` on purpose — rebuilding a ColorScheme.fromSeed there would cost
      // a seed computation per push.
      expect(ParentTheme.light, same(ParentTheme.light));
      expect(ParentTheme.dark, same(ParentTheme.dark));
    });
  });
}
