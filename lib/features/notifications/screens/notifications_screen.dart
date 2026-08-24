import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/app_notification.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
// The ToneColors extension is only in scope where tone.dart is imported
// directly — receiving a Tone through a model is not enough.
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/notifications/providers/notifications_provider.dart';

/// Alerts for whoever is signed in — the same screen serves every role.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = notifications.valueOrNull?.where((n) => !n.isRead).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => _markAllRead(context, ref),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: AsyncView<List<AppNotification>>(
        value: notifications,
        onRetry: () => ref.invalidate(notificationsProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 5, itemHeight: 72),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
            ref.invalidate(unreadCountProvider);
            await ref.read(notificationsProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  children: const [
                    EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'Nothing yet',
                      message: 'Updates about your jobs, verification and '
                          'credits will appear here.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.base,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _NotificationCard(
                    notification: list[i],
                    onTap: () => _open(context, ref, list[i]),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    final route = n.route;

    // Mark read optimistically — the read state is not worth blocking the tap
    // on, and a failure here changes nothing the user asked for.
    if (!n.isRead) {
      ref.read(jobsRepositoryProvider).markNotificationRead(n.id).then((_) {
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadCountProvider);
      }).catchError((_) {});
    }

    if (route != null && context.mounted) context.push(route);
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(jobsRepositoryProvider).markAllNotificationsRead();
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
    } catch (e) {
      if (context.mounted) context.showFailure(e);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final n = notification;
    final tone = n.tone;

    return THTCard(
      onTap: onTap,
      // An unread item is tinted rather than badged: the whole row is the
      // signal, so the list reads at a glance.
      background: n.isRead
          ? null
          : (isDark
              ? AppColors.slate800
              // Follows the scheme — parents see this screen in blue.
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.07)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tone.background(brightness),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(n.icon, size: 17, color: tone.foreground(brightness)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title.trim().isEmpty ? 'Update' : n.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                    height: 1.35,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                if (n.message.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    n.message.trim(),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: isDark ? AppColors.slate300 : AppColors.slate600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  Fmt.relative(n.createdAt),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          if (n.route != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? AppColors.slate400 : AppColors.slate400,
            ),
        ],
      ),
    );
  }
}
