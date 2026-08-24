import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/tuition.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';
import 'package:tht_app/features/tutor/widgets/mark_attendance_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Every tuition the teacher is currently running, and today's attendance.
///
/// This is the screen a teacher opens between sessions, so marking a session is
/// the primary action on every card — never behind a menu.
class TutorScheduleScreen extends ConsumerWidget {
  const TutorScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(todayScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My tuitions'),
        actions: [
          IconButton(
            onPressed: () => context.push('/tutor-tuitions'),
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: 'All tuitions',
          ),
          IconButton(
            onPressed: () => context.push('/tutor-attendance'),
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Attendance history',
          ),
        ],
      ),
      body: AsyncView<TodaySchedule>(
        value: schedule,
        onRetry: () => ref.invalidate(todayScheduleProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 150),
        ),
        data: (s) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayScheduleProvider);
            await ref.read(todayScheduleProvider.future);
          },
          child: s.tuitions.isEmpty
              ? ListView(
                  children: const [
                    EmptyState(
                      icon: Icons.event_available_outlined,
                      title: 'No tuitions running',
                      message: 'Once a family hires you, the tuition appears '
                          'here and you can mark each session in one tap.',
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
                  children: [
                    _TodayHeader(schedule: s),
                    const SizedBox(height: AppSpacing.lg),
                    for (var i = 0; i < s.tuitions.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      _TuitionCard(tuition: s.tuitions[i]),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.schedule});

  final TodaySchedule schedule;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unmarked = schedule.unmarked.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Fmt.longDate(schedule.date ?? DateTime.now()),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: isDark ? AppColors.slate50 : AppColors.slate900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unmarked == 0
              ? 'All ${Fmt.plural(schedule.totalActive, 'tuition')} marked for today'
              : '$unmarked of ${schedule.totalActive} still to mark',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: unmarked == 0
                ? Tone.success.foreground(Theme.of(context).brightness)
                : Tone.warning.foreground(Theme.of(context).brightness),
          ),
        ),
      ],
    );
  }
}

class _TuitionCard extends ConsumerWidget {
  const _TuitionCard({required this.tuition});

  final ActiveTuition tuition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final students = tuition.allStudents;
    final rate = tuition.attendanceRate;

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
                      students.isEmpty ? 'Student' : students.join(', '),
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
                      tuition.summaryLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (tuition.markedToday)
                Pill.status(tuition.todayStatus, dense: true)
              else
                const Pill('To mark', tone: Tone.warning, dense: true),
            ],
          ),

          if (tuition.locality.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tuition.locality,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: muted),
                  ),
                ),
                if (rate != null)
                  Text(
                    '${(rate * 100).round()}% attendance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark ? AppColors.slate300 : AppColors.slate600,
                    ),
                  ),
              ],
            ),
          ],

          if (tuition.markedToday && tuition.todayTopic.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : AppColors.slate50,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taught today',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tuition.todayTopic.trim(),
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
                  if (tuition.todayHomework.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Homework: ${tuition.todayHomework.trim()}',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              Expanded(
                child: tuition.markedToday
                    ? OutlinedButton.icon(
                        onPressed: () => _mark(context, ref),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit session'),
                      )
                    : FilledButton.icon(
                        onPressed: () => _mark(context, ref),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Mark session'),
                      ),
              ),
              if (tuition.parentPhone.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: () => launchUrl(
                    Uri.parse('tel:${tuition.parentPhone}'),
                    mode: LaunchMode.externalApplication,
                  ),
                  tooltip: 'Call ${tuition.parentName}',
                  icon: const Icon(Icons.call_outlined),
                  style: IconButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.slate200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ],
          ),

          if (tuition.recentLogs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _RecentLogs(logs: tuition.recentLogs),
          ],
        ],
      ),
    );
  }

  Future<void> _mark(BuildContext context, WidgetRef ref) async {
    final saved = await MarkAttendanceSheet.show(context, tuition);
    if (saved != true) return;
    // The dashboard counts unmarked sessions too, so refresh both.
    ref.invalidate(todayScheduleProvider);
    if (context.mounted) context.showMessage('Session recorded.');
  }
}

/// The last few sessions, collapsed by default — useful but not the point.
class _RecentLogs extends StatelessWidget {
  const _RecentLogs({required this.logs});

  final List<AttendanceLog> logs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        title: Text(
          'Recent sessions (${logs.length})',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
        children: [
          for (final log in logs)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 62,
                    child: Text(
                      Fmt.date(log.date).replaceAll(RegExp(r' \d{4}$'), ''),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: muted,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Pill.status(log.status, dense: true),
                  ),
                  Expanded(
                    child: Text(
                      log.topicTaught.trim().isEmpty
                          ? (log.remarks.trim().isEmpty
                              ? '—'
                              : log.remarks.trim())
                          : log.topicTaught.trim(),
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: muted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
