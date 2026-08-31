import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/features/jobs/widgets/two_ways_card.dart';

/// The comparison makes a money claim, so it must never appear on a job where
/// the paid route does not exist — there the claim would describe a choice the
/// teacher does not have.
void main() {
  Job job({bool ppl = false, int? price}) => Job.fromJson({
        'id': 1,
        'allow_contact': true,
        'allow_pay_per_lead': ppl,
        if (price != null) 'lead_price': price,
      });

  Future<void> pump(WidgetTester tester, Job j) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: TwoWaysCard(job: j))),
      );

  testWidgets('renders nothing on a job that cannot be bought', (t) async {
    await pump(t, job());
    expect(find.text('Two ways to get this tuition'), findsNothing);
    expect(find.text('Apply free'), findsNothing);
  });

  testWidgets('shows both routes and the price once buyable', (t) async {
    await pump(t, job(ppl: true, price: 499));
    expect(find.text('Two ways to get this tuition'), findsOneWidget);
    expect(find.text('Buy the lead'), findsOneWidget);
    expect(find.text('₹499 once'), findsOneWidget);
    expect(find.text('Apply free'), findsOneWidget);
    expect(find.text('No payment'), findsOneWidget);
  });

  testWidgets('states what each route costs later, not just today', (t) async {
    await pump(t, job(ppl: true, price: 499));

    // The free route's later cost, in the column that offers it.
    expect(find.text('THT keeps half of month 1'), findsOneWidget);

    // The paid route's benefit. Confirmed commercial terms: a teacher who
    // buys the lead pays no placement charge, so this is the argument for
    // paying at all and must not go missing.
    expect(find.text('Full fee stays yours'), findsOneWidget);
    expect(
      find.textContaining('close it yourself and nothing is deducted'),
      findsOneWidget,
    );
  });

  testWidgets('two columns survive a 1.3x text scale on a 360dp phone',
      (t) async {
    // The narrowest realistic case: two columns of prose in 360dp, each word
    // a third larger. Flutter turns a RenderFlex overflow into a test failure
    // on its own, so reaching the expects at all is the layout assertion.
    t.view.physicalSize = const Size(360, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.3,
          maxScaleFactor: 1.3,
          child: Scaffold(
            body: SingleChildScrollView(
              child: TwoWaysCard(job: job(ppl: true, price: 499)),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Buy the lead'), findsOneWidget);
    expect(find.text('Apply free'), findsOneWidget);
  });
}
