import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/attendance_record.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/parent/providers/parent_providers.dart';

/// Both records of whether the teacher turned up.
///
/// Two independent books on the same sessions: what the teacher logged, and
/// what the parent marked. They are shown separately and labelled, because
/// merging them would invent an agreement that may not exist — and a
/// disagreement between the two is exactly what a parent is looking for.
class AttendanceCard extends ConsumerStatefulWidget {
  const AttendanceCard({
    super.key,
    required this.jobId,
    required this.tutorProfileId,
    required this.tutorName,
  });

  final int jobId;
  final int tutorProfileId;
  final String tutorName;

  @override
  ConsumerState<AttendanceCard> createState() => _AttendanceCardState();
}

/// What the teacher logged, which is the half a parent actually wants.
///
/// Separate from the parent's own marks below it: the two are independent
/// records of the same sessions and merging them would invent an agreement
/// that may not exist.
class _TutorLog extends ConsumerWidget {
  const _TutorLog({required this.jobId, required this.tutorName});

  final int jobId;
  final String tutorName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(tutorMarkedAttendanceProvider(jobId));
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return AsyncView<List<AttendanceRecord>>(
      value: log,
      compactError: true,
      onRetry: () => ref.invalidate(tutorMarkedAttendanceProvider(jobId)),
      loading: const SizedBox.shrink(),
      data: (records) {
        final taught = records.where((r) => r.counted).length;
        final missed = records.where((r) => r.isAbsent).length;
        // The most recent session the teacher actually wrote up.
        final withNotes = records.where((r) => r.hasLesson);
        final lastWithNotes = withNotes.isEmpty ? null : withNotes.first;

        return THTCard(
          borderColor: Tone.info.border(brightness),
          background: Tone.info.background(brightness),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 16,
                    color: Tone.info.foreground(brightness),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Marked by $tutorName',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Tone.info.foreground(brightness),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (records.isEmpty)
                Text(
                  'Nothing logged yet. Your teacher marks each session after '
                  'they teach it.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color:
                        Tone.info.foreground(brightness).withValues(alpha: 0.9),
                  ),
                )
              else ...[
                Text(
                  '$taught taught'
                  '${missed > 0 ? ', $missed missed' : ''}'
                  '${records.first.date != null ? ' · last on ${Fmt.date(records.first.date)}' : ''}',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Tone.info
                        .foreground(brightness)
                        .withValues(alpha: 0.95),
                  ),
                ),
                if (lastWithNotes != null &&
                    lastWithNotes.topicTaught.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last taught: ${lastWithNotes.topicTaught.trim()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, height: 1.4, color: muted),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceCardState extends ConsumerState<AttendanceCard> {
  bool _marking = false;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(jobAttendanceProvider(widget.jobId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Attendance',
          icon: Icons.event_available_outlined,
          iconTone: Tone.info,
          subtitle: 'What your teacher logged, and your own record',
        ),
        const SizedBox(height: AppSpacing.md),
        _TutorLog(jobId: widget.jobId, tutorName: widget.tutorName),
        const SizedBox(height: AppSpacing.md),
        AsyncView<List<AttendanceRecord>>(
          value: records,
          compactError: true,
          onRetry: () => ref.invalidate(jobAttendanceProvider(widget.jobId)),
          loading: const THTCard(
            child: SizedBox(
              height: 76,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          data: _body,
        ),
      ],
    );
  }

  Widget _body(List<AttendanceRecord> records) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    final today = DateTime.now();
    final markedToday = records.any((r) => isSameDay(r.date, today));
    final taught = records.where((r) => r.counted).length;
    final missed = records.where((r) => r.isAbsent).length;

    return THTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (records.isEmpty)
            Text(
              'Nothing marked yet. Keeping your own record helps if the '
              'month is ever queried.',
              style: TextStyle(fontSize: 13, height: 1.5, color: muted),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Pill(
                  '$taught taken',
                  tone: Tone.success,
                  icon: Icons.check_rounded,
                  dense: true,
                ),
                if (missed > 0)
                  Pill(
                    '$missed missed',
                    tone: Tone.critical,
                    icon: Icons.close_rounded,
                    dense: true,
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.base),
          if (markedToday)
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: Tone.success.foreground(Theme.of(context).brightness),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Today is marked. The server keeps one entry per day, so '
                    'it cannot be changed here.',
                    style: TextStyle(fontSize: 12.5, height: 1.4, color: muted),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                // One word each: "Came today" / "Did not come" wrapped to two
                // lines at half a 390dp row.
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _marking ? null : () => _mark('PRESENT'),
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Attended'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _marking ? null : () => _mark('ABSENT'),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Missed'),
                  ),
                ),
              ],
            ),
          if (records.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.base),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            // The last handful only — the full log is a month of rows and this
            // card sits above the applicant list.
            for (final r in records.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Fmt.date(r.date),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Pill(
                      r.statusLabel,
                      tone: r.isAbsent ? Tone.critical : Tone.success,
                      dense: true,
                    ),
                  ],
                ),
              ),
            if (records.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'and ${records.length - 5} more',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static bool isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _mark(String status) async {
    setState(() => _marking = true);
    try {
      await ref.read(jobsRepositoryProvider).markTutorAttendance(
            tutorProfileId: widget.tutorProfileId,
            jobId: widget.jobId,
            date: DateTime.now(),
            status: status,
          );
      if (!mounted) return;
      ref.invalidate(jobAttendanceProvider(widget.jobId));
      context.showMessage(
        status == 'PRESENT'
            ? 'Marked as taken today.'
            : 'Marked as missed today.',
      );
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }
}
