import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/tutor_score.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// Where the teacher stands, and what it is made of.
///
/// `/api/ranking/me/` was already being fetched for the badge on the home
/// screen and everything else in it thrown away — the total, the city rank, the
/// attendance record and all seven module scores. This is that payload, shown.
class TutorScoreScreen extends ConsumerWidget {
  const TutorScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(tutorScoreProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your score')),
      body: AsyncView<TutorScore?>(
        value: score,
        onRetry: () => ref.invalidate(tutorScoreProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              SkeletonBox(height: 160, radius: AppRadius.xl),
              SizedBox(height: AppSpacing.lg),
              SkeletonList(count: 4, itemHeight: 64),
            ],
          ),
        ),
        data: (s) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tutorScoreProvider);
            await ref.read(tutorScoreProvider.future);
          },
          child: s == null
              ? ListView(
                  children: const [
                    EmptyState(
                      icon: Icons.workspace_premium_outlined,
                      title: 'No score yet',
                      message: 'Your rating starts once you have taken a demo '
                          'and taught your first month.',
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.base,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  children: _body(context, s),
                ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, TutorScore s) {
    final scored = s.modules.where((m) => m.value != null).toList();
    final unscored = s.modules.where((m) => m.value == null).toList();

    return [
      _Headline(score: s),
      const SizedBox(height: AppSpacing.xl),

      if (s.attendancePercent != null || s.lateCount > 0 || s.absentCount > 0)
        ...[
        const SectionHeader(
          'Your record',
          icon: Icons.event_available_outlined,
          iconTone: Tone.info,
        ),
        const SizedBox(height: AppSpacing.md),
        _Attendance(score: s),
        const SizedBox(height: AppSpacing.xl),
      ],

      SectionHeader(
        'What the score is made of',
        icon: Icons.donut_small_rounded,
        iconTone: Tone.accent,
        subtitle: s.modulesPresent > 0
            ? '${Fmt.plural(s.modulesPresent, 'area')} measured so far'
            : null,
      ),
      const SizedBox(height: AppSpacing.md),

      if (scored.isEmpty)
        const NoteBox(
          tone: Tone.info,
          message: 'Nothing has been measured yet. Take a demo and your first '
              'scores appear here.',
        )
      else
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < scored.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _ModuleRow(module: scored[i]),
              ],
            ],
          ),
        ),

      if (unscored.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.base),
        // Named rather than hidden: a teacher who cannot see what is unmeasured
        // has no way to know what would raise their score.
        NoteBox(
          tone: Tone.neutral,
          title: 'Not measured yet',
          message: '${unscored.map((m) => m.label).join(', ')}. '
              'Your total is scaled across the areas that have been scored, '
              'so a blank one never counts against you.',
        ),
      ],

      if (s.lastCalculatedAt != null) ...[
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'Last updated ${Fmt.relative(s.lastCalculatedAt).toLowerCase()}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.slate400
                  : AppColors.slate500,
            ),
          ),
        ),
      ],
    ];
  }
}

// ── Headline ─────────────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  const _Headline({required this.score});

  final TutorScore score;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tone = _tone;
    final rated = score.isRated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tone.background(brightness),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: tone.border(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                // A teacher with no score sees a dash, never a zero — the two
                // mean opposite things.
                rated ? score.totalScore!.toStringAsFixed(0) : '—',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: tone.foreground(brightness),
                ),
              ),
              if (rated) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tone.foreground(brightness).withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Pill(
                score.badgeLabel,
                tone: tone,
                icon: Icons.workspace_premium_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            score.standing,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: tone.foreground(brightness).withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }

  Tone get _tone {
    switch (score.badge.toUpperCase()) {
      case 'ELITE':
      case 'PRO':
        return Tone.success;
      case 'RISING':
        return Tone.accent;
      case 'NEEDS_IMPROVEMENT':
        return Tone.warning;
      default:
        return Tone.neutral;
    }
  }
}

// ── Attendance ───────────────────────────────────────────────────────────────

class _Attendance extends StatelessWidget {
  const _Attendance({required this.score});

  final TutorScore score;

  @override
  Widget build(BuildContext context) {
    final percent = score.attendancePercent;

    return THTCard(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Figure(
              value: percent == null ? '—' : '${percent.toStringAsFixed(0)}%',
              label: 'Sessions attended',
              tone: percent == null
                  ? Tone.neutral
                  : percent >= 90
                      ? Tone.success
                      : percent >= 75
                          ? Tone.warning
                          : Tone.critical,
            ),
            const _Rule(),
            _Figure(
              value: '${score.lateCount}',
              label: 'Late',
              tone: score.lateCount > 0 ? Tone.warning : Tone.neutral,
            ),
            const _Rule(),
            _Figure(
              value: '${score.absentCount}',
              label: 'Missed',
              tone: score.absentCount > 0 ? Tone.critical : Tone.neutral,
            ),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return VerticalDivider(
      width: AppSpacing.md,
      thickness: 1,
      color: isDark ? AppColors.slate800 : AppColors.slate200,
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.value,
    required this.label,
    required this.tone,
  });

  final String value;
  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: tone == Tone.neutral
                  ? (isDark ? AppColors.slate50 : AppColors.slate900)
                  : tone.foreground(brightness),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── One module ───────────────────────────────────────────────────────────────

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.module});

  final ({String label, double? value, String hint}) module;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final value = module.value ?? 0;
    final fraction = (value / 100).clamp(0.0, 1.0);

    final tone = value >= 75
        ? Tone.success
        : value >= 50
            ? Tone.warning
            : Tone.critical;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  module.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate100 : AppColors.slate800,
                  ),
                ),
              ),
              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: tone.foreground(brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: isDark ? AppColors.slate800 : AppColors.slate200,
              valueColor:
                  AlwaysStoppedAnimation(tone.foreground(brightness)),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            module.hint,
            style: TextStyle(fontSize: 12, height: 1.4, color: muted),
          ),
        ],
      ),
    );
  }
}
