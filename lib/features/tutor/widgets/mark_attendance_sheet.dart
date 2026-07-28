import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/tuition.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/tone.dart';

/// Records one session against a tuition.
///
/// The teacher is standing in a doorway with one hand free, so the whole thing
/// is one tap plus optional detail: pick what happened, and only then are the
/// teaching notes worth filling in.
class MarkAttendanceSheet extends ConsumerStatefulWidget {
  const MarkAttendanceSheet({super.key, required this.tuition});

  final ActiveTuition tuition;

  /// Returns true when a session was recorded.
  static Future<bool?> show(BuildContext context, ActiveTuition tuition) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => MarkAttendanceSheet(tuition: tuition),
      );

  @override
  ConsumerState<MarkAttendanceSheet> createState() =>
      _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends ConsumerState<MarkAttendanceSheet> {
  late String _status = widget.tuition.todayStatus ?? 'PRESENT';
  late final _topic = TextEditingController(text: widget.tuition.todayTopic);
  late final _homework =
      TextEditingController(text: widget.tuition.todayHomework);
  final _remarks = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _topic.dispose();
    _homework.dispose();
    _remarks.dispose();
    super.dispose();
  }

  bool get _taught => _status == 'PRESENT';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final students = widget.tuition.allStudents;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tuition.markedToday
                            ? "Update today's session"
                            : "Mark today's session",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.slate50 : AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        students.isEmpty
                            ? widget.tuition.summaryLine
                            : '${students.join(', ')} · ${widget.tuition.summaryLine}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color:
                              isDark ? AppColors.slate400 : AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'WHAT HAPPENED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: isDark ? AppColors.slate400 : AppColors.slate500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StatusPicker(
              value: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_taught) ...[
              TextField(
                controller: _topic,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What did you teach?',
                  hintText: 'Quadratic equations — word problems',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _homework,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Homework given (optional)',
                  hintText: 'Exercise 4.3, questions 1–8',
                ),
              ),
            ] else
              TextField(
                controller: _remarks,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Why? (optional)',
                  hintText: _status == 'ABSENT'
                      ? 'Student was unwell'
                      : 'Moved to Saturday at the family’s request',
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.tuition.markedToday ? 'Update' : 'Save'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(jobsRepositoryProvider).markAttendance(
            jobId: widget.tuition.jobId,
            status: _status,
            topicTaught: _taught ? _topic.text.trim() : null,
            homeworkGiven: _taught ? _homework.text.trim() : null,
            remarks: _taught ? null : _remarks.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      context.showFailure(e);
    }
  }
}

/// The three states the backend accepts, as one-tap options.
class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('PRESENT', 'Taught', Icons.check_circle_outline_rounded, Tone.success),
    ('ABSENT', 'Missed', Icons.cancel_outlined, Tone.critical),
    ('RESCHEDULED', 'Moved', Icons.event_repeat_outlined, Tone.warning),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Row(
      children: [
        for (final (code, label, icon, tone) in _options) ...[
          if (code != _options.first.$1) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _Option(
              label: label,
              icon: icon,
              selected: value == code,
              tone: tone,
              brightness: brightness,
              onTap: () => onChanged(code),
            ),
          ),
        ],
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.icon,
    required this.selected,
    required this.tone,
    required this.brightness,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Tone tone;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    final fg = selected
        ? tone.foreground(brightness)
        : (isDark ? AppColors.slate400 : AppColors.slate500);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          decoration: BoxDecoration(
            color: selected
                ? tone.background(brightness)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? tone.border(brightness)
                  : (isDark ? AppColors.darkBorder : AppColors.slate200),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
