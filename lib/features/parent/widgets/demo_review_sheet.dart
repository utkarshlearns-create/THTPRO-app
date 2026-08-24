import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/star_rating.dart';
import 'package:tht_app/core/ui/tone.dart';

/// The review a parent must give before we will accept their approval of a
/// teacher.
///
/// `POST /api/jobs/parent/application-action/<id>/confirm/` rejects the request
/// outright unless `teaching_skill`, `subject_knowledge` and `confidence` are
/// all present and between 1 and 5 — so this is not an optional nicety bolted
/// onto the button, it *is* the request body.
///
/// Returns the payload to send, or null if the parent backed out.
class DemoReviewSheet extends StatefulWidget {
  const DemoReviewSheet({super.key, required this.tutorName});

  final String tutorName;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String tutorName,
  }) =>
      showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => DemoReviewSheet(tutorName: tutorName),
      );

  @override
  State<DemoReviewSheet> createState() => _DemoReviewSheetState();
}

class _DemoReviewSheetState extends State<DemoReviewSheet> {
  final _comment = TextEditingController();

  int _teaching = 0;
  int _knowledge = 0;
  int _confidence = 0;

  /// Set only after a failed attempt, so the sheet does not open scolding.
  bool _showMissing = false;

  bool get _complete => _teaching > 0 && _knowledge > 0 && _confidence > 0;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_complete) {
      setState(() => _showMissing = true);
      return;
    }
    Navigator.of(context).pop({
      'teaching_skill': _teaching,
      'subject_knowledge': _knowledge,
      'confidence': _confidence,
      'comment': _comment.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'How was the demo?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Your answers go to the counsellor handling this '
                    'requirement, alongside their own assessment of '
                    '${widget.tutorName}.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Question(
                    label: 'Teaching',
                    hint: 'Did they explain in a way your child followed?',
                    value: _teaching,
                    onChanged: (v) => setState(() => _teaching = v),
                  ),
                  _Question(
                    label: 'Subject knowledge',
                    hint: 'Were they on top of the syllabus?',
                    value: _knowledge,
                    onChanged: (v) => setState(() => _knowledge = v),
                  ),
                  _Question(
                    label: 'Confidence',
                    hint: 'Would you be comfortable leaving them to it?',
                    value: _confidence,
                    onChanged: (v) => setState(() => _confidence = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _comment,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Anything else? (optional)',
                      hintText: 'What went well, or what you would change',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (_showMissing && !_complete) ...[
                    const SizedBox(height: AppSpacing.md),
                    const NoteBox(
                      message: 'Please rate all three before approving — we '
                          'cannot pass on a partial review.',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  const NoteBox(
                    tone: Tone.info,
                    message: 'Approving does not start the tuition on its own. '
                        'Our counsellor confirms the fee and schedule with you '
                        'before anything is fixed.',
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Approve this teacher'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.slate100 : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StarRating(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
