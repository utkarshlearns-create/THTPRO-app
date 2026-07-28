import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/parent_stats.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';

/// The parent dashboard payload: counts, activity and recommendations.
final parentStatsProvider = FutureProvider.autoDispose<ParentStats>(
  (ref) => ref.watch(jobsRepositoryProvider).parentStats(),
);

/// Every requirement this parent has posted.
final myJobsProvider = FutureProvider.autoDispose<List<Job>>(
  (ref) => ref.watch(jobsRepositoryProvider).myJobs(),
);

/// Teachers who have put themselves forward for one requirement.
final applicantsProvider =
    FutureProvider.autoDispose.family<List<Application>, int>(
  (ref, jobId) => ref.watch(jobsRepositoryProvider).applicants(jobId),
);

/// Reloads everything behind the parent home screen at once.
///
/// Errors are swallowed here on purpose: each section renders its own failure
/// through AsyncView, so letting one throw would abort the pull-to-refresh
/// gesture for the sections that did load.
Future<void> refreshParentHome(WidgetRef ref) async {
  ref
    ..invalidate(parentStatsProvider)
    ..invalidate(myJobsProvider);
  try {
    await ref.read(parentStatsProvider.future);
  } catch (_) {
    // Surfaced by the section that owns it.
  }
}
