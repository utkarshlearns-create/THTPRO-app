import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/models/attendance_record.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/parent_stats.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/repositories/users_repository.dart';

/// The parent dashboard payload: counts, activity and recommendations.
final parentStatsProvider = FutureProvider.autoDispose<ParentStats>(
  (ref) => ref.watch(jobsRepositoryProvider).parentStats(),
);

/// Every requirement this parent has posted.
final myJobsProvider = FutureProvider.autoDispose<List<Job>>(
  (ref) => ref.watch(jobsRepositoryProvider).myJobs(),
);

/// One of the parent's own requirements, picked out of the list they already
/// have.
///
/// Deliberately not `GET /api/jobs/<id>/`: that is the teacher-facing view,
/// which gates on `APPROVED`/`TUTOR_SELECTED`/`ASSIGNED` — so a parent's own
/// requirement awaiting approval would 404 on them — and it answers with the
/// contact-unlock shape, which is meaningless when you are the one who posted
/// it. The parent's own list is already permissioned and carries every field.
final myJobProvider = FutureProvider.autoDispose.family<Job?, int>(
  (ref, jobId) async {
    final jobs = await ref.watch(myJobsProvider.future);
    for (final job in jobs) {
      if (job.id == jobId) return job;
    }
    return null;
  },
);

/// Teachers who have put themselves forward for one requirement.
final applicantsProvider =
    FutureProvider.autoDispose.family<List<Application>, int>(
  (ref, jobId) => ref.watch(jobsRepositoryProvider).applicants(jobId),
);

/// Sessions **this parent** marked, for one requirement.
final jobAttendanceProvider =
    FutureProvider.autoDispose.family<List<AttendanceRecord>, int>(
  (ref, jobId) async {
    final rows = await ref
        .watch(jobsRepositoryProvider)
        .parentAttendance(jobId: jobId);
    // Narrowed again client-side: an older server ignores the `job` parameter
    // and returns everything, which would otherwise show another child's
    // sessions under this requirement.
    return rows.where((r) => r.jobId == jobId).toList();
  },
);

/// Sessions the **teacher** logged against one of this parent's requirements.
///
/// The thing a parent actually wants to check — did the teacher turn up — and
/// which the app could not show at all until the endpoint learned `?source=`.
final tutorMarkedAttendanceProvider =
    FutureProvider.autoDispose.family<List<AttendanceRecord>, int>(
  (ref, jobId) async {
    final rows = await ref
        .watch(jobsRepositoryProvider)
        .parentAttendance(jobId: jobId, fromTutor: true);
    return rows.where((r) => r.jobId == jobId).toList();
  },
);

/// Teachers this parent has saved.
final favouriteTutorsProvider = FutureProvider.autoDispose<List<PublicTutor>>(
  (ref) => ref.watch(usersRepositoryProvider).favouriteTutors(),
);

/// Teachers whose contact this parent has already spent a credit on.
final unlockedContactsProvider = FutureProvider.autoDispose<List<PublicTutor>>(
  (ref) => ref.watch(usersRepositoryProvider).unlockedContacts(),
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
