import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/parent_stats.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/stat_tile.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/notifications/providers/notifications_provider.dart';
import 'package:tht_app/features/parent/providers/parent_providers.dart';

/// The parent's home screen.
///
/// A parent opens this to answer one of two questions depending on where they
/// are: "has anyone responded to my requirement yet?" or, if they have not
/// posted one, "how do I find a teacher?" The screen leads with whichever
/// applies.
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(parentStatsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => refreshParentHome(ref),
          child: AsyncView<ParentStats>(
            value: stats,
            onRetry: () => ref.invalidate(parentStatsProvider),
            loading: const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  SkeletonBox(height: 120, radius: AppRadius.xl),
                  SizedBox(height: AppSpacing.xl),
                  SkeletonTiles(count: 3, crossAxisCount: 3),
                  SizedBox(height: AppSpacing.xl),
                  SkeletonList(count: 2),
                ],
              ),
            ),
            data: (s) => ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.base,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                const _Header(),
                const SizedBox(height: AppSpacing.lg),
                if (s.hasPostedAnything) ...[
                  _Numbers(stats: s),
                  const SizedBox(height: AppSpacing.xl),
                  if (s.assignedTutor != null) ...[
                    _AssignedTutor(tutor: s.assignedTutor!),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ] else ...[
                  const _GetStarted(),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (s.recommendedTutors.isNotEmpty) ...[
                  _Recommended(tutors: s.recommendedTutors),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (s.activities.isNotEmpty) _Activity(items: s.activities),
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

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Fmt.titleCase(user?.displayName ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.15,
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        IconButton(
          onPressed: () => context.go('/notifications'),
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

// ── First run ────────────────────────────────────────────────────────────────

class _GetStarted extends StatelessWidget {
  const _GetStarted();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryOrange, AppColors.primaryOrangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find the right teacher',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Tell us what your child needs and we will bring matching teachers '
            'to you — or browse and pick someone yourself.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/post-requirement'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryOrangeDark,
                  ),
                  child: const Text('Post a requirement'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/find-teachers'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  child: const Text('Browse teachers'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Numbers ──────────────────────────────────────────────────────────────────

class _Numbers extends StatelessWidget {
  const _Numbers({required this.stats});

  final ParentStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Your requirements',
          actionLabel: 'See all',
          onAction: () => context.go('/my-jobs'),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.95,
          children: [
            StatTile(
              label: 'Live',
              value: Fmt.number(stats.activeJobs),
              icon: Icons.work_outline_rounded,
              tone: Tone.info,
              onTap: () => context.go('/my-jobs'),
            ),
            StatTile(
              label: 'Teachers interested',
              value: Fmt.number(stats.applicationsReceived),
              icon: Icons.people_outline_rounded,
              tone: stats.applicationsReceived > 0 ? Tone.success : Tone.neutral,
              onTap: () => context.go('/my-jobs'),
            ),
            StatTile(
              label: 'Credits',
              value: Fmt.number(stats.walletBalance),
              icon: Icons.account_balance_wallet_outlined,
              tone: stats.walletBalance > 0 ? Tone.neutral : Tone.warning,
              onTap: () => context.go('/wallet'),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Assigned teacher ─────────────────────────────────────────────────────────

class _AssignedTutor extends StatelessWidget {
  const _AssignedTutor({required this.tutor});

  final HiredTutor tutor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return THTCard(
      onTap: () => context.go('/my-jobs'),
      background: Tone.success.background(brightness),
      borderColor: Tone.success.border(brightness),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Tone.success.foreground(brightness).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              Fmt.initials(tutor.name),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Tone.success.foreground(brightness),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your teacher',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Tone.success.foreground(brightness),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Fmt.titleCase(tutor.name)} · ${tutor.subject}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Tone.success.foreground(brightness),
          ),
        ],
      ),
    );
  }
}

// ── Recommended ──────────────────────────────────────────────────────────────

class _Recommended extends StatelessWidget {
  const _Recommended({required this.tutors});

  final List<RecommendedTutor> tutors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Teachers near you',
          subtitle: 'Matched to your area and experience',
          actionLabel: 'Browse all',
          onAction: () => context.go('/find-teachers'),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: tutors.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) => _RecommendedCard(tutor: tutors[i]),
          ),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.tutor});

  final RecommendedTutor tutor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return SizedBox(
      width: 172,
      child: THTCard(
        onTap: () => context.push('/tutors/${tutor.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primaryOrangeLight,
                shape: BoxShape.circle,
              ),
              child: Text(
                Fmt.initials(tutor.name),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrangeDark,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              Fmt.titleCase(tutor.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate50 : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tutor.subjects.isEmpty ? 'Teacher' : Fmt.list(tutor.subjects, max: 2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, height: 1.35, color: muted),
            ),
            const Spacer(),
            if (tutor.experienceYears > 0)
              Pill(
                '${Fmt.plural(tutor.experienceYears, 'yr')} exp',
                dense: true,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Activity ─────────────────────────────────────────────────────────────────

class _Activity extends StatelessWidget {
  const _Activity({required this.items});

  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    Tone toneFor(String type) {
      switch (type.toLowerCase()) {
        case 'success':
          return Tone.success;
        case 'warning':
          return Tone.warning;
        case 'error':
          return Tone.critical;
        default:
          return Tone.info;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Recent activity'),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.slate200,
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: toneFor(items[i].type).foreground(brightness),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].description,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        Fmt.relative(items[i].at),
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark ? AppColors.slate500 : AppColors.slate400,
                        ),
                      ),
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
