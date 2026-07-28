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
import 'package:tht_app/features/tutor/providers/applications_provider.dart';

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
                    onAction: () => context.go('/find-jobs'),
                  ),
                ],
              ),
            );
          }

          final shown = all.where(stage.matches).toList();

          return Column(
            children: [
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

// ── Application card ─────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final a = application;
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
}
