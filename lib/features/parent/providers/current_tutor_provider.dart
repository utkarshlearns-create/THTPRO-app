import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/features/parent/providers/parent_providers.dart';

/// A teacher currently engaged on one of this parent's requirements, with the
/// requirement they were hired for.
class EngagedTutor {
  const EngagedTutor({required this.job, required this.application});

  final Job job;
  final Application application;

  bool get isRunning => application.isRunning;
  bool get isCompleted => application.isCompleted;
}

/// Everyone teaching for this parent right now, plus anyone recently finished.
///
/// The dashboard's `assigned_tutor` carries three fields — a name, a subject
/// and a photo — which is enough for a hero card and nothing else. This walks
/// the parent's own requirements and pulls the hired application off each, so
/// the fee, the schedule and the start date are all in hand.
///
/// One request per requirement, so it is deliberately not watched from the home
/// screen — only from the screen that needs the detail.
final currentTutorsProvider =
    FutureProvider.autoDispose<List<EngagedTutor>>((ref) async {
  final jobs = await ref.watch(myJobsProvider.future);
  final repo = ref.watch(jobsRepositoryProvider);

  // Only requirements that actually reached a teacher. Asking about the rest
  // would be a request per open job for a list we know is empty of hires.
  final engaged = jobs.where((j) => const {
        'TUTOR_SELECTED',
        'ASSIGNED',
        'CLOSED',
      }.contains(j.status.toUpperCase()));

  final out = <EngagedTutor>[];
  for (final job in engaged) {
    try {
      final applicants = await repo.applicants(job.id);
      for (final a in applicants) {
        if (a.isHired) {
          out.add(EngagedTutor(job: job, application: a));
          break;
        }
      }
    } catch (_) {
      // One unreadable requirement must not blank the whole screen.
    }
  }

  // Running tuitions first — that is what a parent opens this for.
  out.sort((a, b) {
    if (a.isRunning == b.isRunning) return 0;
    return a.isRunning ? -1 : 1;
  });
  return out;
});
