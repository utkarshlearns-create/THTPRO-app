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

final tutorApplicationsProvider =
    FutureProvider.autoDispose<List<Application>>(
  (ref) => ref.watch(jobsRepositoryProvider).tutorApplications(),
);

/// The stage tab currently selected.
final applicationStageProvider =
    StateProvider.autoDispose<ApplicationStage>((ref) => ApplicationStage.all);
