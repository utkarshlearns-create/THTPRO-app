import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_theme.dart';
import 'package:tht_app/core/theme/parent_theme.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/stat_tile.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';

/// One sheet of the shared components, recorded per theme.
///
/// The four themes are the thing worth pinning. A card, a stat tile, a pill and
/// an empty state are the pieces nearly every screen is assembled from, and a
/// change to a token, a radius, a chip fill or a scheme seed shows up here as a
/// picture instead of as a bug report from a tester using dark mode.
///
/// Why one sheet per theme rather than a golden per widget: the components are
/// read *next to each other* on a real screen, and a sheet catches the things a
/// per-widget golden cannot — two radii that no longer agree, a tone that has
/// drifted away from the surface it sits on.
///
/// Regenerate with: flutter test --update-goldens
void main() {
  final themes = <String, ThemeData>{
    'light': AppTheme.light,
    'dark': AppTheme.dark,
    'parent_light': ParentTheme.light,
    'parent_dark': ParentTheme.dark,
  };

  themes.forEach((name, theme) {
    testWidgets('the component sheet in $name', (tester) async {
      tester.view.physicalSize = const Size(420, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: const _Sheet(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(_Sheet),
        matchesGoldenFile('goldens/component_sheet_$name.png'),
      );
    });
  });
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Components')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const THTCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Class 10 · CBSE',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(height: AppSpacing.xs),
                  Text('Gomti Nagar, Lucknow'),
                  SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      Pill('Maths', tone: Tone.info),
                      Pill('Science', tone: Tone.accent),
                      Pill('Hired', tone: Tone.success),
                      Pill('Overdue', tone: Tone.critical),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Earnings',
                    value: '₹18,400',
                    icon: Icons.account_balance_wallet_outlined,
                    tone: Tone.success,
                    caption: 'This month',
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatTile(
                    label: 'Applications',
                    value: '7',
                    icon: Icons.description_outlined,
                    tone: Tone.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Both buttons, because the AA fix moved what they are painted with
            // and the pair reads differently in each brightness.
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Apply now'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Not now'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const THTCard(
              child: EmptyState(
                title: 'No tuitions yet',
                message: 'Applications you send will show up here.',
                icon: Icons.inbox_outlined,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
