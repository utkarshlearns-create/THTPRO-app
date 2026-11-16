import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/router/page_transitions.dart';
import 'package:tht_app/core/theme/app_theme.dart';
import 'package:tht_app/features/shared/widgets/tht_button.dart';

/// The two things that made the app feel built in an evening: screens that
/// changed with no motion at all, and a phone that never answered the thumb.
///
/// Both fixes are deliberately centralised — one transition, one haptics file,
/// one shared button — so these tests guard the centre rather than 42 screens.
void main() {
  /// Every `HapticFeedback.*` call, in order, as the platform channel sees it.
  ///
  /// `mediumImpact()` and friends are all the same `HapticFeedback.vibrate`
  /// method call distinguished only by their argument, so the argument is the
  /// assertion — checking merely that *something* buzzed would pass even if
  /// every button fired the same undifferentiated thump.
  List<String> watchHaptics(WidgetTester tester) {
    final fired = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          fired.add((call.arguments as String?) ?? 'standard');
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    return fired;
  }

  Future<void> pumpButton(
    WidgetTester tester, {
    required ThtButtonVariant variant,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: ThtButton(
              label: 'Apply',
              variant: variant,
              isLoading: isLoading,
              onPressed: onPressed,
            ),
          ),
        ),
      ));

  group('haptics', () {
    testWidgets('a committing tap thumps, a quieter one only ticks',
        (tester) async {
      final fired = watchHaptics(tester);

      await pumpButton(tester,
          variant: ThtButtonVariant.filled, onPressed: () {});
      await tester.tap(find.byType(ThtButton));
      expect(fired, ['HapticFeedbackType.mediumImpact']);

      fired.clear();
      await pumpButton(tester,
          variant: ThtButtonVariant.outlined, onPressed: () {});
      await tester.tap(find.byType(ThtButton));
      expect(fired, ['HapticFeedbackType.lightImpact']);

      fired.clear();
      await pumpButton(tester,
          variant: ThtButtonVariant.text, onPressed: () {});
      await tester.tap(find.byType(ThtButton));
      expect(fired, ['HapticFeedbackType.lightImpact']);
    });

    testWidgets('the press still reaches the caller', (tester) async {
      watchHaptics(tester);
      var pressed = 0;
      await pumpButton(tester,
          variant: ThtButtonVariant.filled, onPressed: () => pressed++);
      await tester.tap(find.byType(ThtButton));
      expect(pressed, 1);
    });

    testWidgets('a button that cannot be pressed does not buzz',
        (tester) async {
      final fired = watchHaptics(tester);

      // Disabled: nothing to acknowledge.
      await pumpButton(tester, variant: ThtButtonVariant.filled);
      await tester.tap(find.byType(ThtButton), warnIfMissed: false);
      expect(fired, isEmpty);

      // Mid-submit: the thump already fired on the tap that started it, and a
      // second one would read as a second submission.
      await pumpButton(tester,
          variant: ThtButtonVariant.filled,
          isLoading: true,
          onPressed: () {});
      await tester.tap(find.byType(ThtButton), warnIfMissed: false);
      expect(fired, isEmpty);
    });
  });

  group('page transitions', () {
    test('coming back is quicker than going', () {
      final page = slidePage(const SizedBox());
      expect(page.transitionDuration, const Duration(milliseconds: 260));
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 210));
      expect(
        page.reverseTransitionDuration < page.transitionDuration,
        isTrue,
        reason: 'a return should feel shorter than the trip out',
      );
    });

    test('iOS keeps its own grammar, Android gets ours', () {
      final builders = kThtPageTransitions.builders;
      expect(builders[TargetPlatform.android], isA<ThtPageTransitionsBuilder>());
      expect(
        builders[TargetPlatform.iOS],
        isA<CupertinoPageTransitionsBuilder>(),
        reason: 'replacing the back-edge swipe costs more than this motion '
            'is worth',
      );
    });

    testWidgets('the arriving screen really travels', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) => const NoTransitionPage(
              child: Scaffold(body: Center(child: Text('home'))),
            ),
          ),
          GoRoute(
            path: '/score',
            pageBuilder: (_, __) => slidePage(
              const Scaffold(body: Center(child: Text('score'))),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ));

      router.go('/score');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      // Caught in flight, and measured against where this same screen ends up
      // rather than against the one it replaced — two different words centre
      // at two different x, which is not motion.
      final inFlight = tester.getTopLeft(find.text('score')).dx;
      final opacity = tester
          .widgetList<FadeTransition>(
            find.ancestor(
              of: find.text('score'),
              matching: find.byType(FadeTransition),
            ),
          )
          .map((f) => f.opacity.value)
          .reduce((a, b) => a * b);

      await tester.pumpAndSettle();
      final atRest = tester.getTopLeft(find.text('score')).dx;

      expect(inFlight, greaterThan(atRest),
          reason: 'it should arrive from the right');
      expect(opacity, lessThan(1.0), reason: 'and fade up as it comes');
    });

    testWidgets('someone who turned animations off gets none of it',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) => slidePage(const Text('x')).transitionsBuilder(
                context,
                const AlwaysStoppedAnimation(0.5),
                const AlwaysStoppedAnimation(0),
                const Text('x'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('x'), findsOneWidget);
      expect(
        find.byType(SlideTransition),
        findsNothing,
        reason: 'the phone was asked to stop moving things, so this stops too',
      );
    });
  });
}
