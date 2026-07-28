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
class MyJobsScreen extends ConsumerWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myJobsProvider);
            await ref.read(myJobsProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  children: [
                    EmptyState(
                      icon: Icons.post_add_rounded,
                      title: 'No requirements posted yet',
                      message: 'Tell us what your child needs help with, and we '
                          'will bring matching teachers to you.',
                      actionLabel: 'Post a requirement',
                      onAction: () => context.push('/post-requirement'),
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
