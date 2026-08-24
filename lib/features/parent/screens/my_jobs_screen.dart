import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/parent/providers/parent_providers.dart';

/// The requirements this parent has posted, and where each one stands.
///
/// Live and finished are separated. They used to share one list, so a closed
/// requirement from months ago sat between two active ones and a parent had to
/// read every status pill to find what still needed them.
class MyJobsScreen extends ConsumerStatefulWidget {
  const MyJobsScreen({super.key});

  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen> {
  bool _showPast = false;

  /// A requirement nobody is going to act on again.
  static bool _isFinished(Job job) => const {'CLOSED', 'CANCELLED', 'REJECTED'}
      .contains(job.status.toUpperCase());

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(myJobsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My requirements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/post-requirement'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post a requirement'),
      ),
      body: AsyncView<List<Job>>(
        value: jobs,
        onRetry: () => ref.invalidate(myJobsProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 120),
        ),
        data: (all) {
          final live = all.where((j) => !_isFinished(j)).toList();
          final past = all.where(_isFinished).toList();
          final list = _showPast ? past : live;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myJobsProvider);
              await ref.read(myJobsProvider.future);
            },
            child: all.isEmpty
                ? ListView(
                    children: [
                      EmptyState(
                        icon: Icons.post_add_rounded,
                        title: 'No requirements posted yet',
                        message:
                            'Tell us what your child needs help with, and we '
                            'will bring matching teachers to you.',
                        actionLabel: 'Post a requirement',
                        onAction: () => context.push('/post-requirement'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      // Only worth the space once something has actually closed.
                      if (past.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          child: SegmentedButton<bool>(
                            segments: [
                              ButtonSegment(
                                value: false,
                                label: Text('Live · ${live.length}'),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Past · ${past.length}'),
                              ),
                            ],
                            selected: {_showPast},
                            showSelectedIcon: false,
                            onSelectionChanged: (v) =>
                                setState(() => _showPast = v.first),
                          ),
                        ),
                      Expanded(
                        child: list.isEmpty
                            ? ListView(
                                children: [
                                  EmptyState(
                                    icon: _showPast
                                        ? Icons.history_rounded
                                        : Icons.post_add_rounded,
                                    title: _showPast
                                        ? 'Nothing closed yet'
                                        : 'No live requirements',
                                    message: _showPast
                                        ? 'Requirements you close move here.'
                                        : 'Post one and matching teachers will '
                                            'start applying.',
                                    compact: true,
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.base,
                                  AppSpacing.lg,
                                  // Room for the floating button not to cover the last card.
                                  AppSpacing.massive + AppSpacing.xl,
                                ),
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (_, i) => _JobCard(job: list[i]),
                              ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final students = job.allStudents;

    return THTCard(
      onTap: () => context.push('/my-jobs/${job.id}'),
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
                      job.subjects.isEmpty
                          ? 'Tuition required'
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
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (students.isNotEmpty) students.join(', '),
                        if (job.classGrade.isNotEmpty) job.classGrade,
                        if (job.board.isNotEmpty) job.board,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pill(_statusLabel(job), tone: _statusTone(job), dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.people_outline_rounded, size: 15, color: muted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  job.applicationCount == 0
                      ? 'No teachers yet'
                      : '${Fmt.plural(job.applicationCount, 'teacher')} interested',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: job.applicationCount > 0
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: job.applicationCount > 0
                        ? Tone.success.foreground(Theme.of(context).brightness)
                        : muted,
                  ),
                ),
              ),
              if (job.postedAt != null)
                Text(
                  Fmt.relative(job.postedAt),
                  style: TextStyle(fontSize: 11.5, color: muted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// What the job's status means to the parent who posted it, not the raw enum.
  String _statusLabel(Job job) {
    switch (job.status.toUpperCase()) {
      case 'PENDING_APPROVAL':
        return 'Being checked';
      case 'APPROVED':
      case 'ACTIVE':
        return 'Live';
      case 'TUTOR_SELECTED':
        return 'Teacher chosen';
      case 'ASSIGNED':
        return 'Teacher assigned';
      case 'MODIFICATIONS_NEEDED':
        return 'Needs changes';
      case 'REJECTED':
        return 'Not accepted';
      case 'CLOSED':
        return job.isCompleted ? 'Completed' : 'Closed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return Fmt.status(job.status);
    }
  }

  Tone _statusTone(Job job) {
    switch (job.status.toUpperCase()) {
      case 'APPROVED':
      case 'ACTIVE':
      case 'ASSIGNED':
      case 'TUTOR_SELECTED':
        return Tone.success;
      case 'PENDING_APPROVAL':
      case 'MODIFICATIONS_NEEDED':
        return Tone.warning;
      case 'REJECTED':
      case 'CANCELLED':
        return Tone.critical;
      default:
        return Tone.neutral;
    }
  }
}
