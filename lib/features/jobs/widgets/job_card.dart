import 'package:flutter/material.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';

/// One requirement in the teacher's feed.
///
/// A teacher scanning this list is deciding one thing: is this worth a credit?
/// So the card leads with what they teach and where, then the fee, then how much
/// competition there already is.
class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, this.onTap});

  final Job job;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return THTCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A class block, so the feed scans down the left edge by what is
              // being taught rather than by a wall of subject names.
              _ClassBlock(job: job),
              const SizedBox(width: AppSpacing.md),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (job.board.isNotEmpty) job.board,
                        job.modeLabel,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (job.hasApplied)
                const Pill('Applied', tone: Tone.info, icon: Icons.check_rounded, dense: true)
              else if (job.isContactUnlocked)
                const Pill('Unlocked', tone: Tone.success, icon: Icons.lock_open_rounded, dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.locality.isEmpty ? 'Location not specified' : job.locality,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: muted),
                ),
              ),
            ],
          ),
          if (job.feeLabel != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 14, color: muted),
                const SizedBox(width: 4),
                Text(
                  job.feeLabel!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isDark ? AppColors.slate100 : AppColors.slate800,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (job.isInstituteJob)
                const Pill('Institute', tone: Tone.accent, dense: true),
              if (job.isMultiChild)
                Pill(
                  '${job.allStudents.length} students',
                  tone: Tone.neutral,
                  icon: Icons.groups_outlined,
                  dense: true,
                ),
              if (job.genderMismatch)
                Pill(
                  'Wants a ${job.tutorGenderPreference.toLowerCase()} teacher',
                  tone: Tone.warning,
                  icon: Icons.info_outline,
                  dense: true,
                ),
              Pill(
                job.applicationCount == 0
                    ? 'No applicants yet'
                    : Fmt.plural(job.applicationCount, 'applicant'),
                tone: job.applicationCount == 0 ? Tone.success : Tone.neutral,
                dense: true,
              ),
            ],
          ),
          if (job.postedAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Posted ${Fmt.relative(job.postedAt).toLowerCase()}',
              style: TextStyle(fontSize: 11.5, color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// The class this job is for, as a block on the leading edge.
class _ClassBlock extends StatelessWidget {
  const _ClassBlock({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // A lead nobody has applied to is the one worth a teacher's attention.
    final tone = job.hasApplied
        ? Tone.neutral
        : job.applicationCount == 0
            ? Tone.success
            : Tone.info;

    final grade = job.classGrade.trim();
    final short = grade.isEmpty
        ? '—'
        : grade.replaceAll(RegExp(r'^Class\s+', caseSensitive: false), '');

    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: tone.background(brightness),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            'CLASS',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              height: 1,
              color: tone.foreground(brightness).withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            short,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: tone.foreground(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
