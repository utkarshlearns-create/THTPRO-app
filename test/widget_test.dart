import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tht_app/main.dart';

void main() {
  testWidgets('App boots into the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: THTApp()));
    await tester.pump();

    // Auth starts in the loading state, so the router lands on /splash,
    // which shows the brand mark above a progress indicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
