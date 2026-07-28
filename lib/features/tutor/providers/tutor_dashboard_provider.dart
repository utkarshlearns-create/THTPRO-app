import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/kyc_status.dart';
import 'package:tht_app/core/models/tuition.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/models/tutor_score.dart';
import 'package:tht_app/core/models/tutor_stats.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/features/wallet/providers/wallet_providers.dart';

export 'package:tht_app/features/wallet/providers/wallet_providers.dart'
    show walletProvider;

/// The teacher's headline numbers.
final tutorStatsProvider = FutureProvider.autoDispose<TutorStats>(
  (ref) => ref.watch(usersRepositoryProvider).tutorStats(),
);

/// Today's teaching, with per-tuition attendance state.
final todayScheduleProvider = FutureProvider.autoDispose<TodaySchedule>(
  (ref) => ref.watch(jobsRepositoryProvider).todaySchedule(),
);

/// The teacher's own profile record.
final tutorProfileProvider = FutureProvider.autoDispose<TutorProfile>(
  (ref) => ref.watch(usersRepositoryProvider).tutorProfile(),
);

/// The teacher's platform score and rank badge. Null until they have been
/// scored — a new teacher has no rating rather than a bad one.
final tutorScoreProvider = FutureProvider.autoDispose<TutorScore?>(
  (ref) => ref.watch(usersRepositoryProvider).myScore(),
);

/// Verification state, for the header pill and the KYC prompt.
final kycStatusProvider = FutureProvider.autoDispose<KycStatus>(
  (ref) => ref.watch(usersRepositoryProvider).kycStatus(),
);

/// Leads the teacher has already paid to see but not yet acted on.
final unlockedLeadsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(usersRepositoryProvider).unlockedLeads(),
);

/// Badge count on the notification bell.
final unreadNotificationsProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(jobsRepositoryProvider).unreadNotificationCount(),
);

/// Refreshes everything behind the teacher dashboard at once.
///
/// Pull-to-refresh should reload the whole screen, not whichever card the
/// finger happened to land on.
Future<void> refreshTutorDashboard(WidgetRef ref) async {
  ref
    ..invalidate(tutorStatsProvider)
    ..invalidate(todayScheduleProvider)
    ..invalidate(walletProvider)
    ..invalidate(kycStatusProvider)
    ..invalidate(unlockedLeadsProvider)
    ..invalidate(unreadNotificationsProvider);

  await Future.wait([
    ref.read(tutorStatsProvider.future),
    ref.read(todayScheduleProvider.future),
    ref.read(walletProvider.future),
  ]).catchError((_) => <Object>[]);
}
