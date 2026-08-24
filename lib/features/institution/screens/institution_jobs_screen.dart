import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/faculty_vacancy.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/institution/providers/institution_providers.dart';

/// Both kinds of job an institute has, kept apart.
///
/// **Tuition Requirements** are posted by the THT team on the institute's
/// behalf — the institute watches them and can close one. **Faculty Vacancies**
/// are the institute's own hiring board. They are different models on different
/// endpoints with colliding ids, so they never share a list.
class InstitutionJobsScreen extends ConsumerWidget {
  const InstitutionJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(institutionOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My jobs')),
      floatingActionButton: FloatingActionButton.extended(
        // A faculty vacancy — the only job an institute posts itself. Tuition
        // requirements arrive from the THT team.
        onPressed: () => context.push('/inst-post-vacancy'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post a vacancy'),
      ),
      body: AsyncView<({List<Job> requirements, List<FacultyVacancy> vacancies})>(
        value: overview,
        onRetry: () => refreshInstitutionDashboard(ref),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 120),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => refreshInstitutionDashboard(ref),
          child: data.requirements.isEmpty && data.vacancies.isEmpty
              ? ListView(
                  children: [
                    EmptyState(
                      icon: Icons.work_outline_rounded,
                      title: 'Nothing here yet',
                      message: 'Your THT team will post tuition requirements '
                          'here on your behalf. You can also post a faculty '
                          'vacancy yourself.',
                      actionLabel: 'Post a vacancy',
                      onAction: () => context.push('/inst-post-vacancy'),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.base,
                    AppSpacing.lg,
                    AppSpacing.massive + AppSpacing.xl,
                  ),
                  children: [
                    if (data.requirements.isNotEmpty) ...[
                      const SectionHeader(
                        'Tuition requirements',
                        icon: Icons.school_outlined,
                        iconTone: Tone.info,
                        subtitle: 'Posted and managed by your THT team',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final job in data.requirements) ...[
                        _RequirementCard(job: job),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    SectionHeader(
                      'Faculty vacancies',
                      icon: Icons.badge_outlined,
                      iconTone: Tone.accent,
                      subtitle: 'Posted by you',
                      actionLabel:
                          data.vacancies.isEmpty ? null : 'Post another',
                      onAction: data.vacancies.isEmpty
                          ? null
                          : () => context.push('/inst-post-vacancy'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (data.vacancies.isEmpty)
                      THTCard(
                        onTap: () => context.push('/inst-post-vacancy'),
                        child: const EmptyState(
                          icon: Icons.post_add_rounded,
                          title: 'No vacancies posted',
                          message: 'Hiring teaching staff? Post the role and '
                              'teachers can apply to you directly.',
                          compact: true,
                        ),
                      )
                    else
                      for (final v in data.vacancies) ...[
                        _VacancyCard(vacancy: v),
                        const SizedBox(height: AppSpacing.md),
                      ],
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Tuition requirement ──────────────────────────────────────────────────────

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({required this.job});

  final Job job;

  /// What each pipeline state means to the institute reading it.
  ///
  /// `TUTOR_SELECTED` is the one worth being careful about: it means a demo is
  /// scheduled, **not** that anyone is hired. Hiring is `ASSIGNED`.
  static (String, Tone) _status(String raw) {
    switch (raw.toUpperCase()) {
      case 'PENDING_APPROVAL':
        return ('Under review', Tone.warning);
      case 'MODIFICATIONS_NEEDED':
        return ('Needs changes', Tone.warning);
      case 'APPROVED':
        return ('Live · taking applications', Tone.success);
      case 'ACTIVE':
        return ('Live', Tone.success);
      case 'TUTOR_SELECTED':
        return ('Demo scheduled', Tone.info);
      case 'ASSIGNED':
        return ('Teacher hired', Tone.success);
      case 'CLOSED':
        return ('Closed', Tone.neutral);
      case 'CANCELLED':
        return ('Cancelled', Tone.neutral);
      case 'REJECTED':
        return ('Not approved', Tone.critical);
      default:
        return (Fmt.status(raw), Tone.neutral);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final (label, tone) = _status(job.status);

    final title = job.studentName.trim().isNotEmpty
        ? job.studentName
        : [
            if (job.classGrade.isNotEmpty) job.classGrade,
            if (job.subjects.isNotEmpty) Fmt.list(job.subjects),
          ].join(' — ');

    return THTCard(
      onTap: () => context.push('/inst-jobs/${job.id}'),
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
                      title.isEmpty ? 'Tuition requirement' : title,
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
                      job.summaryLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pill(label, tone: tone, dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Pill('JD-${job.id}', dense: true),
              if (job.locality.isNotEmpty)
                Pill(job.locality, icon: Icons.place_outlined, dense: true),
              if (job.feeLabel != null)
                Pill(
                  job.feeLabel!,
                  tone: Tone.success,
                  icon: Icons.payments_outlined,
                  dense: true,
                ),
              Pill(
                job.applicationCount == 0
                    ? 'No applicants yet'
                    : Fmt.plural(job.applicationCount, 'applicant'),
                tone: job.applicationCount > 0 ? Tone.info : Tone.neutral,
                icon: Icons.people_outline_rounded,
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Faculty vacancy ──────────────────────────────────────────────────────────

class _VacancyCard extends StatelessWidget {
  const _VacancyCard({required this.vacancy});

  final FacultyVacancy vacancy;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return THTCard(
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
                      vacancy.title.isEmpty
                          ? 'Teaching vacancy'
                          : vacancy.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    if (vacancy.summaryLine.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        vacancy.summaryLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pill(
                vacancy.isOpen ? 'Open' : 'Closed',
                tone: vacancy.isOpen ? Tone.success : Tone.neutral,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Pill(
                vacancy.jobTypeLabel,
                tone: Tone.accent,
                icon: Icons.schedule_outlined,
                dense: true,
              ),
              if (vacancy.salaryRange.trim().isNotEmpty)
                Pill(
                  vacancy.salaryRange.trim(),
                  tone: Tone.success,
                  icon: Icons.payments_outlined,
                  dense: true,
                ),
              if (vacancy.createdAt != null)
                Pill(
                  'Posted ${Fmt.relative(vacancy.createdAt).toLowerCase()}',
                  dense: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
