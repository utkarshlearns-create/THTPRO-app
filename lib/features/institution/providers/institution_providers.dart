import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/faculty_vacancy.dart';
import 'package:tht_app/core/models/institution_profile.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/repositories/users_repository.dart';

/// The institute's own record. Auto-created server-side on first read.
final institutionProfileProvider =
    FutureProvider.autoDispose<InstitutionProfile>(
  (ref) => ref.watch(usersRepositoryProvider).institutionProfile(),
);

/// Tuition requirements the THT team posted for this institute.
///
/// The institute is the client on these, not the author — it monitors them and
/// may close them, but demos and hiring are run by its relationship manager.
final tuitionRequirementsProvider = FutureProvider.autoDispose<List<Job>>(
  (ref) => ref.watch(jobsRepositoryProvider).institutionTuitionRequirements(),
);

/// Faculty vacancies the institute posted itself.
final facultyVacanciesProvider =
    FutureProvider.autoDispose<List<FacultyVacancy>>(
  (ref) => ref.watch(jobsRepositoryProvider).facultyVacancies(),
);

/// What the search box on Browse Teachers currently holds.
final teacherSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Teachers suited to institute work.
///
/// Filtered server-side to verified, active teachers who opted in to institute
/// teaching and have school or coaching experience — so this never fetches the
/// global tutor pool.
final institutionTutorsProvider =
    FutureProvider.autoDispose<List<PublicTutor>>((ref) {
  final query = ref.watch(teacherSearchQueryProvider);
  return ref.watch(usersRepositoryProvider).institutionTutors(query: query);
});

/// Both job lists at once, for the dashboard's headline counts.
///
/// The counts span the two kinds — active tuition requirements plus open
/// vacancies — so the screen needs both resolved before it can add them up.
final institutionOverviewProvider = FutureProvider.autoDispose<
    ({List<Job> requirements, List<FacultyVacancy> vacancies})>((ref) async {
  final requirements = await ref.watch(tuitionRequirementsProvider.future);
  final vacancies = await ref.watch(facultyVacanciesProvider.future);
  return (requirements: requirements, vacancies: vacancies);
});

/// Reloads everything behind the institute dashboard.
Future<void> refreshInstitutionDashboard(WidgetRef ref) async {
  ref
    ..invalidate(institutionProfileProvider)
    ..invalidate(tuitionRequirementsProvider)
    ..invalidate(facultyVacanciesProvider);
  try {
    await ref.read(institutionOverviewProvider.future);
  } catch (_) {
    // Each section renders its own failure; one bad list must not abort the
    // pull-to-refresh for the others.
  }
}
