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
import 'package:tht_app/features/institution/providers/institution_providers.dart';

/// Vacancies the institute has posted, and how many teachers want each one.
class InstitutionJobsScreen extends ConsumerWidget {
  const InstitutionJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(institutionJobsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Requirements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/post-requirement'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post a requirement'),
      ),
      body: AsyncView<List<Job>>(
        value: jobs,
        onRetry: () => ref.invalidate(institutionJobsProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 120),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(institutionJobsProvider);
            await ref.read(institutionJobsProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  children: [
                    EmptyState(
                      icon: Icons.post_add_rounded,
                      title: 'No requirements posted',
                      message: 'Tell us the vacancy you need to fill and we '
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

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
                          ? 'Teaching vacancy'
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
                        if (job.classGrade.isNotEmpty) job.classGrade,
                        if (job.board.isNotEmpty) job.board,
                        if (job.locality.isNotEmpty) job.locality,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pill(
                Fmt.status(job.status),
                tone: toneForStatus(job.status),
                dense: true,
              ),
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
                        ? Tone.success.foreground(brightness)
                        : muted,
                  ),
                ),
              ),
              if (job.feeLabel != null)
                Text(
                  job.feeLabel!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isDark ? AppColors.slate200 : AppColors.slate700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
