import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tht_app/core/theme/app_theme.dart';
import 'package:tht_app/core/ui/intro_timing.dart';
import 'package:tht_app/features/shared/screens/splash_screen.dart';

/// The intro, and the one property that used to break it.
///
/// The old splash ran on a fixed timeline while the auth gate held the screen
/// for a constant written somewhere else, so on a fast launch the animation was
/// torn down halfway through — the logo appeared and the app cut to the home
/// screen before the name had finished writing itself. Both now read
/// [IntroTiming.floor], and the test that matters is that the whole sequence
/// actually finishes inside it.
void main() {
  Future<void> pumpSplash(WidgetTester tester, {ThemeData? theme}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }

  /// The controller the whole sequence hangs off.
  ///
  /// Scoped to the splash: `MaterialApp` has an `AnimatedBuilder` of its own
  /// above this, and the progress indicator has one below it that spins forever
  /// by design, so neither the first nor the last in the tree is the right one.
  Animation<double> sequence(WidgetTester tester) => tester
      .widget<AnimatedBuilder>(find
          .descendant(
            of: find.byType(SplashScreen),
            matching: find.byType(AnimatedBuilder),
          )
          .first)
      .listenable as Animation<double>;

  /// How far in the promise has arrived: 0 before its beat, 1 at rest.
  double taglineOpacity(WidgetTester tester) => tester
      .widget<Opacity>(find
          .ancestor(
            of: find.text('Learn & Earn'),
            matching: find.byType(Opacity),
          )
          .first)
      .opacity;

  /// Every `Text` the splash paints, in paint order — the wordmark is written a
  /// letter at a time, so the name is seventeen separate widgets.
  String renderedText(WidgetTester tester) =>
      tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join();

  testWidgets('the lockup is the brand name and the promise', (tester) async {
    await pumpSplash(tester);
    await tester.pump(IntroTiming.floor);

    final text = renderedText(tester);
    expect(text, contains('THE HOME TUITIONS'));
    expect(text, contains('Learn & Earn'));
  });

  testWidgets('the whole sequence finishes inside the floor', (tester) async {
    // This is the regression. The auth gate navigates away the moment the floor
    // is up, so a sequence still mid-flight at that point is a cut, not an
    // ending — which is exactly what the old fixed-duration splash did.
    await pumpSplash(tester);
    expect(sequence(tester).isAnimating, isTrue,
        reason: 'the intro should be running on the first frame');

    // One frame of slack: the controller is started in `initState`, so its
    // ticker only begins counting on the frame after the one `pumpWidget`
    // produced, and the test clock is a frame behind the animation throughout.
    await tester.pump(IntroTiming.floor);
    await tester.pump(const Duration(milliseconds: 17));
    expect(sequence(tester).isCompleted, isTrue,
        reason: 'the intro is still running after IntroTiming.floor has passed');
    expect(taglineOpacity(tester), 1.0);
  });

  testWidgets('it writes itself rather than appearing at once', (tester) async {
    await pumpSplash(tester);
    // A third of the way in the mark has landed and the name is being set, but
    // the promise has not arrived — it is the last beat, at 0.68 of the whole.
    await tester.pump(IntroTiming.floor * 0.35);
    expect(taglineOpacity(tester), 0.0);

    await tester.pump(IntroTiming.floor);
    expect(taglineOpacity(tester), 1.0);
  });

  testWidgets('it plays on the dark canvas too', (tester) async {
    await pumpSplash(tester, theme: AppTheme.dark);
    await tester.pump(IntroTiming.floor);
    expect(renderedText(tester), contains('Learn & Earn'));
  });

  group('IntroTiming decides how long the intro gets', () {
    test('the first launch of an install gets the full cinematic', () async {
      SharedPreferences.setMockInitialValues({});
      await IntroTiming.resolve();

      expect(IntroTiming.playFullIntro, isTrue);
      expect(IntroTiming.floor, IntroTiming.full);
    });

    test('and every launch after it gets the short one', () async {
      SharedPreferences.setMockInitialValues({});
      await IntroTiming.resolve();
      // The flag is stamped during the first resolve, not when the animation
      // ends — a launch killed mid-intro must not replay it forever.
      await IntroTiming.resolve();

      expect(IntroTiming.playFullIntro, isFalse);
      expect(IntroTiming.floor, IntroTiming.brief);
      expect(IntroTiming.brief, lessThan(IntroTiming.full));
    });

    test('a storage failure shortens the intro rather than blocking launch',
        () async {
      // No mock values registered at all: the platform channel throws, and the
      // catch has to leave the app launchable.
      SharedPreferences.setMockInitialValues({'intro_played_v1': true});
      await IntroTiming.resolve();
      expect(IntroTiming.floor, IntroTiming.brief);
    });
  });
}
