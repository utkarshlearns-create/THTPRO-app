import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/constants/platform_stats.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/models/parent_stats.dart';
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
import 'package:tht_app/features/notifications/providers/notifications_provider.dart';
import 'package:tht_app/features/parent/providers/parent_providers.dart';

/// The parent's home screen.
///
/// A parent opens this to answer one question, and which question it is depends
/// entirely on how far along they are: "has anyone responded yet?", "who is
/// teaching my child?", or "how do I even start?". The hero card answers
/// whichever applies and the rest of the screen supports it.
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
                  SkeletonBox(height: 140, radius: AppRadius.xl),
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
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                _Header(stats: s),
                const SizedBox(height: AppSpacing.lg),
                _Hero(stats: s),
                const SizedBox(height: AppSpacing.lg),
                const _QuickActions(),
                if (s.hasPostedAnything) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _Numbers(stats: s),
                ],
                if (s.recentJobs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _Requirements(jobs: s.recentJobs),
                ],
                if (s.recommendedTutors.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _Recommended(tutors: s.recommendedTutors),
                ],
                if (s.activities.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _Activity(items: s.activities),
                ],
                // Platform claims belong to the empty state only. Next to a
                // parent's own live counts they read as if they were also
                // theirs.
                if (!s.hasPostedAnything) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const _PlatformStrip(),
                ],
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

/// Two rows, not one: three trailing actions plus a name leaves the name a few
/// characters wide on a 360dp screen.
class _Header extends ConsumerWidget {
  const _Header({required this.stats});

  final ParentStats stats;

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
            // Balance comes from the dashboard payload already in hand, so the
            // chip costs no extra request and has no second loading state.
            _CreditsChip(balance: stats.walletBalance),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => context.push('/notifications'),
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
            THTAvatar(
              name: user?.displayName ?? '',
              imageUrl: user?.profilePicture,
              size: 34,
              onTap: () => context.go('/parent-profile'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
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
    );
  }
}

class _CreditsChip extends StatelessWidget {
  const _CreditsChip({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final tone = balance > 0 ? Tone.success : Tone.warning;
    final fg = tone.foreground(brightness);

    return Material(
      color: tone.background(brightness),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: () => context.go('/wallet'),
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: tone.border(brightness)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.toll_rounded, size: 14, color: fg),
              const SizedBox(width: 5),
              Text(
                Fmt.number(balance),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? AppColors.slate100 : fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

/// One card, four states, first match wins.
///
/// A hired teacher outranks waiting applicants, which outrank a live
/// requirement, which outranks having posted nothing. Deliberately silent about
/// how quickly a match will arrive — the website promises that, but this
/// endpoint cannot back it for any individual parent.
class _Hero extends StatelessWidget {
  const _Hero({required this.stats});

  final ParentStats stats;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

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
      child: _body(context, primary),
    );
  }

  Widget _body(BuildContext context, Color primary) {
    final tutor = stats.assignedTutor;

    if (tutor != null) {
      return _HeroLayout(
        eyebrow: 'YOUR TEACHER',
        title: Fmt.titleCase(tutor.name),
        body: tutor.subject.trim().isEmpty
            ? 'Teaching your child now.'
            : 'Teaching ${tutor.subject}.',
        leading: THTAvatar(
          name: tutor.name,
          imageUrl: tutor.imageUrl,
          size: 46,
        ),
        // Straight to the teacher, not to the list of requirements — the
        // arrangement is what a parent with a teacher wants to see.
        primaryLabel: 'View teacher',
        onPrimary: () => context.push('/current-tutor'),
        accent: primary,
      );
    }

    if (stats.applicationsReceived > 0) {
      return _HeroLayout(
        eyebrow: 'WAITING FOR YOU',
        title: Fmt.number(stats.applicationsReceived),
        titleIsNumeral: true,
        body: stats.applicationsReceived == 1
            ? 'teacher has put themselves forward.'
            : 'teachers have put themselves forward.',
        primaryLabel: 'Review them',
        onPrimary: () => context.go('/my-jobs'),
        accent: primary,
      );
    }

    if (stats.hasPostedAnything) {
      return _HeroLayout(
        eyebrow: 'LIVE',
        title: 'Your requirement is out there',
        body: '${Fmt.plural(stats.activeJobs, 'requirement')} open. '
            'You can also go looking yourself.',
        primaryLabel: 'Browse teachers',
        onPrimary: () => context.go('/find-teachers'),
        accent: primary,
      );
    }

    return _HeroLayout(
      eyebrow: 'GET STARTED',
      title: 'Find the right teacher',
      body: 'Tell us what your child needs and we will bring matching '
          'teachers to you — or browse and pick someone yourself.',
      primaryLabel: 'Post a requirement',
      onPrimary: () => context.push('/post-requirement'),
      secondaryLabel: 'Browse teachers',
      onSecondary: () => context.go('/find-teachers'),
      accent: primary,
    );
  }
}

class _HeroLayout extends StatelessWidget {
  const _HeroLayout({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.accent,
    this.titleIsNumeral = false,
    this.leading,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Color accent;

  /// Renders the title as a large figure with the body running on beneath it.
  final bool titleIsNumeral;

  final Widget? leading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Text(
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
            ),
          ],
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
        // Stacked, not side by side. Two buttons sharing a phone's width break
        // "Post a requirement" mid-word once the user has text scaling on, and
        // a label reading "Post a req / uirement" is worse than a taller card.
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onPrimary,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: accent,
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
              child: Text(secondaryLabel!, maxLines: 1),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Quick actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    // Three, not four. A Credits tile would have been this screen's third route
    // to the wallet after the header chip and the bottom bar, and dropping it
    // buys the remaining labels enough width to survive text scaling.
    //
    // Fixed height with Expanded children rather than a GridView with an aspect
    // ratio: a ratio-derived box has no slack when the label wraps.
    return const SizedBox(
      height: 98,
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.post_add_rounded,
              label: 'Post a\nrequirement',
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
              route: '/find-teachers',
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _QuickAction(
              icon: Icons.work_outline_rounded,
              label: 'My\nrequirements',
              tone: Tone.warning,
              route: '/my-jobs',
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
          'Where things stand',
          actionLabel: 'See all',
          onAction: () => context.go('/my-jobs'),
        ),
        const SizedBox(height: AppSpacing.md),
        // IntrinsicHeight rather than a GridView with a fixed aspect ratio. A
        // ratio decides the tile's height before the text is measured, so at
        // large text scale the label was squeezed to nothing and the row
        // rendered as three unlabelled numbers.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  label: 'Live',
                  value: Fmt.number(stats.activeJobs),
                  icon: Icons.work_outline_rounded,
                  tone: Tone.info,
                  onTap: () => context.go('/my-jobs'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  label: 'Applicants',
                  value: Fmt.number(stats.applicationsReceived),
                  icon: Icons.people_outline_rounded,
                  tone: stats.applicationsReceived > 0
                      ? Tone.success
                      : Tone.neutral,
                  onTap: () => context.go('/my-jobs'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Parsed since the model was written, never shown until now.
              Expanded(
                child: StatTile(
                  label: 'Hired',
                  value: Fmt.number(stats.hiredCount),
                  icon: Icons.handshake_outlined,
                  tone: stats.hiredCount > 0 ? Tone.success : Tone.neutral,
                  onTap: () => context.go('/my-jobs'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Requirements ─────────────────────────────────────────────────────────────

/// The parent's own posted requirements.
///
/// `recentJobs` has been in this payload and parsed by the model all along
/// without ever reaching the screen.
class _Requirements extends StatelessWidget {
  const _Requirements({required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    final shown = jobs.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Your requirements',
          icon: Icons.work_outline_rounded,
          iconTone: Tone.info,
          actionLabel: 'See all',
          onAction: () => context.go('/my-jobs'),
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _RequirementRow(job: shown[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final glyph =
        job.subjects.isEmpty ? '📘' : SubjectGlyph.of(job.subjects.first);

    return InkWell(
      onTap: () => context.go('/my-jobs/${job.id}'),
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
                    job.summaryLine.isEmpty
                        ? 'Tuition requirement'
                        : job.summaryLine,
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
                        ? 'No applicants yet'
                        : Fmt.plural(job.applicationCount, 'applicant'),
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
          icon: Icons.person_search_rounded,
          iconTone: Tone.success,
          actionLabel: 'Browse all',
          onAction: () => context.go('/find-teachers'),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 186,
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
      width: 176,
      child: THTCard(
        onTap: () => context.push('/tutors/${tutor.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            THTAvatar(
              name: tutor.name,
              imageUrl: tutor.imageUrl,
              size: 44,
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
              tutor.subjects.isEmpty
                  ? 'Teacher'
                  : Fmt.list(tutor.subjects, max: 2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, height: 1.35, color: muted),
            ),
            if (tutor.locality.trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 12, color: muted),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      tutor.locality,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: muted),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            // No rating here. The recommendation endpoint returns a hardcoded
            // 4.8 for every teacher, which the model refuses to parse for that
            // reason — see RecommendedTutor.
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

// ── Platform strip ───────────────────────────────────────────────────────────

/// Marketing figures, shown only to a parent with nothing of their own yet.
class _PlatformStrip extends StatelessWidget {
  const _PlatformStrip();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ON THE HOME TUITIONS',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: isDark ? AppColors.slate500 : AppColors.slate400,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  child: _PlatformCell(
                    value: PlatformStats.verifiedTutors,
                    label: PlatformStats.verifiedTutorsLabel,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.slate200,
                ),
                const Expanded(
                  child: _PlatformCell(
                    value: PlatformStats.studentsHelped,
                    label: PlatformStats.studentsHelpedLabel,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.slate200,
                ),
                const Expanded(
                  child: _PlatformCell(
                    value: PlatformStats.averageRating,
                    label: PlatformStats.averageRatingLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatformCell extends StatelessWidget {
  const _PlatformCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: isDark ? AppColors.slate50 : AppColors.slate900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            height: 1.3,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
      ],
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
        const SectionHeader(
          'Recent activity',
          icon: Icons.history_rounded,
          iconTone: Tone.neutral,
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1),
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
