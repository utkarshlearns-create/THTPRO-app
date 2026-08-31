import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/application.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/jobs/providers/job_search_provider.dart';
import 'package:tht_app/features/tutor/providers/applications_provider.dart';

/// Everything that has happened to one application, in order.
///
/// A sheet rather than a screen on purpose. It is opened from the job the
/// application belongs to, and the job is the context that makes it readable —
/// pushing a route would take that away, and the applications list lives
/// inside the tutor shell, which a job detail cannot push into.
///
/// **Only the teacher's own journey is here.** The co-applicants payload
/// carries names, scores and ranks but no demo or rejection state for anyone
/// else, so "who else went to a demo" is not a question this app can answer
/// without inventing it. What it can say about the others — how many there
/// are, where this teacher sits, and whether somebody has been hired — is at
/// the foot of the sheet.
class ApplicationTimelineSheet extends ConsumerWidget {
  const ApplicationTimelineSheet({super.key, required this.jobId});

  final int jobId;

  static Future<void> show(BuildContext context, int jobId) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ApplicationTimelineSheet(jobId: jobId),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final application = ref.watch(applicationForJobProvider(jobId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate700 : AppColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.base,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Your progress on this job',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.slate50 : AppColors.slate900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<Application?>(
              value: application,
              onRetry: () => ref.invalidate(tutorApplicationsProvider),
              compactError: true,
              data: (a) {
                if (a == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'We could not find your application for this job. '
                        'Pull the job screen down to refresh.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, height: 1.55),
                      ),
                    ),
                  );
                }

                final steps = _stepsFor(a);
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    Pill(a.stageLabel, tone: _toneFor(a), dense: true),
                    const SizedBox(height: AppSpacing.lg),
                    for (var i = 0; i < steps.length; i++)
                      _Step(
                        step: steps[i],
                        isFirst: i == 0,
                        isLast: i == steps.length - 1,
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    _Standing(jobId: jobId),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Tone _toneFor(Application a) {
    if (a.isCompleted) return Tone.success;
    if (a.isClosed) return Tone.critical;
    if (a.isHired) return Tone.success;
    if (a.hasUpcomingDemo) return Tone.info;
    return Tone.neutral;
  }

  /// The journey — the whole of it, every time.
  ///
  /// Showing only what has happened leaves a fresh application looking like a
  /// dead end: one tick and nothing else. The stages ahead are drawn too, in
  /// grey, so a teacher can see the road and where on it they are standing.
  ///
  /// Nothing is invented. A stage is *done* only when the server recorded
  /// something for it, *current* where the application is actually sitting,
  /// and *upcoming* otherwise — never ticked on hope.
  List<_TimelineStep> _stepsFor(Application a) {
    final steps = <_TimelineStep>[];
    final closed = a.isClosed;

    // 1 — Applied. Always done; it is why this sheet exists.
    steps.add(_TimelineStep(
      title: 'You applied',
      when: a.createdAt,
      detail: a.coverMessage.trim().isEmpty ? null : a.coverMessage.trim(),
      state: _StepState.done,
      icon: Icons.send_rounded,
    ));

    // 2 — The family looking through applicants.
    final pastReview =
        a.isShortlisted || a.isHired || a.demoDate != null || a.isDemoDone;
    steps.add(_TimelineStep(
      title: pastReview ? 'The family shortlisted you' : 'With the family',
      state: pastReview
          ? _StepState.done
          : (closed ? _StepState.upcoming : _StepState.current),
      icon: pastReview ? Icons.star_rounded : Icons.hourglass_empty_rounded,
      detail: pastReview
          ? null
          : closed
              ? null
              : 'They are going through everyone who applied. Our team nudges '
                  'them, and you will be told the moment anything moves.',
    ));

    // 3 — Demo.
    if (a.isDemoDone || a.demoCompletedAt != null) {
      steps.add(_TimelineStep(
        title: 'Demo done',
        when: a.demoCompletedAt ?? a.demoDate,
        detail: a.demoRemarks.trim().isEmpty ? null : a.demoRemarks.trim(),
        state: _StepState.done,
        icon: Icons.check_circle_rounded,
      ));
    } else if (a.demoDate != null) {
      final booked = a.isDemoBooked;
      steps.add(_TimelineStep(
        title: booked ? 'Demo confirmed' : 'Demo slot proposed',
        when: a.demoDate,
        detail: booked
            ? 'The family has agreed to this slot. Turn up, and the lead is '
                'yours to win.'
            : 'Waiting for the family to accept this slot.',
        state: _StepState.current,
        icon: Icons.event_available_rounded,
      ));
    } else {
      steps.add(const _TimelineStep(
        title: 'Demo',
        detail: 'Our team arranges this once the family shortlists you.',
        state: _StepState.upcoming,
        icon: Icons.event_rounded,
      ));
    }

    if (a.demoRejectionReason.trim().isNotEmpty) {
      steps.add(_TimelineStep(
        title: 'The family declined the demo',
        detail: a.demoRejectionReason.trim(),
        state: _StepState.bad,
        icon: Icons.cancel_rounded,
      ));
    }

    if (a.parentApproved) {
      steps.add(const _TimelineStep(
        title: 'The family reviewed you',
        state: _StepState.done,
        icon: Icons.rate_review_rounded,
      ));
    }

    // 4 — Hired, or the reason it stopped.
    if (a.isHired) {
      final fee = a.finalizedAmount;
      steps.add(_TimelineStep(
        title: 'You were hired',
        when: a.tuitionStartDate,
        detail: fee == null
            ? null
            : 'Agreed fee ₹${Fmt.number(fee)} a month. THT keeps half of the '
                'first month; from the second the whole fee is yours.',
        state: _StepState.done,
        icon: Icons.workspace_premium_rounded,
      ));
    } else if (!closed) {
      steps.add(const _TimelineStep(
        title: 'Hired',
        detail: 'The family picks one teacher after the demos.',
        state: _StepState.upcoming,
        icon: Icons.workspace_premium_outlined,
      ));
    }

    // 5 — Where it is now, or where it ended.
    if (a.isRunning) {
      steps.add(const _TimelineStep(
        title: 'Teaching',
        detail: 'Mark your attendance after each class.',
        state: _StepState.current,
        icon: Icons.cast_for_education_rounded,
      ));
    }

    if (a.isCompleted) {
      steps.add(_TimelineStep(
        title: 'Tuition completed',
        when: a.completedAt,
        detail: a.parentFeedback.trim().isEmpty
            ? null
            : 'The family said: "${a.parentFeedback.trim()}"',
        state: _StepState.done,
        icon: Icons.emoji_events_rounded,
      ));
    }

    if (closed) {
      steps.add(_TimelineStep(
        title: a.status.toUpperCase() == 'REJECTED'
            ? 'The family went elsewhere'
            : 'Not selected for this one',
        detail: a.closureReason.trim().isEmpty
            ? 'It happens on most leads. The teachers who get hired are '
                'usually the ones applying quickly and often.'
            : a.closureReason.trim(),
        state: _StepState.bad,
        icon: Icons.do_not_disturb_on_rounded,
      ));
    }

    return steps;
  }
}

enum _StepState { done, current, upcoming, bad }

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.state,
    required this.icon,
    this.when,
    this.detail,
  });

  final String title;
  final _StepState state;
  final IconData icon;
  final DateTime? when;
  final String? detail;
}

class _Step extends StatelessWidget {
  const _Step({
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  final _TimelineStep step;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final line = isDark ? AppColors.darkBorder : AppColors.slate200;

    final tone = switch (step.state) {
      _StepState.done => Tone.success,
      _StepState.current => Tone.info,
      _StepState.bad => Tone.critical,
      _StepState.upcoming => Tone.neutral,
    };
    final tint = tone.foreground(brightness);
    final faded = step.state == _StepState.upcoming;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The rail: a dot for this step, a line running to the next.
          Column(
            children: [
              Container(
                width: 2,
                height: 6,
                color: isFirst ? Colors.transparent : line,
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: faded
                      ? (isDark ? AppColors.slate800 : AppColors.slate100)
                      : tone.background(brightness),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: faded ? line : tint.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  step.icon,
                  size: 15,
                  color: faded ? muted : tint,
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: line)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 8,
                bottom: isLast ? 0 : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: faded
                          ? muted
                          : (isDark ? AppColors.slate50 : AppColors.slate900),
                    ),
                  ),
                  if (step.when != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      Fmt.dateTime(step.when!),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: tint,
                      ),
                    ),
                  ],
                  if (step.detail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.detail!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where this teacher sits among everyone who applied.
///
/// Deliberately thin: the co-applicants payload has no demo or rejection state
/// for anybody else, so this says how many there are, where the teacher ranks
/// and whether the job has gone — and nothing it cannot back.
class _Standing extends ConsumerWidget {
  const _Standing({required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(coApplicantsProvider(jobId)).valueOrNull;
    if (data == null) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final hired = data.hired;

    final lines = <String>[
      if (data.totalCount > 0)
        '${Fmt.plural(data.totalCount, 'teacher')} applied for this tuition.',
      if (data.myRank != null) 'You were number ${data.myRank} to apply.',
      if (hired != null && !hired.isMe)
        'The family has chosen someone else for this one.',
    ];
    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.slate100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.groups_rounded, size: 16, color: muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              lines.join(' '),
              style: TextStyle(fontSize: 12.5, height: 1.5, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
