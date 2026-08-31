import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/chance_detail.dart';
import 'package:tht_app/features/jobs/providers/job_search_provider.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/tone.dart';

/// Where a teacher's hiring chance on one lead comes from.
///
/// The percentage on its own is a verdict with no recourse. The point of this
/// sheet is the opposite: show which of the six pillars cost the points, so
/// the number becomes something a teacher can act on rather than something
/// that happens to them.
class ChanceSheet extends ConsumerWidget {
  const ChanceSheet({
    super.key,
    required this.jobId,
    required this.tutorProfileId,
  });

  final int jobId;
  final int tutorProfileId;

  static Future<void> show(
    BuildContext context, {
    required int jobId,
    required int tutorProfileId,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) =>
            ChanceSheet(jobId: jobId, tutorProfileId: tutorProfileId),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(chanceDetailProvider((jobId, tutorProfileId)));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AsyncView<ChanceDetail>(
          value: detail,
          onRetry: () =>
              ref.invalidate(chanceDetailProvider((jobId, tutorProfileId))),
          loading: const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          data: (d) => _body(context, d, isDark),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ChanceDetail d, bool isDark) {
    final brightness = Theme.of(context).brightness;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final pct = d.percentage;
    final tone = toneForChance(pct);

    return Column(
      mainAxisSize: MainAxisSize.min,
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
                    'Your chances here',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.slate50 : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'How well you fit what this family asked for.',
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ],
              ),
            ),
            if (pct != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tone.background(brightness),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${pct.round()}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: tone.foreground(brightness),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        if (!d.hasBreakdown)
          const NoteBox(
            tone: Tone.info,
            message: 'No breakdown available for this lead yet.',
          )
        else ...[
          for (final p in d.pillars) ...[
            _PillarRow(pillar: p),
            const SizedBox(height: AppSpacing.md),
          ],
          if (d.weakest case final weak?) ...[
            const SizedBox(height: AppSpacing.sm),
            NoteBox(
              tone: Tone.info,
              title: 'Where you lose the most here',
              message: _advice(weak),
            ),
          ],
        ],

        const SizedBox(height: AppSpacing.base),
        Text(
          'This is a guide, not a decision. Families choose for their own '
          'reasons, and a lower score has still won plenty of tuitions.',
          style: TextStyle(fontSize: 12, height: 1.45, color: muted),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ),
      ],
    );
  }

  /// What the weakest pillar actually means for this teacher.
  ///
  /// Only says something when there is something to do about it — "location"
  /// is worth a sentence, "class match" on a lead you cannot change is not.
  String _advice(ChancePillar weak) {
    switch (weak.label.toLowerCase()) {
      case 'subject match':
        return 'The subjects on your profile do not fully cover what this '
            'family wants. Adding the ones you do teach helps here and on '
            'every future lead.';
      case 'class match':
        return 'This class is outside the range on your profile. If you do '
            'teach it, add it — otherwise this will keep costing you.';
      case 'experience':
        return 'Experience is counted from your profile. If yours is out of '
            'date, updating it is the quickest gain.';
      case 'qualification':
        return 'Your qualifications and certifications count here. Anything '
            'verified — B.Ed, TET, CTET — moves this.';
      case 'location':
        return 'You are further from this family than most applicants. Adding '
            'the areas you can travel to helps you match nearer leads.';
      case 'salary fit':
        return 'Your expected fee sits outside what this family budgeted. '
            'Worth reviewing if you are seeing this often.';
      default:
        return '${weak.label} is where you lose the most points on this lead.';
    }
  }
}

/// The colour band a chance percentage falls in.
///
/// Shared with the badge on the job screen so the two never disagree.
Tone toneForChance(double? pct) {
  if (pct == null) return Tone.neutral;
  if (pct >= 70) return Tone.success;
  if (pct >= 45) return Tone.warning;
  return Tone.critical;
}

class _PillarRow extends StatelessWidget {
  const _PillarRow({required this.pillar});

  final ChancePillar pillar;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final tone = pillar.isFull
        ? Tone.success
        : pillar.fraction >= 0.5
            ? Tone.warning
            : Tone.critical;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                pillar.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.slate100 : AppColors.slate800,
                ),
              ),
            ),
            Text(
              // Out of the pillar's own ceiling, so the weighting is visible —
              // 6/6 on a small pillar is not the same win as 6/10 on a big one.
              '${_trim(pillar.score)} / ${_trim(pillar.max)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: tone.foreground(brightness),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: pillar.fraction,
            minHeight: 5,
            backgroundColor: isDark ? AppColors.slate800 : AppColors.slate200,
            valueColor: AlwaysStoppedAnimation(tone.foreground(brightness)),
          ),
        ),
        if (!pillar.isFull) ...[
          const SizedBox(height: 3),
          Text(
            '${_trim(pillar.lost)} point${pillar.lost == 1 ? '' : 's'} short',
            style: TextStyle(fontSize: 11.5, color: muted),
          ),
        ],
      ],
    );
  }

  /// Whole numbers where the value is whole — "8" reads better than "8.0".
  String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}
