import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/institution_profile.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/repositories/users_repository.dart';

/// The institute's own profile.
final institutionProfileProvider =
    FutureProvider.autoDispose<InstitutionProfile>(
  (ref) => ref.watch(usersRepositoryProvider).institutionProfile(),
);

/// Requirements this institute has posted.
final institutionJobsProvider = FutureProvider.autoDispose<List<Job>>(
  (ref) => ref.watch(jobsRepositoryProvider).institutionJobs(),
);

/// What the teacher directory is currently being searched for.
final teacherSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Active teachers the institute can browse, filtered by the search box.
final institutionTutorsProvider =
    FutureProvider.autoDispose<List<PublicTutor>>((ref) {
  final query = ref.watch(teacherSearchQueryProvider);
  return ref.watch(usersRepositoryProvider).institutionTutors(query: query);
});

/// Reloads everything behind the institute dashboard.
Future<void> refreshInstitutionHome(WidgetRef ref) async {
  ref
    ..invalidate(institutionProfileProvider)
    ..invalidate(institutionJobsProvider);
  try {
    await ref.read(institutionProfileProvider.future);
  } catch (_) {
    // Each section renders its own failure through AsyncView.
  }
}
