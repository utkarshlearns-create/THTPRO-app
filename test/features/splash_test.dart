import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tht_app/core/theme/app_theme.dart';
import 'package:tht_app/core/ui/intro_timing.dart';
import 'package:tht_app/features/shared/screens/splash_screen.dart';

/// The intro, and the three properties that decide whether it looks bought or
/// built in an evening.
///
/// 1. **It is the real logo, not a re-typing of it.** The splash used to draw a
///    mark that already read `THT` and then set `THE HOME TUITIONS` underneath
///    it in Plus Jakarta Sans — the app's UI face, not the logo's. The brand
///    appeared twice, in two typefaces, neither of them the one on the
///    signboard. Every layer is now a slice of the real artwork, so the test
///    that matters is that the splash paints no text at all.
///
/// 2. **The handover is seamless.** `flutter_native_splash` leaves the roof on
///    screen at 179dp, centred. The first frame of this widget has to put the
///    same roof at the same width in the same place or the launch shows a jump.
///
/// 3. **The sequence finishes inside the floor.** The auth gate navigates away
///    the moment [IntroTiming.floor] is up, so a sequence still mid-flight at
///    that point is a cut, not an ending — which is exactly what the old
///    fixed-duration splash did on a fast launch.
void main() {
  Future<void> pumpSplash(WidgetTester tester, {ThemeData? theme}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }

  /// The asset a given `Image` is drawing.
  ///
  /// Every layer passes `cacheWidth`, which wraps the provider in a
  /// `ResizeImage` — so the `AssetImage` is one level down, not at the top.
  String? assetOf(Image widget) {
    ImageProvider provider = widget.image;
    if (provider is ResizeImage) provider = provider.imageProvider;
    return provider is AssetImage ? provider.assetName : null;
  }

  Finder layer(String name) => find.byWidgetPredicate(
        (w) => w is Image && assetOf(w) == 'assets/images/$name.png',
        description: '$name.png',
      );

  /// How far a layer has arrived: 0 before its beat, 1 at rest.
  double opacityOf(WidgetTester tester, String name) => tester
      .widget<Opacity>(
        find.ancestor(of: layer(name), matching: find.byType(Opacity)).first,
      )
      .opacity;

  /// The scale the mark is currently drawn at — 1 as the launch screen left it,
  /// settling to 0.75 once the lockup has assembled around it.
  ///
  /// Read off the x axis rather than through `getMaxScaleOnAxis`, which would
  /// answer 1 forever: `Transform.scale` scales x and y and leaves z alone, so
  /// the largest axis of a shrinking 2D transform is the untouched one.
  double markScale(WidgetTester tester) => tester
      .widget<Transform>(
        find.ancestor(of: layer('logo_mark'), matching: find.byType(Transform)).first,
      )
      .transform
      .storage[0];

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

  testWidgets('the lockup is the logo itself, never a re-typing of it',
      (tester) async {
    await pumpSplash(tester);
    await tester.pump(IntroTiming.floor);

    expect(layer('logo_mark'), findsOneWidget);
    expect(layer('logo_wordmark'), findsOneWidget);
    expect(layer('logo_tagline'), findsOneWidget);

    // The regression this screen was rebuilt for. Any `Text` here is the brand
    // being set in the wrong face again.
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('the first frame continues the launch screen rather than replacing it',
      (tester) async {
    await pumpSplash(tester);

    // 179dp is not a design choice: `flutter_native_splash` renders splash.png
    // on a 256dp canvas and the artwork fills 0.6992 of it, so this is the
    // width Android has already painted when this frame runs.
    expect(tester.widget<Image>(layer('logo_mark')).width, 179);
    expect(markScale(tester), 1.0,
        reason: 'the mark must start at the size the launch screen left it');

    // And in the same place: the lockup is pushed down on the first frame so
    // that the roof, not the assembled lockup, is what sits dead centre.
    expect(
      tester.getCenter(layer('logo_mark')).dy,
      moreOrLessEquals(tester.getCenter(find.byType(SplashScreen)).dy, epsilon: 0.5),
      reason: 'the roof must begin screen-centred, as the launch screen drew it',
    );
  });

  testWidgets('the whole sequence finishes inside the floor', (tester) async {
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
    expect(opacityOf(tester, 'logo_tagline'), 1.0);
    expect(markScale(tester), moreOrLessEquals(0.75, epsilon: 0.001));
  });

  testWidgets('it assembles beat by beat rather than appearing at once',
      (tester) async {
    await pumpSplash(tester);
    // A third of the way in the mark is settling and the name is fading up, but
    // the promise has not arrived — it is the last beat, at 0.62 of the whole.
    await tester.pump(IntroTiming.floor * 0.35);
    expect(opacityOf(tester, 'logo_tagline'), 0.0);
    expect(opacityOf(tester, 'logo_wordmark'), lessThan(1.0));
    expect(markScale(tester), lessThan(1.0),
        reason: 'the mark should already be settling by a third of the way in');

    await tester.pump(IntroTiming.floor);
    expect(opacityOf(tester, 'logo_tagline'), 1.0);
    expect(opacityOf(tester, 'logo_wordmark'), 1.0);
  });

  testWidgets('it plays on the dark canvas too', (tester) async {
    await pumpSplash(tester, theme: AppTheme.dark);
    await tester.pump(IntroTiming.floor);

    // Separate artwork, not a tint: the mark keeps its brand blue while the ink
    // around it lifts to slate-100, which a colour filter could not do.
    expect(layer('logo_mark_dark'), findsOneWidget);
    expect(layer('logo_wordmark_dark'), findsOneWidget);
    expect(layer('logo_tagline_dark'), findsOneWidget);
    expect(layer('logo_mark'), findsNothing);
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
