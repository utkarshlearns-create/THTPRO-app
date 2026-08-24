import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tht_app/core/models/attendance_record.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/tutor/providers/attendance_providers.dart';

/// Every session this teacher has logged.
///
/// Marking attendance already worked from the tuitions screen; nothing read it
/// back. A teacher's record is what a fee dispute turns on, so this shows the
/// whole log — grouped by month, with what was taught kept on the row rather
/// than hidden behind a tap.
class TutorAttendanceScreen extends ConsumerWidget {
  const TutorAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(attendanceHistoryProvider);
    // Labels are a nicety — a record still reads fine as a date and a status,
    // so this never blocks the list or surfaces its own error.
    final labels = ref.watch(tuitionLabelsProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance history')),
      body: AsyncView<List<AttendanceRecord>>(
        value: history,
        onRetry: () => ref.invalidate(attendanceHistoryProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 4, itemHeight: 96),
        ),
        data: (records) => RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(attendanceHistoryProvider)
              ..invalidate(tuitionLabelsProvider);
            await ref.read(attendanceHistoryProvider.future);
          },
          child: records.isEmpty
              ? ListView(
                  children: const [
                    EmptyState(
                      icon: Icons.event_note_outlined,
                      title: 'Nothing logged yet',
                      message: 'Mark a session from My tuitions and it will '
                          'appear here. Your record is what we check if a '
                          'family ever queries the month.',
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
                  children: _body(context, records, labels),
                ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    List<AttendanceRecord> records,
    Map<int, String> labels,
  ) {
    final months = _byMonth(records);

    return [
      _Summary(records: records),
      const SizedBox(height: AppSpacing.xl),
      for (final entry in months.entries) ...[
        SectionHeader(entry.key, icon: Icons.calendar_month_outlined),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < entry.value.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _RecordCard(
            record: entry.value[i],
            label: labels[entry.value[i].jobId],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    ];
  }

  /// Groups into `LinkedHashMap`-ordered months, preserving the newest-first
  /// order the repository already sorted into.
  Map<String, List<AttendanceRecord>> _byMonth(List<AttendanceRecord> rows) {
    final out = <String, List<AttendanceRecord>>{};
    final format = DateFormat('MMMM yyyy');
    for (final r in rows) {
      final key = r.date == null ? 'Undated' : format.format(r.date!);
      (out[key] ??= []).add(r);
    }
    return out;
  }
}

/// The counts a teacher is asked for when a month is queried.
class _Summary extends StatelessWidget {
  const _Summary({required this.records});

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final taught = records.where((r) => r.counted).length;
    final absent = records.where((r) => r.isAbsent).length;
    final written = records.where((r) => r.hasLesson).length;

    return THTCard(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Stat(value: '$taught', label: 'Sessions taught', tone: Tone.success),
            _Divider(),
            _Stat(
              value: '$absent',
              label: 'Marked absent',
              tone: absent > 0 ? Tone.warning : Tone.neutral,
            ),
            _Divider(),
            _Stat(value: '$written', label: 'With lesson notes'),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
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

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.tone = Tone.neutral,
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
              fontSize: 24,
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, this.label});

  final AttendanceRecord record;

  /// The tuition this session belongs to, when we could name it.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final tone = _tone;

    return THTCard(
      borderColor: record.isAbsent ? tone.border(brightness) : null,
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
                      Fmt.date(record.date),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    if (label != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pill(record.statusLabel, tone: tone, dense: true),
            ],
          ),
          if (record.topicTaught.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _Line(
              icon: Icons.menu_book_outlined,
              label: 'Taught',
              value: record.topicTaught.trim(),
            ),
          ],
          if (record.homeworkGiven.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _Line(
              icon: Icons.edit_note_outlined,
              label: 'Homework',
              value: record.homeworkGiven.trim(),
            ),
          ],
          if (record.remarks.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _Line(
              icon: Icons.sticky_note_2_outlined,
              label: 'Note',
              value: record.remarks.trim(),
            ),
          ],
        ],
      ),
    );
  }

  Tone get _tone {
    switch (record.status.toUpperCase()) {
      case 'PRESENT':
        return Tone.success;
      case 'LATE':
        return Tone.warning;
      case 'ABSENT':
        return Tone.critical;
      default:
        return Tone.neutral;
    }
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 15, color: muted),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: isDark ? AppColors.slate200 : AppColors.slate700,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
              children: [
                TextSpan(
                  text: '$label  ',
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
