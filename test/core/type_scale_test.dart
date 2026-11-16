import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/theme/app_theme.dart';
import 'package:tht_app/core/theme/app_type.dart';
import 'package:tht_app/core/theme/parent_theme.dart';

/// The scale is only worth the migration if it holds.
///
/// 479 hand-written sizes across 33 values went onto ten named steps. Nothing
/// stops the thirty-fourth value from appearing next week except a test that
/// reads the source and refuses it, which is what the first case here does.
void main() {
  /// Sizes that come from a container rather than from the hierarchy.
  ///
  /// The initials inside an avatar scale with the avatar; pinning them to the
  /// type scale would make a 24px avatar and a 64px one wear the same letters.
  /// These are the only sizes in the app allowed off the scale.
  final derived = RegExp(r'fontSize: \w+ \* [0-9.]+');

  final rawSize = RegExp(r'fontSize:\s*[0-9]');

  group('the type scale', () {
    test('no screen sets a font size of its own', () {
      final offenders = <String>[];

      for (final f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        // The scale itself is the one file allowed to name the numbers.
        if (f.path.replaceAll(r'\', '/').endsWith('core/theme/app_type.dart')) {
          continue;
        }
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (rawSize.hasMatch(line) && !derived.hasMatch(line)) {
            offenders.add('${f.path}:${i + 1}  ${line.trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'use a ThtType step instead of a literal. If none of the ten '
            'fits, the scale is wrong and should be changed in app_type.dart '
            'rather than worked around here:\n${offenders.join('\n')}',
      );
    });

    test('the steps are far enough apart to be seen', () {
      const steps = ThtType.steps;
      expect(steps, equals([...steps]..sort()), reason: 'kept ascending');
      expect(steps.toSet().length, steps.length, reason: 'no duplicates');

      for (var i = 1; i < steps.length; i++) {
        final ratio = steps[i] / steps[i - 1];
        expect(
          ratio,
          greaterThanOrEqualTo(1.07),
          reason: '${steps[i - 1]} and ${steps[i]} are too close to read as '
              'different sizes — which is the problem the scale exists to fix',
        );
      }
    });

    test('both themes answer with the scale, not with Material defaults', () {
      for (final entry in <String, ThemeData>{
        'light': AppTheme.light,
        'dark': AppTheme.dark,
        'parent light': ParentTheme.light,
        'parent dark': ParentTheme.dark,
      }.entries) {
        final t = entry.value.textTheme;
        expect(t.bodyMedium?.fontSize, ThtType.body, reason: entry.key);
        expect(t.titleLarge?.fontSize, ThtType.title, reason: entry.key);
        expect(t.labelSmall?.fontSize, ThtType.micro, reason: entry.key);

        // Material's own headlineMedium is 28sp of Roboto. Four auth headings
        // were rendering at that size because nobody had said otherwise.
        expect(t.headlineMedium?.fontSize, ThtType.display, reason: entry.key);
      }
    });

    test('every size the app uses is one of the ten', () {
      final named = RegExp(r'ThtType\.(\w+)');
      final allowed = <String>{
        'micro', 'caption', 'body', 'bodyStrong', 'subtitle',
        'title', 'headline', 'display', 'figure', 'hero', 'steps',
      };
      final used = <String>{};

      for (final f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        for (final m in named.allMatches(f.readAsStringSync())) {
          used.add(m.group(1)!);
        }
      }

      expect(used.difference(allowed), isEmpty);
      expect(used, isNotEmpty, reason: 'the migration should have left marks');
    });
  });
}
