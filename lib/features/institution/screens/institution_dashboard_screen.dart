import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/institution_profile.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/stat_tile.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/institution/providers/institution_providers.dart';
import 'package:tht_app/features/notifications/providers/notifications_provider.dart';

/// The institute's home screen.
///
/// An institute opens the app to fill a vacancy, so the screen leads with the
/// requirements they have open and how many teachers have come forward.
class InstitutionDashboardScreen extends ConsumerWidget {
  const InstitutionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(institutionProfileProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => refreshInstitutionHome(ref),
          child: AsyncView<InstitutionProfile>(
            value: profile,
            onRetry: () => ref.invalidate(institutionProfileProvider),
            loading: const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  SkeletonBox(height: 90, radius: AppRadius.lg),
                  SizedBox(height: AppSpacing.xl),
                  SkeletonTiles(count: 2),
                  SizedBox(height: AppSpacing.xl),
                  SkeletonList(count: 2),
                ],
              ),
            ),
            data: (p) => ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.base,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                _Header(profile: p),
                const SizedBox(height: AppSpacing.lg),
                if (p.weakestSpot != null) ...[
                  _ProfilePrompt(profile: p),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const _Numbers(),
                const SizedBox(height: AppSpacing.xl),
                const _OpenRequirements(),
              ]
                  .animate(interval: 60.ms)
                  .fadeIn(duration: 260.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.profile});

  final InstitutionProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your institute',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile.hasName ? profile.name : 'Set up your institute',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Pill(
                profile.isVerified ? 'Verified institute' : 'Not verified yet',
                tone: profile.isVerified ? Tone.success : Tone.warning,
                icon: profile.isVerified
                    ? Icons.verified_rounded
                    : Icons.shield_outlined,
                dense: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        IconButton(
          onPressed: () => context.go('/inst-notifications'),
          tooltip: unread > 0
              ? 'Notifications, $unread unread'
              : 'Notifications, none unread',
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 9 ? '9+' : '$unread'),
            backgroundColor: AppColors.error,
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    );
  }
}

class _ProfilePrompt extends StatelessWidget {
  const _ProfilePrompt({required this.profile});

  final InstitutionProfile profile;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return THTCard(
      onTap: () => context.go('/inst-profile'),
      background: Tone.warning.background(brightness),
      borderColor: Tone.warning.border(brightness),
      child: Row(
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 20,
            color: Tone.warning.foreground(brightness),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finish your profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Tone.warning.foreground(brightness),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.weakestSpot!,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Tone.warning
                        .foreground(brightness)
                        .withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Tone.warning.foreground(brightness),
          ),
        ],
      ),
    );
  }
}

class _Numbers extends ConsumerWidget {
  const _Numbers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(institutionJobsProvider);

    return AsyncView<List<Job>>(
      value: jobs,
      onRetry: () => ref.invalidate(institutionJobsProvider),
      loading: const SkeletonTiles(count: 2),
      compactError: true,
      data: (list) {
        final open = list
            .where((j) => const {'APPROVED', 'ACTIVE', 'PENDING_APPROVAL'}
                .contains(j.status.toUpperCase()))
            .length;
        final applicants =
            list.fold<int>(0, (sum, j) => sum + j.applicationCount);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.45,
          children: [
            StatTile(
              label: 'Open requirements',
              value: Fmt.number(open),
              icon: Icons.work_outline_rounded,
              tone: Tone.info,
              onTap: () => context.go('/inst-jobs'),
            ),
            StatTile(
              label: 'Teachers interested',
              value: Fmt.number(applicants),
              icon: Icons.people_outline_rounded,
              tone: applicants > 0 ? Tone.success : Tone.neutral,
              caption: applicants > 0 ? 'across all requirements' : null,
              onTap: () => context.go('/inst-jobs'),
            ),
          ],
        );
      },
    );
  }
}

class _OpenRequirements extends ConsumerWidget {
  const _OpenRequirements();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(institutionJobsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Your requirements',
          actionLabel: 'See all',
          onAction: () => context.go('/inst-jobs'),
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncView<List<Job>>(
          value: jobs,
          onRetry: () => ref.invalidate(institutionJobsProvider),
          loading: const SkeletonList(count: 2),
          compactError: true,
          data: (list) => list.isEmpty
              ? THTCard(
                  child: EmptyState(
                    icon: Icons.post_add_rounded,
                    title: 'No requirements posted',
                    message: 'Post a vacancy and we will bring matching '
                        'teachers to you.',
                    actionLabel: 'Post a requirement',
                    onAction: () => context.push('/post-requirement'),
                    compact: true,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < list.take(3).length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      THTCard(
                        onTap: () => context.push('/my-jobs/${list[i].id}'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    list[i].subjects.isEmpty
                                        ? 'Teaching vacancy'
                                        : Fmt.list(list[i].subjects),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.slate50
                                          : AppColors.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    list[i].applicationCount == 0
                                        ? 'No teachers yet'
                                        : '${Fmt.plural(list[i].applicationCount, 'teacher')} interested',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? AppColors.slate400
                                          : AppColors.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
