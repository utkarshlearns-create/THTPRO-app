import 'package:flutter_test/flutter_test.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/features/jobs/providers/job_search_provider.dart';

/// The buyable filter runs on the client, because `/api/jobs/search/` has no
/// parameter for it. That makes it easy to get wrong in a way the server would
/// otherwise have caught, so the rules are pinned here.
void main() {
  Job job({required int id, bool ppl = false, int? price, bool applied = false}) =>
      Job.fromJson({
        'id': id,
        'allow_contact': true,
        'allow_pay_per_lead': ppl,
        if (price != null) 'lead_price': price,
        'has_applied': applied,
      });

  final buyable = job(id: 1, ppl: true, price: 499);
  final managed = job(id: 2);
  final buyableApplied = job(id: 3, ppl: true, price: 300, applied: true);

  JobFeedState feed(JobFilters f) =>
      JobFeedState(jobs: [buyable, managed, buyableApplied], filters: f);

  test('off by default — every job stays visible', () {
    expect(feed(const JobFilters()).visible.length, 3);
  });

  test('on, only leads that can actually be bought remain', () {
    final v = feed(const JobFilters(buyableOnly: true)).visible;
    expect(v.map((j) => j.id), [1, 3]);
    expect(v.every((j) => j.isBuyable), isTrue);
  });

  test('stacks with the applied filter rather than replacing it', () {
    final v = feed(
      const JobFilters(buyableOnly: true, unappliedOnly: true),
    ).visible;
    expect(v.map((j) => j.id), [1],
        reason: 'the applied buyable lead must drop out too');
  });

  test('counts toward the badge so the button shows it is on', () {
    expect(const JobFilters().activeCount, 0);
    expect(const JobFilters(buyableOnly: true).activeCount, 1);
    expect(
      const JobFilters(buyableOnly: true, unappliedOnly: true).activeCount,
      2,
    );
  });

  test('never reaches the API, which would reject it', () {
    expect(const JobFilters(buyableOnly: true).toQuery().keys,
        isNot(contains('buyableOnly')));
    expect(const JobFilters(buyableOnly: true).toQuery(), isEmpty);
  });
}
