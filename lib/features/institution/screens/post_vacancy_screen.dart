import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/faculty_vacancy.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/institution/providers/institution_providers.dart';

/// Post a teaching post the institute is hiring for.
///
/// A **faculty vacancy**, not a tuition requirement — those are created by the
/// THT team with the institute as the client, and an institute cannot self-post
/// one. This is the only job an institute makes for itself.
class PostVacancyScreen extends ConsumerStatefulWidget {
  const PostVacancyScreen({super.key});

  @override
  ConsumerState<PostVacancyScreen> createState() => _PostVacancyScreenState();
}

class _PostVacancyScreenState extends ConsumerState<PostVacancyScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subject = TextEditingController();
  final _classLevel = TextEditingController();
  final _salary = TextEditingController();
  final _requirements = TextEditingController();

  String _jobType = 'FULL_TIME';
  DateTime? _startDate;

  /// Off by default — an institute opts in to being contacted directly rather
  /// than having its number handed out.
  bool _allowContact = false;
  int _maxUnlocks = 5;

  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    for (final c in [
      _title,
      _subject,
      _classLevel,
      _salary,
      _requirements,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Scaffold(
      appBar: AppBar(title: const Text('Post a vacancy')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            Text(
              'Hiring teaching staff for your institute. Teachers see this on '
              'the jobs board and apply to you directly.',
              style: TextStyle(fontSize: 13, height: 1.5, color: muted),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Job title',
                hintText: 'Senior Physics Faculty for Class 11–12',
                errorText: _fieldErrors['title'],
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Give the role a title' : null,
            ),
            const SizedBox(height: AppSpacing.base),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subject,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      hintText: 'Physics',
                      errorText: _fieldErrors['subject'],
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _classLevel,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Class level',
                      hintText: 'Class 11-12',
                      errorText: _fieldErrors['class_level'],
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),

            TextFormField(
              controller: _salary,
              decoration: InputDecoration(
                labelText: 'Salary range',
                hintText: '50k – 70k per month',
                helperText: 'Optional, but posts with a range get more applicants',
                errorText: _fieldErrors['salary_range'],
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            DropdownButtonFormField<String>(
              initialValue: _jobType,
              decoration: const InputDecoration(labelText: 'Job type'),
              items: [
                for (final entry in FacultyVacancy.jobTypes.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (v) => setState(() => _jobType = v ?? 'FULL_TIME'),
            ),
            const SizedBox(height: AppSpacing.base),

            _StartDateField(
              value: _startDate,
              onPick: (d) => setState(() => _startDate = d),
              onClear: () => setState(() => _startDate = null),
            ),
            const SizedBox(height: AppSpacing.base),

            TextFormField(
              controller: _requirements,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Role and requirements',
                hintText: 'What the role involves, the qualifications and '
                    'experience you need, and anything else worth saying.',
                alignLabelWithHint: true,
                errorText: _fieldErrors['requirements'],
              ),
              validator: (v) => (v ?? '').trim().length < 20
                  ? 'A little more detail gets better applicants'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            SwitchListTile.adaptive(
              value: _allowContact,
              onChanged: (v) => setState(() => _allowContact = v),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Let teachers contact you directly',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Verified teachers can unlock your number instead of going '
                'through our team.',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ),
            if (_allowContact) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'How many teachers may unlock it',
                      style: TextStyle(fontSize: 13.5, color: muted),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: TextFormField(
                      initialValue: '$_maxUnlocks',
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        helperText: '0 = no limit',
                      ),
                      onChanged: (v) =>
                          _maxUnlocks = int.tryParse(v.trim()) ?? 0,
                    ),
                  ),
                ],
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              NoteBox(message: _error!),
            ],

            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post vacancy'),
            ),
            const SizedBox(height: AppSpacing.md),
            const NoteBox(
              tone: Tone.info,
              message: 'Need a tutor for your students instead? Your THT '
                  'relationship manager posts those for you — just ask them.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = const {});
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(jobsRepositoryProvider).createFacultyVacancy({
        'title': _title.text.trim(),
        'subject': _subject.text.trim(),
        'class_level': _classLevel.text.trim(),
        'requirements': _requirements.text.trim(),
        'salary_range': _salary.text.trim(),
        'job_type': _jobType,
        if (_startDate != null)
          'start_date': _startDate!.toIso8601String().split('T').first,
        'allow_contact': _allowContact,
        if (_allowContact) 'max_contact_unlocks': _maxUnlocks,
      });
      if (!mounted) return;
      ref.invalidate(facultyVacanciesProvider);
      context.go('/inst-jobs');
      context.showMessage('Vacancy posted. Teachers can now apply.');
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      setState(() {
        _saving = false;
        _fieldErrors = failure.fieldErrors;
        _error = failure.fieldErrors.isEmpty ? failure.message : null;
      });
    }
  }
}

/// A date picker that reads as a field and can be cleared.
class _StartDateField extends StatelessWidget {
  const _StartDateField({
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: DateTime(now.year + 2),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Start date',
          helperText: 'Optional',
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_outlined, size: 19)
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 19),
                  tooltip: 'Clear',
                ),
        ),
        child: Text(
          value == null ? 'Not set' : Fmt.date(value),
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}
