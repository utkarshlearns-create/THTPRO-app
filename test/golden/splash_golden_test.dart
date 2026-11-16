import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/theme/app_theme.dart';
import 'package:tht_app/core/ui/intro_timing.dart';
import 'package:tht_app/features/shared/screens/splash_screen.dart';

/// The intro, recorded mid-flight and at rest.
///
/// The mid-flight frame is the one worth having. At rest the splash is just the
/// logo; at 45% the mark has just finished settling, the lockup is halfway
/// through its rise and the wordmark is fading up with the rule and the promise
/// still to come — so a change to any beat of the choreography, a curve or an
/// interval, moves this picture and nothing else would have caught it.
///
/// Regenerate with: flutter test --update-goldens
void main() {
  final frames = <String, double>{
    // Mid-flight: the mark has settled, the name is arriving, the rule and the
    // promise have not.
    'midflight': 0.45,
    'settled': 1.0,
  };

  for (final brightness in ['light', 'dark']) {
    frames.forEach((label, at) {
      testWidgets('the intro at $label in $brightness', (tester) async {
        tester.view.physicalSize = const Size(400, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: brightness == 'dark' ? AppTheme.dark : AppTheme.light,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          ),
        );

        // The logo is an asset, and an asset decodes on the real clock rather
        // than the test one. Without this the goldens record the sequence with
        // a hole where the mark should be.
        await tester.runAsync(() async {
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(
              image.image,
              tester.element(find.byType(SplashScreen)),
            );
          }
        });

        await tester.pump(IntroTiming.floor * at);

        await expectLater(
          find.byType(SplashScreen),
          matchesGoldenFile('goldens/splash_${label}_$brightness.png'),
        );
      });
    });
  }
}
