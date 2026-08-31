import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/features/tutor/providers/applications_provider.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// The teacher's pipeline: everything they've applied to and where it stands.
class TutorApplicationsScreen extends ConsumerWidget {
  const TutorApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(tutorApplicationsProvider);
    final stage = ref.watch(applicationStageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My applications')),
      body: AsyncView<List<Application>>(
        value: applications,
        onRetry: () => ref.invalidate(tutorApplicationsProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 4, itemHeight: 110),
        ),
        data: (all) {
          if (all.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(tutorApplicationsProvider),
              child: ListView(
                children: [
                  EmptyState(
                    icon: Icons.description_outlined,
                    title: "You haven't applied to anything yet",
                    message: 'Unlock a lead from the job feed and your name goes '
                        'forward for that tuition. It will show up here.',
                    actionLabel: 'Find jobs',
                    // The teacher's own feed tab, not the public route — this is
                    // inside their shell.
                    onAction: () => context.go('/tutor-jobs'),
                  ),
                ],
              ),
            );
          }

          final shown = all.where(stage.matches).toList();

          return Column(
            children: [
              const _UpcomingDemos(),
              _StageTabs(
                all: all,
                selected: stage,
                onSelect: (s) =>
                    ref.read(applicationStageProvider.notifier).state = s,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(tutorApplicationsProvider),
                  child: shown.isEmpty
                      ? ListView(
                          children: [
                            EmptyState(
                              icon: Icons.filter_list_off_rounded,
                              title: 'Nothing at this stage',
                              message: _emptyForStage(stage),
                              compact: true,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.xxxl,
                          ),
                          itemCount: shown.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) =>
                              _ApplicationCard(application: shown[i]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _emptyForStage(ApplicationStage stage) {
    switch (stage) {
      case ApplicationStage.awaiting:
        return 'No applications are waiting on a reply right now.';
      case ApplicationStage.demo:
        return 'No demos are booked. When a family accepts one, it appears here.';
      case ApplicationStage.teaching:
        return "You aren't teaching any tuitions from these applications yet.";
      case ApplicationStage.closed:
        return 'Nothing has been closed or completed yet.';
      case ApplicationStage.all:
        return 'Nothing to show.';
    }
  }
}

// ── Stage tabs ───────────────────────────────────────────────────────────────

class _StageTabs extends StatelessWidget {
  const _StageTabs({
    required this.all,
    required this.selected,
    required this.onSelect,
  });

  final List<Application> all;
  final ApplicationStage selected;
  final ValueChanged<ApplicationStage> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          for (final stage in ApplicationStage.values) ...[
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(
                child: ChoiceChip(
                  label: Text(
                    '${stage.label} · ${all.where(stage.matches).length}',
                  ),
                  selected: stage == selected,
                  onSelected: (_) => onSelect(stage),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        stage == selected ? FontWeight.w700 : FontWeight.w500,
                    color: stage == selected
                        ? AppColors.primaryOrangeDark
                        : null,
                  ),
                  selectedColor: AppColors.primaryOrangeLight,
                  side: stage == selected
                      ? const BorderSide(color: AppColors.primaryOrange)
                      : BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkBorder
                              : AppColors.slate200,
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Demos our team has put on the calendar.
///
/// `GET /api/jobs/tutor/demos/` was fetched by nobody. A demo is the single
/// most time-critical thing in a teacher's week — missing one loses the
/// tuition — so it gets a strip above the pipeline rather than being buried in
/// a status line further down.
class _UpcomingDemos extends ConsumerWidget {
  const _UpcomingDemos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demos = ref.watch(tutorDemosProvider).valueOrNull;
    if (demos == null) return const SizedBox.shrink();

    // Only what is still ahead. A completed demo belongs in the pipeline
    // below, not in a banner asking the teacher to attend it.
    final upcoming = demos.where((d) => d.hasUpcomingDemo).toList()
      ..sort((a, b) {
        final at = a.demoDate, bt = b.demoDate;
        if (at == null) return 1;
        if (bt == null) return -1;
        return at.compareTo(bt);
      });
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: THTCard(
        background: Tone.info.background(brightness),
        borderColor: Tone.info.border(brightness),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 17,
                  color: Tone.info.foreground(brightness),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  upcoming.length == 1
                      ? 'You have a demo coming up'
                      : '${upcoming.length} demos coming up',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Tone.info.foreground(brightness),
                  ),
                ),
              ],
            ),
            for (final demo in upcoming.take(3)) ...[
              const SizedBox(height: 6),
              Text(
                '${demo.job?.contextLine.isNotEmpty == true ? '${demo.job!.contextLine} — ' : ''}'
                '${Fmt.dateTime(demo.demoDate)}',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Tone.info.foreground(brightness).withValues(alpha: 0.95),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Application card ─────────────────────────────────────────────────────────

class _ApplicationCard extends ConsumerStatefulWidget {
  const _ApplicationCard({required this.application});

  final Application application;

  @override
  ConsumerState<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends ConsumerState<_ApplicationCard> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.application;
    final job = a.job;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return THTCard(
      onTap: () => context.push('/jobs/${a.jobId}'),
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
                      job == null || job.subjects.isEmpty
                          ? 'Tuition'
                          : Fmt.list(job.subjects),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    if (job != null && job.contextLine.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        job.contextLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pill(a.stageLabel, tone: toneForStatus(a.toneKey), dense: true),
            ],
          ),

          // The one thing that matters next, if there is one.
          if (_nextStep(a) case final step?) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(step.$1, size: 14, color: step.$3.foreground(Theme.of(context).brightness)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    step.$2,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: step.$3.foreground(Theme.of(context).brightness),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (a.earning != null && (a.isHired || a.isCompleted))
                Pill(
                  '${Fmt.rupees(a.earning)} your share',
                  tone: Tone.success,
                  icon: Icons.payments_outlined,
                  dense: true,
                ),
              if (a.isCompleted || a.isRunning)
                Pill.status(a.paymentStatus, dense: true),
              if (a.tutorPaid)
                const Pill('Paid out', tone: Tone.success, dense: true),
              if (a.createdAt != null)
                Pill(
                  'Applied ${Fmt.relative(a.createdAt).toLowerCase()}',
                  dense: true,
                ),
            ],
          ),

          if (a.isRestricted && a.restrictionReason.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              a.restrictionReason.trim(),
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Tone.critical.foreground(Theme.of(context).brightness),
              ),
            ),
          ],

          ..._actions(a),
        ],
      ),
    );
  }

  /// The single next action or fact worth surfacing on the card.
  (IconData, String, Tone)? _nextStep(Application a) {
    if (a.hasUpcomingDemo && a.demoDate != null) {
      final when = Fmt.dateTime(a.demoDate);
      return a.demoStatus.toUpperCase() == 'ACCEPTED'
          ? (Icons.event_available_outlined, 'Demo on $when — please attend', Tone.info)
          : (Icons.event_outlined, 'Demo proposed for $when', Tone.warning);
    }
    if (a.isRunning) {
      return (
        Icons.school_outlined,
        a.tuitionStartDate == null
            ? 'Tuition running — mark attendance after each session'
            : 'Teaching since ${Fmt.date(a.tuitionStartDate)}',
        Tone.success,
      );
    }
    if (a.isCompleted) {
      return (
        Icons.check_circle_outline_rounded,
        a.completedAt == null
            ? 'Tuition completed'
            : 'Completed ${Fmt.date(a.completedAt)}',
        Tone.success,
      );
    }
    if (a.status.toUpperCase() == 'REJECTED' &&
        a.demoRejectionReason.trim().isNotEmpty) {
      return (Icons.info_outline, a.demoRejectionReason.trim(), Tone.critical);
    }
    if (a.isAwaiting) {
      return (
        Icons.hourglass_empty_rounded,
        'Waiting on the family to respond',
        Tone.warning,
      );
    }
    return null;
  }

  /// The one thing the teacher can do about this application from here.
  ///
  /// The screen used to be entirely read-only, which stalled two flows: a demo
  /// nobody marks as taken leaves the parent's approve button refused, and a
  /// finished tuition that is never closed keeps counting against the
  /// active-tuition cap that blocks new applications.
  List<Widget> _actions(Application a) {
    if (a.isDemoBooked && !a.isDemoDone) {
      return [
        const SizedBox(height: AppSpacing.base),
        _ActionButton(
          icon: Icons.task_alt_rounded,
          label: 'I have taken the demo',
          busy: _working,
          onPressed: _completeDemo,
        ),
      ];
    }

    if (a.isRunning) {
      return [
        const SizedBox(height: AppSpacing.base),
        _ActionButton(
          icon: Icons.flag_outlined,
          label: 'End this tuition',
          busy: _working,
          onPressed: _endTuition,
        ),
      ];
    }

    return const [];
  }

  Future<void> _completeDemo() async {
    final ok = await _ask(
      title: 'Mark the demo as taken?',
      body: 'We will tell the family so they can give their feedback. Only do '
          'this once you have actually taken the class.',
      confirmLabel: 'Yes, I took it',
    );
    if (ok != true) return;

    await _run(
      () => ref
          .read(jobsRepositoryProvider)
          .completeDemo(widget.application.id),
      success: 'Demo recorded. The family has been asked for their feedback.',
    );
  }

  Future<void> _endTuition() async {
    final ok = await _ask(
      title: 'End this tuition?',
      body: 'Mark it finished once your last session is done. It stops '
          'counting towards your active-tuition limit, which frees you to '
          'apply for new jobs.',
      confirmLabel: 'End it',
    );
    if (ok != true) return;

    await _run(
      () => ref.read(jobsRepositoryProvider).endTuition(widget.application.id),
      success: 'Tuition closed. Your payout is settled at month end.',
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() => _working = true);
    try {
      await action();
      if (!mounted) return;
      ref
        ..invalidate(tutorApplicationsProvider)
        ..invalidate(tutorStatsProvider)
        ..invalidate(todayScheduleProvider);
      context.showMessage(success);
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<bool?> _ask({
    required String title,
    required String body,
    required String confirmLabel,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not yet'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: busy ? null : () => onPressed(),
          icon: busy
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 17),
          label: Text(label),
        ),
      );
}

