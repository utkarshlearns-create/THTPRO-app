import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';

/// How the teacher wants their pipeline narrowed.
enum ApplicationStage { all, awaiting, demo, teaching, closed }

extension ApplicationStageX on ApplicationStage {
  String get label {
    switch (this) {
      case ApplicationStage.all:
        return 'All';
      case ApplicationStage.awaiting:
        return 'Awaiting';
      case ApplicationStage.demo:
        return 'Demos';
      case ApplicationStage.teaching:
        return 'Teaching';
      case ApplicationStage.closed:
        return 'Closed';
    }
  }

  bool matches(Application a) {
    switch (this) {
      case ApplicationStage.all:
        return true;
      case ApplicationStage.awaiting:
        return (a.isAwaiting || a.isShortlisted) && !a.hasUpcomingDemo;
      case ApplicationStage.demo:
        return a.hasUpcomingDemo;
      case ApplicationStage.teaching:
        return a.isRunning || (a.isHired && !a.isCompleted);
      case ApplicationStage.closed:
        return a.isClosed || a.isCompleted;
    }
  }
}

final tutorApplicationsProvider = FutureProvider.autoDispose<List<Application>>(
  (ref) => ref.watch(jobsRepositoryProvider).tutorApplications(),
);

/// This teacher's application against one job, or null if they have not
/// applied to it.
///
/// Derived from the list rather than fetched: there is no per-application
/// endpoint, and the list is already loaded wherever this is needed.
final applicationForJobProvider =
    FutureProvider.autoDispose.family<Application?, int>((ref, jobId) async {
  final all = await ref.watch(tutorApplicationsProvider.future);
  for (final a in all) {
    if (a.jobId == jobId) return a;
  }
  return null;
});

/// The stage tab currently selected.
final applicationStageProvider =
    StateProvider.autoDispose<ApplicationStage>((ref) => ApplicationStage.all);
