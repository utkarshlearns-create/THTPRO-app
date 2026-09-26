import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/ui/responsive_shell.dart';

/// A phone layout is the only layout this app has, so the question a tablet
/// asks is not "which two-pane arrangement" but "how wide is the column".
void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveShell(
          child: Scaffold(body: Placeholder()),
        ),
      ),
    );
  }

  /// The frame the shell paints: a box constrained to the content width with a
  /// hairline down each side. `ColoredBox` alone is no use as a marker — a
  /// Scaffold paints one of its own.
  final frame = find.byWidgetPredicate((w) =>
      w is ConstrainedBox &&
      w.constraints.maxWidth == ResponsiveShell.maxContentWidth);

  testWidgets('a phone gets the whole screen', (tester) async {
    await pumpAt(tester, const Size(400, 900));

    expect(tester.getSize(find.byType(Scaffold)).width, 400);
    // No frame, no wasted paint: below the threshold the shell is a pass-through
    // and every screen renders exactly as it did before it existed.
    expect(frame, findsNothing);
  });

  testWidgets('a phone in landscape is framed rather than stretched',
      (tester) async {
    await pumpAt(tester, const Size(900, 420));

    expect(tester.getSize(find.byType(Scaffold)).width,
        ResponsiveShell.maxContentWidth);
    expect(frame, findsOneWidget);
  });

  testWidgets('a tablet gets the same framed column, centred', (tester) async {
    await pumpAt(tester, const Size(1024, 1366));

    final content = tester.getRect(find.byType(Scaffold));
    expect(content.width, ResponsiveShell.maxContentWidth);
    // Centred: the gutters on either side are equal, which is what makes the
    // empty space read as a frame rather than as a layout that failed to fill.
    expect(content.left, closeTo(1024 - content.right, 0.5));
  });
}
