import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/tuition.dart';
import 'package:tht_app/core/models/tutor_stats.dart';
import 'package:tht_app/core/models/wallet.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/stat_tile.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// The teacher's home screen.
///
/// Ordered by what a teacher opens the app to find out, in order: can I still
/// unlock leads, what am I teaching today, and how am I doing. Everything on
/// this screen comes from the API — there are no placeholder numbers, because a
/// dashboard that invents its figures is worse than no dashboard.
class TutorHomeScreen extends ConsumerWidget {
  const TutorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => refreshTutorDashboard(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.base,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              const _Header(),
              const SizedBox(height: AppSpacing.lg),
              const _CreditsCard(),
              const SizedBox(height: AppSpacing.xl),
              const _VerificationPrompt(),
              const _TodaySection(),
              const SizedBox(height: AppSpacing.xl),
              const _NumbersSection(),
              const SizedBox(height: AppSpacing.xl),
              const _EarningsSection(),
              const SizedBox(height: AppSpacing.xl),
              const _QuickActions(),
            ]
                .animate(interval: 60.ms)
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
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
    final kyc = ref.watch(kycStatusProvider).valueOrNull;
    final unread = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
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
              if (kyc != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Pill(
                  kyc.shortLabel,
                  tone: kyc.isVerified
                      ? Tone.success
                      : kyc.isRejected
                          ? Tone.critical
                          : Tone.warning,
                  icon: kyc.isVerified
                      ? Icons.verified_rounded
                      : Icons.shield_outlined,
                  dense: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _NotificationBell(unread: unread),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: unread > 0
          ? 'Notifications, $unread unread'
          : 'Notifications, none unread',
      child: InkWell(
        onTap: () => context.go('/tutor-notifications'),
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.slate200,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 21,
                color: isDark ? AppColors.slate200 : AppColors.slate700,
              ),
              if (unread > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 15),
                    height: 15,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Credits ──────────────────────────────────────────────────────────────────

/// The first question a teacher has on opening the app: can I still unlock the
/// next lead? So the balance leads, and the validity window sits right under it.
class _CreditsCard extends ConsumerWidget {
  const _CreditsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);

    return AsyncView<Wallet>(
      value: wallet,
      onRetry: () => ref.invalidate(walletProvider),
      loading: const SkeletonBox(height: 132, radius: AppRadius.xl),
      compactError: true,
      data: (w) => _CreditsBody(wallet: w),
    );
  }
}

class _CreditsBody extends StatelessWidget {
  const _CreditsBody({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final days = wallet.daysRemaining;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lead credits',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Fmt.number(wallet.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => context.go('/tutor-wallet'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryOrangeDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: const Text('Add credits'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 15, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _validityLine(wallet, days),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _validityLine(Wallet w, int? days) {
    if (!w.validityActivated && w.pendingValidityDays > 0) {
      return '${Fmt.plural(w.pendingValidityDays, 'day')} of validity — the clock '
          'starts when you unlock your first lead.';
    }
    if (w.isExpired) {
      return 'Your plan has expired. Renew to keep unlocking leads.';
    }
    if (days != null) {
      return w.isExpiringSoon
          ? 'Expires in ${Fmt.plural(days, 'day')} — renew to avoid a gap.'
          : 'Valid for another ${Fmt.plural(days, 'day')}.';
    }
    // Unlocking a lead costs nothing up front — the balance is a gate, and a
    // credit is only deducted if the teacher never visits the family. Saying
    // "spend a credit to unlock" would misdescribe the deal they're agreeing to.
    return w.hasCredits
        ? "Unlocking a lead is free. A credit is only deducted if you don't visit."
        : 'Add credits to start unlocking leads — you need at least one.';
  }
}

// ── Verification ─────────────────────────────────────────────────────────────

/// Only appears when there is something for the teacher to do about KYC.
class _VerificationPrompt extends ConsumerWidget {
  const _VerificationPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kyc = ref.watch(kycStatusProvider).valueOrNull;
    final step = kyc?.nextStep;
    if (kyc == null || step == null) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final tone = kyc.isRejected ? Tone.critical : Tone.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: THTCard(
        onTap: () => context.go('/tutor-kyc'),
        background: tone.background(brightness),
        borderColor: tone.border(brightness),
        child: Row(
          children: [
            Icon(
              kyc.isRejected
                  ? Icons.error_outline_rounded
                  : Icons.badge_outlined,
              size: 20,
              color: tone.foreground(brightness),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kyc.shortLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tone.foreground(brightness),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: tone.foreground(brightness).withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: tone.foreground(brightness),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today ────────────────────────────────────────────────────────────────────

class _TodaySection extends ConsumerWidget {
  const _TodaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(todayScheduleProvider);
    final unmarked = schedule.valueOrNull?.unmarked.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          "Today's teaching",
          subtitle: unmarked > 0
              ? '$unmarked still to mark'
              : schedule.valueOrNull?.allMarked == true
                  ? 'All marked — nicely done'
                  : null,
          actionLabel: 'All tuitions',
          onAction: () => context.go('/tutor-schedule'),
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncView<TodaySchedule>(
          value: schedule,
          onRetry: () => ref.invalidate(todayScheduleProvider),
          loading: const SkeletonList(count: 2),
          compactError: true,
          data: (s) => s.tuitions.isEmpty
              ? const THTCard(
                  child: EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No tuitions running today',
                    message:
                        'Once a parent hires you, your sessions show up here '
                        'with a one-tap attendance mark.',
                    compact: true,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < s.tuitions.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      _TuitionCard(tuition: s.tuitions[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _TuitionCard extends StatelessWidget {
  const _TuitionCard({required this.tuition});

  final ActiveTuition tuition;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final students = tuition.allStudents;

    return THTCard(
      onTap: () => context.go('/tutor-schedule'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      students.isEmpty
                          ? 'Student'
                          : students.length == 1
                              ? students.first
                              : '${students.first} +${students.length - 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate100 : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tuition.summaryLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (tuition.markedToday)
                Pill.status(tuition.todayStatus, dense: true)
              else
                const Pill('To mark', tone: Tone.warning, dense: true),
            ],
          ),
          if (tuition.locality.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    tuition.locality,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ),
                if (tuition.sessionsTotal > 0)
                  Text(
                    '${tuition.sessionsPresent}/${tuition.sessionsTotal} sessions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark ? AppColors.slate300 : AppColors.slate600,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Numbers ──────────────────────────────────────────────────────────────────

class _NumbersSection extends ConsumerWidget {
  const _NumbersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(tutorStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Your numbers'),
        const SizedBox(height: AppSpacing.md),
        AsyncView<TutorStats>(
          value: stats,
          onRetry: () => ref.invalidate(tutorStatsProvider),
          loading: const SkeletonTiles(),
          compactError: true,
          data: (s) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.45,
            children: [
              StatTile(
                label: 'Applications sent',
                value: Fmt.number(s.totalApplications),
                icon: Icons.send_outlined,
                tone: Tone.info,
                caption: s.pendingApplications > 0
                    ? '${s.pendingApplications} awaiting reply'
                    : null,
                onTap: () => context.go('/tutor-applications'),
              ),
              StatTile(
                label: 'Tuitions won',
                value: Fmt.number(s.acceptedApplications),
                icon: Icons.handshake_outlined,
                tone: Tone.success,
                caption: s.hireRate == null
                    ? null
                    : '${(s.hireRate! * 100).round()}% success rate',
              ),
              StatTile(
                label: 'Demos scheduled',
                value: Fmt.number(s.demoScheduled),
                icon: Icons.event_outlined,
                tone: Tone.accent,
                onTap: () => context.go('/tutor-schedule'),
              ),
              StatTile(
                label: 'Earned so far',
                value: Fmt.rupeesCompact(s.totalEarned),
                icon: Icons.account_balance_wallet_outlined,
                tone: Tone.success,
                caption: s.completedTuitions > 0
                    ? 'across ${Fmt.plural(s.completedTuitions, 'tuition')}'
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Earnings ─────────────────────────────────────────────────────────────────

class _EarningsSection extends ConsumerWidget {
  const _EarningsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(tutorStatsProvider).valueOrNull;
    if (stats == null || stats.earnings.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recent = stats.earnings.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Earnings',
          subtitle: stats.pendingPayment > 0
              ? '${Fmt.rupees(stats.pendingPayment)} due to you at month end'
              : 'Your share of every completed tuition',
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.slate200,
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recent[i].student.isEmpty
                                  ? 'Tuition'
                                  : recent[i].student,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.slate100
                                    : AppColors.slate900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (recent[i].classGrade.isNotEmpty)
                                  recent[i].classGrade,
                                if (recent[i].completedOn.isNotEmpty)
                                  recent[i].completedOn,
                              ].join(' · '),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Fmt.rupees(recent[i].yourShare),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: isDark
                                  ? AppColors.slate50
                                  : AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Pill.status(recent[i].paymentStatus, dense: true),
                        ],
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

// ── Quick actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Shortcuts'),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.work_outline_rounded,
                label: 'Find jobs',
                route: '/tutor-jobs',
                tone: Tone.accent,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionTile(
                icon: Icons.description_outlined,
                label: 'Applications',
                route: '/tutor-applications',
                tone: Tone.info,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionTile(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                route: '/tutor-profile',
                tone: Tone.neutral,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String route;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return THTCard(
      onTap: () => context.go(route),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.base,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: tone.background(brightness),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 19, color: tone.foreground(brightness)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.slate200 : AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }
}
