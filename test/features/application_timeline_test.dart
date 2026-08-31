import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/features/jobs/widgets/application_timeline_sheet.dart';
import 'package:tht_app/features/tutor/providers/applications_provider.dart';

/// The timeline draws stages that have not happened yet, so the rule that
/// matters is that it never ticks one off early — a teacher reading "Demo
/// done" when no demo was booked would go looking for one.
void main() {
  Application app(Map<String, dynamic> extra) => Application.fromJson({
        'id': 1,
        'job': 7,
        'status': 'APPLIED',
        'demo_status': 'PENDING',
        'created_at': '2026-08-20T09:30:00Z',
        ...extra,
      });

  Future<void> pump(WidgetTester t, Application a) async {
    t.view.physicalSize = const Size(390, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          tutorApplicationsProvider.overrideWith((ref) async => [a]),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ApplicationTimelineSheet(jobId: 7)),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a fresh application shows the road ahead, none of it ticked',
      (t) async {
    await pump(t, app({}));

    expect(find.text('You applied'), findsOneWidget);
    expect(find.text('With the family'), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('Hired'), findsOneWidget);

    // Nothing claiming a demo happened.
    expect(find.text('Demo done'), findsNothing);
    expect(find.text('Demo confirmed'), findsNothing);
    expect(find.text('You were hired'), findsNothing);
  });

  testWidgets('a booked demo names the slot rather than the default status',
      (t) async {
    await pump(
      t,
      app({
        'status': 'SHORTLISTED',
        'demo_status': 'ACCEPTED',
        'demo_date': '2026-09-02T16:00:00Z',
      }),
    );

    expect(find.text('The family shortlisted you'), findsOneWidget);
    expect(find.text('Demo confirmed'), findsOneWidget);
    expect(find.text('With the family'), findsNothing);
  });

  testWidgets('a closed application gives the reason it ended', (t) async {
    await pump(
      t,
      app({
        'status': 'NOT_SELECTED',
        'closure_reason': 'The family picked a teacher living closer.',
      }),
    );

    expect(find.text('Not selected for this one'), findsOneWidget);
    expect(
      find.text('The family picked a teacher living closer.'),
      findsOneWidget,
    );
    // No dangling future stage on something already over.
    expect(find.text('Hired'), findsNothing);
  });
}
