import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/features/tutor/providers/applications_provider.dart';

/// Which tab an application belongs under.
///
/// The server sets `demo_status = 'PENDING'` on every application at creation,
/// so status alone says nothing about whether a demo exists. Reading it that
/// way filed every freshly applied job under Demos and left Applied empty —
/// which is exactly what a teacher who had only applied saw.
void main() {
  Application app({
    String status = 'APPLIED',
    String demoStatus = 'PENDING',
    String? demoDate,
    String completion = '',
  }) =>
      Application.fromJson({
        'id': 1,
        'status': status,
        'demo_status': demoStatus,
        if (demoDate != null) 'demo_date': demoDate,
        'job_completion_status': completion,
      });

  test('applying alone is not a demo', () {
    final a = app();
    expect(a.hasUpcomingDemo, isFalse,
        reason: 'demo_status is PENDING by default on every application');
    expect(ApplicationStage.demo.matches(a), isFalse);
    expect(ApplicationStage.awaiting.matches(a), isTrue,
        reason: 'it belongs under Applied, where the teacher looks for it');
  });

  test('a dated demo is a demo', () {
    final a = app(demoDate: '2026-09-10T15:00:00Z');
    expect(a.hasUpcomingDemo, isTrue);
    expect(ApplicationStage.demo.matches(a), isTrue);
    expect(ApplicationStage.awaiting.matches(a), isFalse,
        reason: 'once scheduled it moves on from Applied');
  });

  test('a rejected or finished demo is not upcoming', () {
    expect(
      app(demoDate: '2026-09-10T15:00:00Z', demoStatus: 'REJECTED')
          .hasUpcomingDemo,
      isFalse,
    );
    expect(
      app(
        demoDate: '2026-09-10T15:00:00Z',
        completion: 'COMPLETED',
      ).hasUpcomingDemo,
      isFalse,
    );
  });

  test('a fresh application reads as awaiting, not as a demo', () {
    final a = app();
    expect(a.stageLabel, 'Awaiting reply',
        reason: 'the pill said "Demo proposed" the moment a teacher applied');
    expect(a.toneKey, 'APPLIED');
  });

  test('the demo labels appear once a slot exists', () {
    expect(app(demoDate: '2026-09-10T15:00:00Z').stageLabel, 'Demo proposed');
    expect(
      app(demoDate: '2026-09-10T15:00:00Z', demoStatus: 'ACCEPTED').stageLabel,
      'Demo booked',
    );
  });

  test('a hired application is teaching, not applied', () {
    final a = app(status: 'HIRED', completion: 'ONGOING');
    expect(ApplicationStage.teaching.matches(a), isTrue);
    expect(ApplicationStage.awaiting.matches(a), isFalse);
  });

  test('every application lands in exactly one tab', () {
    final cases = [
      app(),
      app(demoDate: '2026-09-10T15:00:00Z'),
      app(status: 'HIRED', completion: 'ONGOING'),
      app(status: 'REJECTED'),
    ];
    for (final a in cases) {
      final tabs = [
        ApplicationStage.awaiting,
        ApplicationStage.demo,
        ApplicationStage.teaching,
        ApplicationStage.closed,
      ].where((s) => s.matches(a)).toList();
      expect(tabs.length, 1,
          reason: 'status=${a.status} demo=${a.demoStatus} '
              'date=${a.demoDate} landed in $tabs');
    }
  });
}
