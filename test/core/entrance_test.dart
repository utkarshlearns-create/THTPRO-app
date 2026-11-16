import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/entrance.dart';

/// A staggered list is a two-line idea with one hard part.
///
/// The easy half — cards fade and lift into place — is visible the moment it
/// works. The hard half is that it must happen exactly once, on the list's
/// first draw: an app that fades in whatever the thumb drags into view feels
/// broken in a way the original snapping list never did. Most of this file
/// guards the hard half.
void main() {
  /// The opacity the reader actually sees, or 1 when nothing is animating.
  ///
  /// An item that never started has no [Opacity] above it at all — the widget
  /// returns its child untouched — so "no wrapper" and "finished" both read as
  /// 1. They are told apart by *when* they are measured: one frame in, an
  /// arriving item is still faint and a skipped one is already solid.
  double opacityOf(WidgetTester tester, String label) {
    final wrappers = tester.widgetList<Opacity>(
      find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
    );
    return wrappers.isEmpty
        ? 1
        : wrappers.map((o) => o.opacity).reduce((a, b) => a * b);
  }

  Widget listOf(
    int count, {
    ScrollController? controller,
    bool stillAnimations = false,
  }) =>
      MaterialApp(
        home: Builder(
          builder: (context) {
            final list = ListView.builder(
              controller: controller,
              itemExtent: 100,
              itemCount: count,
              itemBuilder: (_, i) =>
                  ThtEntrance(index: i, child: Text('item $i')),
            );
            return Scaffold(
              body: stillAnimations
                  ? MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(disableAnimations: true),
                      child: list,
                    )
                  : list,
            );
          },
        ),
      );

  group('the stagger rule', () {
    test('each item waits its turn, until the cap', () {
      expect(entranceDelayFor(0), Duration.zero);
      expect(entranceDelayFor(1), kEntranceStagger);
      expect(entranceDelayFor(3), kEntranceStagger * 3);
      expect(entranceDelayFor(kEntranceMaxStagger),
          kEntranceStagger * kEntranceMaxStagger);
    });

    test('past the cap nothing waits longer', () {
      final capped = entranceDelayFor(kEntranceMaxStagger);
      expect(entranceDelayFor(kEntranceMaxStagger + 1), capped);
      expect(entranceDelayFor(900), capped);
      expect(
        capped + kEntranceDuration,
        lessThan(const Duration(milliseconds: 700)),
        reason: 'the whole list must be settled before a reader could have '
            'read the first card and reached for the second',
      );
    });
  });

  group('a list arriving', () {
    testWidgets('fades and lifts its cards in order', (tester) async {
      await tester.pumpWidget(listOf(40));

      // Caught in flight, one stagger step in.
      await tester.pump(const Duration(milliseconds: 60));
      final first = opacityOf(tester, 'item 0');
      expect(first, greaterThan(0), reason: 'the first card is already coming');
      expect(first, lessThan(1), reason: 'but it has not arrived');
      expect(
        opacityOf(tester, 'item 2'),
        lessThan(first),
        reason: 'a card further down the list should still be behind the one '
            'above it — that gap is the whole point of a stagger',
      );

      final inFlight = tester.getTopLeft(find.text('item 0')).dy;
      await tester.pumpAndSettle();
      final atRest = tester.getTopLeft(find.text('item 0')).dy;

      expect(inFlight, greaterThan(atRest), reason: 'it rises into place');
      expect(opacityOf(tester, 'item 0'), 1);
      expect(opacityOf(tester, 'item 2'), 1);
    });

    testWidgets('leaves nothing pending when torn down mid-arrival',
        (tester) async {
      await tester.pumpWidget(listOf(40));
      await tester.pump(const Duration(milliseconds: 60));
      // Half-arrived, and then the screen goes away. The delay lives inside
      // the controller rather than in a timer precisely so this is clean.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
      expect(find.text('item 0'), findsNothing);
    });
  });

  group('a list being read', () {
    testWidgets('does not fade in what the thumb scrolls to', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(listOf(60, controller: controller));
      await tester.pumpAndSettle();
      // Well past the first draw, which is the condition being tested.
      await tester.pump(const Duration(seconds: 1));

      controller.jumpTo(3000);
      await tester.pump();

      expect(
        opacityOf(tester, 'item 30'),
        1,
        reason: 'this card was scrolled to, not arrived at. Animating it would '
            'mean the list never stops moving while it is being read',
      );
    });

    testWidgets('does not replay a card scrolled back to', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(listOf(60, controller: controller));
      await tester.pumpAndSettle();

      controller.jumpTo(3000);
      await tester.pump();
      controller.jumpTo(0);
      await tester.pump();

      expect(opacityOf(tester, 'item 0'), 1,
          reason: 'item 0 already arrived once; coming back is not arriving');
    });

    testWidgets('gives none of it to someone who turned animations off',
        (tester) async {
      await tester.pumpWidget(listOf(40, stillAnimations: true));
      await tester.pump(const Duration(milliseconds: 60));

      expect(opacityOf(tester, 'item 0'), 1);
      expect(opacityOf(tester, 'item 3'), 1);
      expect(
        find.byType(Opacity),
        findsNothing,
        reason: 'the phone was asked to stop moving things, so this stops too',
      );
    });
  });

  testWidgets('a refusal is felt, not only read', (tester) async {
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

    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          captured = context;
          return const SizedBox();
        }),
      ),
    ));

    captured.showFailure(Exception('the server said no'));
    await tester.pump();

    expect(
      fired,
      ['HapticFeedbackType.heavyImpact'],
      reason: 'heavier than any success, so a refusal cannot be mistaken for '
          'one by a thumb that is not looking',
    );
    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
  });
}
