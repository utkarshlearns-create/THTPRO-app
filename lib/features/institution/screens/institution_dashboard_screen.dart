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
import 'package:tht_app/core/ui/subject_glyph.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/institution/providers/institution_providers.dart';
import 'package:tht_app/features/notifications/providers/notifications_provider.dart';

/// The institute's home screen.
///
/// An institute opens the app to fill a vacancy, so the screen leads with the
/// vacancies they have open and how many teachers have come forward.
class InstitutionDashboardScreen extends ConsumerWidget {
  const InstitutionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(institutionProfileProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => refreshInstitutionDashboard(ref),
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
                const _Hero(),
                const SizedBox(height: AppSpacing.lg),
                const _QuickActions(),
                if (p.weakestSpot != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ProfilePrompt(profile: p),
                ],
                const SizedBox(height: AppSpacing.xl),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(
                'The Home Tuitions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
            ),
            const Spacer(),
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
            // The institute's own mark, and the way into their profile —
            // matching where a parent finds theirs.
            THTAvatar(
              name: profile.name,
              imageUrl: profile.logoUrl,
              size: 34,
              squared: true,
              onTap: () => context.go('/inst-profile'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
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
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

/// One card, three states, first match wins.
///
/// Everything here is counted from the vacancies the institute has actually
/// posted — there is no institute stats endpoint, so nothing is asserted that
/// the jobs list cannot show.
class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(institutionOverviewProvider).valueOrNull;
    final primary = Theme.of(context).colorScheme.primary;

    // Applicants only ever accrue on tuition requirements — a faculty vacancy
    // has no application pipeline behind it.
    final applicants = data?.requirements
            .fold<int>(0, (sum, j) => sum + j.applicationCount) ??
        0;
    // "Active" spans both kinds: a live tuition requirement and an open
    // vacancy are both something the institute is waiting on.
    final open = (data?.requirements
                .where((j) => const {'APPROVED', 'ACTIVE', 'PENDING_APPROVAL'}
                    .contains(j.status.toUpperCase()))
                .length ??
            0) +
        (data?.vacancies.where((v) => v.isOpen).length ?? 0);

    final String eyebrow;
    final String title;
    final bool titleIsNumeral;
    final String body;
    final String primaryLabel;
    final VoidCallback onPrimary;
    String? secondaryLabel;
    VoidCallback? onSecondary;

    if (applicants > 0) {
      eyebrow = 'WAITING FOR YOU';
      title = Fmt.number(applicants);
      titleIsNumeral = true;
      body = applicants == 1
          ? 'teacher has applied to your tuition requirements.'
          : 'teachers have applied to your tuition requirements.';
      primaryLabel = 'Review them';
      onPrimary = () => context.go('/inst-jobs');
    } else if (open > 0) {
      eyebrow = 'LIVE';
      title = 'Your vacancy is out there';
      titleIsNumeral = false;
      body = '${Fmt.plural(open, 'vacancy', pluralForm: 'vacancies')} open. '
          'You can also go through the teacher directory yourself.';
      primaryLabel = 'Browse teachers';
      onPrimary = () => context.go('/inst-teachers');
    } else {
      eyebrow = 'GET STARTED';
      title = 'Fill your first vacancy';
      titleIsNumeral = false;
      body = 'Post what you are hiring for and we will bring matching '
          'teachers to you — or browse the directory yourself.';
      primaryLabel = 'Post a vacancy';
      onPrimary = () => context.push('/post-requirement');
      secondaryLabel = 'Browse teachers';
      onSecondary = () => context.go('/inst-teachers');
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, Color.lerp(primary, Colors.black, 0.22)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.26),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleIsNumeral ? 40 : 22,
              fontWeight: FontWeight.w800,
              height: titleIsNumeral ? 1 : 1.25,
              letterSpacing: titleIsNumeral ? -1.4 : -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Stacked, not side by side — two buttons sharing a phone's width
          // break their labels mid-word once text scaling is on.
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primary,
              ),
              child: Text(primaryLabel, maxLines: 1),
            ),
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: Text(secondaryLabel, maxLines: 1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Quick actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 98,
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.post_add_rounded,
              label: 'Post a\nvacancy',
              tone: Tone.info,
              route: '/post-requirement',
              push: true,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _QuickAction(
              icon: Icons.person_search_rounded,
              label: 'Find\nteachers',
              tone: Tone.success,
              route: '/inst-teachers',
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _QuickAction(
              icon: Icons.work_outline_rounded,
              label: 'My\nvacancies',
              tone: Tone.warning,
              route: '/inst-jobs',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tone,
    required this.route,
    this.push = false,
  });

  final IconData icon;
  final String label;
  final Tone tone;
  final String route;

  /// The requirement wizard is pushed full-screen; the tabs are switched to.
  final bool push;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return THTCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: AppSpacing.md,
      ),
      onTap: () => push ? context.push(route) : context.go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.background(brightness),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: tone.foreground(brightness)),
          ),
          const SizedBox(height: 7),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: isDark ? AppColors.slate300 : AppColors.slate700,
              ),
            ),
          ),
        ],
      ),
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
    final jobs = ref.watch(tuitionRequirementsProvider);

    return AsyncView<List<Job>>(
      value: jobs,
      onRetry: () => ref.invalidate(tuitionRequirementsProvider),
      loading: const SkeletonTiles(count: 2),
      compactError: true,
      data: (list) {
        final open = list
            .where((j) => const {'APPROVED', 'ACTIVE', 'PENDING_APPROVAL'}
                .contains(j.status.toUpperCase()))
            .length;
        final applicants =
            list.fold<int>(0, (sum, j) => sum + j.applicationCount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              'Where things stand',
              actionLabel: 'See all',
              onAction: () => context.go('/inst-jobs'),
            ),
            const SizedBox(height: AppSpacing.md),
            // IntrinsicHeight rather than a GridView with a fixed aspect
            // ratio. A ratio decides the tile's height before the text is
            // measured, so at large text scale the label was squeezed to
            // nothing and the row rendered as three unlabelled numbers.
            // Intrinsic height sizes to whatever the content actually needs.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Open',
                      value: Fmt.number(open),
                      icon: Icons.work_outline_rounded,
                      tone: Tone.info,
                      onTap: () => context.go('/inst-jobs'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      label: 'Applicants',
                      value: Fmt.number(applicants),
                      icon: Icons.people_outline_rounded,
                      tone: applicants > 0 ? Tone.success : Tone.neutral,
                      onTap: () => context.go('/inst-jobs'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Everything ever posted, counted from the list itself —
                  // there is no institute stats endpoint to ask for more.
                  Expanded(
                    child: StatTile(
                      label: 'Posted',
                      value: Fmt.number(list.length),
                      icon: Icons.history_rounded,
                      tone: Tone.neutral,
                      onTap: () => context.go('/inst-jobs'),
                    ),
                  ),
                ],
              ),
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
    final jobs = ref.watch(tuitionRequirementsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Your vacancies',
          actionLabel: 'See all',
          onAction: () => context.go('/inst-jobs'),
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncView<List<Job>>(
          value: jobs,
          onRetry: () => ref.invalidate(tuitionRequirementsProvider),
          loading: const SkeletonList(count: 2),
          compactError: true,
          data: (list) => list.isEmpty
              ? THTCard(
                  child: EmptyState(
                    icon: Icons.post_add_rounded,
                    title: 'No vacancies posted',
                    message: 'Post a vacancy and we will bring matching '
                        'teachers to you.',
                    actionLabel: 'Post a vacancy',
                    onAction: () => context.push('/post-requirement'),
                    compact: true,
                  ),
                )
              : THTCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < list.take(3).length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _VacancyRow(job: list[i], isDark: isDark),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// One posted vacancy, as a row.
///
/// Mirrors the parent's requirement row so the two audiences read the same
/// shape: a subject glyph, what the vacancy is, how many teachers have come
/// forward, and where it sits in the pipeline.
class _VacancyRow extends StatelessWidget {
  const _VacancyRow({required this.job, required this.isDark});

  final Job job;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final glyph =
        job.subjects.isEmpty ? '📘' : SubjectGlyph.of(job.subjects.first);

    return InkWell(
      onTap: () => context.push('/my-jobs/${job.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : AppColors.slate100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(glyph, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.subjects.isEmpty
                        ? 'Teaching vacancy'
                        : Fmt.list(job.subjects, max: 2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    job.applicationCount == 0
                        ? 'No teachers yet'
                        : '${Fmt.plural(job.applicationCount, 'teacher')} interested',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: job.applicationCount == 0
                          ? muted
                          : Tone.success.foreground(brightness),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (job.status.trim().isNotEmpty)
              Pill.status(job.status, dense: true),
          ],
        ),
      ),
    );
  }
}
