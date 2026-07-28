import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/app_notification.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';

/// Every notification for the signed-in user, newest first.
final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>(
  (ref) => ref.watch(jobsRepositoryProvider).notifications(),
);

/// The unread count behind the bell badge. Shared by every role.
final unreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(jobsRepositoryProvider).unreadNotificationCount(),
);
