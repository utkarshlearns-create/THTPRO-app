import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/star_rating.dart';

/// The parent's public review of a teacher they have worked with.
///
/// Distinct from [DemoReviewSheet]: that one is a private three-part
/// assessment our counsellor reads before a hire, this is the single rating
/// that shows on the teacher's profile afterwards.
///
/// Returns `(rating, review)`, or null if the parent backed out.
class RateTutorSheet extends StatefulWidget {
  const RateTutorSheet({super.key, required this.tutorName});

  final String tutorName;

  static Future<({int rating, String review})?> show(
    BuildContext context, {
    required String tutorName,
  }) =>
      showModalBottomSheet<({int rating, String review})>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => RateTutorSheet(tutorName: tutorName),
      );

  @override
  State<RateTutorSheet> createState() => _RateTutorSheetState();
}

class _RateTutorSheetState extends State<RateTutorSheet> {
  final _review = TextEditingController();
  int _rating = 0;
  bool _showMissing = false;

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      setState(() => _showMissing = true);
      return;
    }
    Navigator.of(context).pop((rating: _rating, review: _review.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rate ${widget.tutorName}',
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
              const SizedBox(height: 2),
              Text(
                'Your rating appears on their profile and helps other parents '
                'choose.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: StarRating(
                  value: _rating,
                  size: 38,
                  onChanged: (v) => setState(() => _rating = v),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _review,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Your review (optional)',
                  hintText: 'How did the tuition go?',
                  alignLabelWithHint: true,
                ),
              ),
              if (_showMissing && _rating == 0) ...[
                const SizedBox(height: AppSpacing.md),
                const NoteBox(message: 'Pick a star rating first.'),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Submit rating'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
