import 'package:flutter/material.dart';
import 'package:tht_app/core/models/job.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/subject_glyph.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';

/// What this lead is to *this* teacher, which is the one thing that decides how
/// the card is coloured.
///
/// Resolved once and spent in three places — the rail, the border and the class
/// block — so the card carries a single signal instead of three independent
/// colour decisions that can drift apart.
enum _LeadState {
  /// Already acted on. Deliberately the quietest state on the card.
  applied,

  /// This teacher holds the parent's contact.
  unlocked,

  /// Nobody has applied. The one worth a teacher's attention.
  uncontested,

  /// Posted in the last day.
  fresh,

  /// Everything else.
  open;

  static _LeadState of(Job job) {
    if (job.hasApplied) return _LeadState.applied;
    if (job.isContactUnlocked) return _LeadState.unlocked;
    if (job.applicationCount == 0) return _LeadState.uncontested;
    final posted = job.postedAt;
    if (posted != null && DateTime.now().difference(posted).inHours < 24) {
      return _LeadState.fresh;
    }
    return _LeadState.open;
  }

  Tone get tone => switch (this) {
        _LeadState.applied => Tone.neutral,
        _LeadState.unlocked => Tone.success,
        _LeadState.uncontested => Tone.success,
        _LeadState.fresh => Tone.accent,
        _LeadState.open => Tone.info,
      };

  /// A tinted border is a highlight, so it has to stay rare. States that need
  /// no action keep the default hairline and recede into the feed.
  bool get highlights =>
      this == _LeadState.unlocked ||
      this == _LeadState.uncontested ||
      this == _LeadState.fresh;
}

/// One requirement in the teacher's feed.
///
/// A teacher scanning this list is deciding one thing: is this worth going to?
/// So the card leads with what they teach, then the money, then where and when,
/// then how much competition there already is.
///
/// Colour is rationed by two rules. Icons carry tint and sentences stay slate,
/// so the only coloured *text* is the fee — and brand orange means "fresh lead"
/// and nothing else, which is why the institute pill is blue.
class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, this.onTap});

  final Job job;
  final VoidCallback? onTap;

  /// The subjects, each behind its own glyph.
  ///
  /// The glyph carries the recognition and the word carries the detail, so the
  /// subjects stay the card's headline rather than being demoted to a chip row
  /// that repeats what the title already said.
  String get _subjectTitle {
    if (job.subjects.isEmpty) return 'Tuition required';
    // Two, not three. The line shares its width with the class block and a
    // status pill, and a third subject pushed the count off the end — leaving
    // "Accoun…", which tells a teacher less than "+3 more" does.
    const max = 2;
    final shown = job.subjects
        .take(max)
        .map((s) => '${SubjectGlyph.of(s)} $s')
        .join(', ');
    final extra = job.subjects.length - max;
    return extra > 0 ? '$shown  +$extra more' : shown;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final state = _LeadState.of(job);
    final accent = state.tone.foreground(brightness);

    return THTCard(
      onTap: onTap,
      // Zero padding so the rail can run the card's height; the content brings
      // its own inset back.
      padding: EdgeInsets.zero,
      borderColor: state.highlights ? state.tone.border(brightness) : null,
      child: Stack(
        children: [
          // A Stack sizes to its non-positioned child, and the rail below is
          // fully constrained — so there is no intrinsic-height pass and no
          // CrossAxisAlignment.stretch, which has crashed this codebase before.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ClassBlock(job: job, tone: state.tone),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _subjectTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: isDark
                                  ? AppColors.slate50
                                  : AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(_modeIcon, size: 13, color: muted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  [
                                    if (job.board.isNotEmpty) job.board,
                                    job.modeLabel,
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      TextStyle(fontSize: 12.5, color: muted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (job.hasApplied)
                      const Pill('Applied',
                          tone: Tone.info,
                          icon: Icons.check_rounded,
                          dense: true)
                    else if (job.isContactUnlocked)
                      const Pill('Unlocked',
                          tone: Tone.success,
                          icon: Icons.lock_open_rounded,
                          dense: true)
                    else if (state == _LeadState.fresh)
                      const Pill('🔥 New', tone: Tone.accent, dense: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _MetaPanel(job: job),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (job.isInstituteJob)
                      // Blue, not orange: orange is the fresh-lead rail now, and
                      // two oranges on one card make both of them mean nothing.
                      const Pill('Institute',
                          tone: Tone.info,
                          icon: Icons.apartment_rounded,
                          dense: true),
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
                      tone: job.applicationCount == 0
                          ? Tone.success
                          : Tone.neutral,
                      icon: job.applicationCount == 0
                          ? Icons.bolt_rounded
                          : Icons.people_alt_outlined,
                      dense: true,
                    ),
                  ],
                ),
                if (job.postedAt != null || job.contactUnlockCount > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      if (job.postedAt != null)
                        Expanded(
                          child: Text(
                            'Posted ${Fmt.relative(job.postedAt).toLowerCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: muted),
                          ),
                        )
                      else
                        const Spacer(),
                      if (job.contactUnlockCount > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.lock_open_rounded, size: 12, color: muted),
                        const SizedBox(width: 4),
                        Text(
                          // Deliberately not "paid": unlocking costs nothing up
                          // front, so a count of unlocks is not a count of spends.
                          '${job.contactUnlockCount} already have this contact',
                          style: TextStyle(fontSize: 11.5, color: muted),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 7,
            top: 14,
            bottom: 14,
            width: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    state.highlights ? accent : accent.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _modeIcon {
    switch (job.tuitionMode.toUpperCase()) {
      case 'HOME':
        return Icons.home_outlined;
      case 'ONLINE_ONE_TO_ONE':
      case 'ONLINE_GROUP':
        return Icons.videocam_outlined;
      case 'INSTITUTION':
        return Icons.apartment_rounded;
      case 'BOTH':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.school_outlined;
    }
  }
}

// ── The practical facts ──────────────────────────────────────────────────────

/// The money first, then where and when.
class _MetaPanel extends StatelessWidget {
  const _MetaPanel({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    final schedule = [
      if (job.preferredTime.trim().isNotEmpty) job.preferredTime.trim(),
      if (job.daysPerWeek.trim().isNotEmpty) job.daysPerWeek.trim(),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate800.withValues(alpha: 0.45)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark
              ? AppColors.slate700.withValues(alpha: 0.5)
              : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeeBadge(label: job.feeLabel),
          const SizedBox(height: 9),
          _MetaRow(
            icon: Icons.location_on_outlined,
            text: job.locality.isEmpty ? 'Location not specified' : job.locality,
            tone: Tone.info,
            color: muted,
          ),
          if (schedule.isNotEmpty) ...[
            const SizedBox(height: 7),
            _MetaRow(
              icon: Icons.schedule_rounded,
              text: schedule,
              tone: Tone.warning,
              color: muted,
            ),
          ],
        ],
      ),
    );
  }
}

/// The fee, in green, as a badge rather than a line of text.
///
/// Rendered even when the lead carries no budget: an omitted slot makes the
/// card above it look like the better-paying one, which is a lie told by layout.
class _FeeBadge extends StatelessWidget {
  const _FeeBadge({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final known = label != null;
    final tone = known ? Tone.success : Tone.neutral;
    final fg = tone.foreground(brightness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tone.background(brightness),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: tone.border(brightness)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            known ? Icons.payments_rounded : Icons.payments_outlined,
            size: 15,
            color: fg,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label ?? 'Budget not shared',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: known ? FontWeight.w800 : FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One fact. The icon takes the tint; the sentence stays slate.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    required this.tone,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Tone tone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: tone.foreground(Theme.of(context).brightness),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Class ────────────────────────────────────────────────────────────────────

/// The class this job is for, as a block on the leading edge.
class _ClassBlock extends StatelessWidget {
  const _ClassBlock({required this.job, required this.tone});

  final Job job;

  /// Comes from the card's [_LeadState] rather than being recomputed here, so
  /// the block, the rail and the border can never disagree.
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

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
        border: Border.all(color: tone.border(brightness)),
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
