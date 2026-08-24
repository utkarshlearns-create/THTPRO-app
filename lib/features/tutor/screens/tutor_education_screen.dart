import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/constants/education.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// The teacher's education record: 12th, graduation, post-graduation, and the
/// teaching certifications they hold.
///
/// Its own screen rather than a sheet — around thirty fields with per-level
/// marks validation is a page, not a popover. It used to be a link to the
/// website.
///
/// **Levels lock.** Once a teacher is approved and a level's certificate has
/// been verified, the server silently discards edits to that level. Showing an
/// open form there would take input and throw it away, so verified levels are
/// rendered read-only with the reason.
class TutorEducationScreen extends ConsumerWidget {
  const TutorEducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(tutorProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Education')),
      body: AsyncView<TutorProfile>(
        value: profile,
        onRetry: () => ref.invalidate(tutorProfileProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 140),
        ),
        data: (p) => _EducationForm(profile: p),
      ),
    );
  }
}

/// One level of the record and whether it can still be changed.
class _Level {
  const _Level({
    required this.title,
    required this.prefix,
    required this.locked,
  });

  final String title;

  /// The field-name prefix this level's inputs write to.
  final String prefix;

  final bool locked;
}

class _EducationForm extends ConsumerStatefulWidget {
  const _EducationForm({required this.profile});

  final TutorProfile profile;

  @override
  ConsumerState<_EducationForm> createState() => _EducationFormState();
}

class _EducationFormState extends ConsumerState<_EducationForm> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _choices = <String, String?>{};
  final _flags = <String, bool>{};

  bool _saving = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    for (final field in _textFields) {
      _controllers[field] = TextEditingController(text: _raw(field));
    }
    for (final field in _choiceFields) {
      final v = _raw(field);
      _choices[field] = v.isEmpty ? null : v;
    }
    for (final field in Education.certifications.keys) {
      _flags[field] = widget.profile.raw[field] == true;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  static const _textFields = [
    'intermediate_school', 'intermediate_board', 'intermediate_stream',
    'intermediate_year', 'inter_max_marks', 'inter_obtained_marks',
    'inter_grade_value',
    'grad_degree_other', 'grad_stream', 'grad_college', 'grad_university',
    'grad_year', 'grad_max_marks', 'grad_obtained_marks', 'grad_grade_value',
    'post_grad_degree_other', 'post_grad_stream', 'post_grad_college',
    'post_grad_university', 'post_grad_year', 'post_grad_max_marks',
    'post_grad_obtained_marks', 'post_grad_grade_value',
    'other_certifications',
  ];

  static const _choiceFields = [
    'inter_grade_type',
    'grad_status', 'grad_degree', 'grad_grade_type',
    'post_grad_status', 'post_grad_degree', 'post_grad_grade_type',
  ];

  String _raw(String key) {
    final v = widget.profile.raw[key];
    return v == null ? '' : v.toString();
  }

  /// The most recent KYC record, which carries the per-level verified flags.
  Map<String, dynamic> get _kyc {
    final raw = widget.profile.raw['kyc'];
    if (raw is List && raw.isNotEmpty) {
      final last = raw.last;
      if (last is Map) return last.cast<String, dynamic>();
    }
    if (raw is Map) return raw.cast<String, dynamic>();
    return const {};
  }

  /// Only an approved teacher's verified levels freeze; an unapproved one can
  /// still correct anything.
  bool get _approved {
    final status = widget.profile.raw['status_msg'];
    if (status is! Map) return false;
    final value = status['status']?.toString().toUpperCase();
    return value == 'APPROVED' || value == 'ACTIVE';
  }

  bool _lockedLevel(String verifiedFlag) =>
      _approved && _kyc[verifiedFlag] == true;

  @override
  Widget build(BuildContext context) {
    final levels = [
      _Level(
        title: '12th / Intermediate',
        prefix: 'inter',
        locked: _lockedLevel('intermediate_certificate_verified'),
      ),
      _Level(
        title: 'Graduation',
        prefix: 'grad',
        locked: _lockedLevel('graduation_certificate_verified'),
      ),
      _Level(
        title: 'Post-graduation',
        prefix: 'post_grad',
        locked: _lockedLevel('post_grad_certificate_verified'),
      ),
    ];

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.base,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          const NoteBox(
            tone: Tone.info,
            message: 'Your qualifications feed your score, so filling these in '
                'properly is worth the few minutes.',
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final level in levels) ...[
            _levelSection(level),
            const SizedBox(height: AppSpacing.xl),
          ],
          _certifications(),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            NoteBox(message: _error!),
          ],
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
                  : const Text('Save education'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelSection(_Level level) {
    final isInter = level.prefix == 'inter';
    final isPostGrad = level.prefix == 'post_grad';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          level.title,
          icon: Icons.school_outlined,
          iconTone: level.locked ? Tone.success : Tone.neutral,
        ),
        const SizedBox(height: AppSpacing.md),
        if (level.locked) ...[
          const NoteBox(
            tone: Tone.success,
            title: 'Verified — locked',
            message: 'Our team has checked this against your certificate. '
                'Contact your admin if something needs correcting.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        THTCard(
          child: Column(
            children: [
              if (isInter) ...[
                _text('intermediate_school', 'School', enabled: !level.locked),
                _text('intermediate_board', 'Board', enabled: !level.locked),
                _text('intermediate_stream', 'Stream',
                    hint: 'Science, Commerce, Arts', enabled: !level.locked),
                _year('intermediate_year', enabled: !level.locked),
              ] else ...[
                _dropdown(
                  '${level.prefix}_status',
                  'Status',
                  isPostGrad
                      ? Education.postGradStatuses
                      : Education.gradStatuses,
                  enabled: !level.locked,
                ),
                _dropdown(
                  '${level.prefix}_degree',
                  'Degree',
                  isPostGrad
                      ? Education.postGradDegrees
                      : Education.gradDegrees,
                  enabled: !level.locked,
                ),
                // Only when "Other" was chosen — an always-visible free-text
                // box next to a picked degree invites two different answers.
                if (_choices['${level.prefix}_degree'] == 'OTHER')
                  _text('${level.prefix}_degree_other', 'Which degree?',
                      enabled: !level.locked),
                _text('${level.prefix}_stream', 'Stream / subject',
                    enabled: !level.locked),
                _text('${level.prefix}_college', 'College',
                    enabled: !level.locked),
                _text('${level.prefix}_university', 'University',
                    enabled: !level.locked),
                _year('${level.prefix}_year', enabled: !level.locked),
              ],
              _grades(level),
            ],
          ),
        ),
      ],
    );
  }

  /// The marks block, which changes shape with the grade type — and so does
  /// what the server will accept.
  Widget _grades(_Level level) {
    final typeField = '${level.prefix}_grade_type';
    final type = _choices[typeField] ?? 'PERCENTAGE';

    return Column(
      children: [
        _dropdown(typeField, 'Marks recorded as', Education.gradeTypes,
            enabled: !level.locked),
        if (type == 'PERCENTAGE') ...[
          Row(
            children: [
              Expanded(
                child: _number('${level.prefix}_obtained_marks', 'Marks scored',
                    enabled: !level.locked),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _number('${level.prefix}_max_marks', 'Out of',
                    enabled: !level.locked),
              ),
            ],
          ),
        ] else if (type == 'GRADE')
          _text('${level.prefix}_grade_value', 'Grade',
              hint: 'A+, B, First class', enabled: !level.locked)
        else
          _text(
            '${level.prefix}_grade_value',
            'CGPA',
            hint: 'Out of ${Education.cgpaLimit(type)?.toStringAsFixed(0)}',
            enabled: !level.locked,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return null;
              final value = double.tryParse(s);
              if (value == null) return 'Enter a number';
              final limit = Education.cgpaLimit(type)!;
              // The server rejects anything outside this, so catching it here
              // saves a round trip that comes back as a field error.
              if (value < 0 || value > limit) {
                return 'Between 0 and ${limit.toStringAsFixed(0)}';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _certifications() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Certifications',
            icon: Icons.workspace_premium_outlined,
            iconTone: Tone.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          THTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final entry in Education.certifications.entries)
                      FilterChip(
                        label: Text(entry.value),
                        selected: _flags[entry.key] ?? false,
                        onSelected: (v) =>
                            setState(() => _flags[entry.key] = v),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                _text('other_certifications', 'Anything else',
                    hint: 'Other courses or certificates', lines: 2),
              ],
            ),
          ),
        ],
      );

  // ── Inputs ─────────────────────────────────────────────────────────────────

  Widget _text(
    String field,
    String label, {
    String? hint,
    bool enabled = true,
    int lines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.base),
        child: TextFormField(
          controller: _controllers[field],
          enabled: enabled,
          maxLines: lines,
          keyboardType: keyboard,
          textCapitalization: TextCapitalization.words,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            errorText: _fieldErrors[field],
          ),
        ),
      );

  Widget _number(String field, String label, {bool enabled = true}) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.base),
        child: TextFormField(
          controller: _controllers[field],
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: label,
            errorText: _fieldErrors[field],
          ),
        ),
      );

  Widget _year(String field, {bool enabled = true}) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.base),
        child: TextFormField(
          controller: _controllers[field],
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            labelText: 'Year',
            errorText: _fieldErrors[field],
          ),
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return null;
            final year = int.tryParse(s);
            if (year == null || s.length != 4) return 'Enter a 4-digit year';
            // A year in the future is fine — someone pursuing a degree has one.
            if (year < 1950 || year > DateTime.now().year + 8) {
              return 'That year does not look right';
            }
            return null;
          },
        ),
      );

  Widget _dropdown(
    String field,
    String label,
    Map<String, String> options, {
    bool enabled = true,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.base),
        child: DropdownButtonFormField<String>(
          initialValue:
              options.containsKey(_choices[field]) ? _choices[field] : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            errorText: _fieldErrors[field],
          ),
          items: [
            for (final entry in options.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged:
              enabled ? (v) => setState(() => _choices[field] = v) : null,
        ),
      );

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Only what changed, and nothing from a locked level.
  ///
  /// Sending a locked field would not fail — the server drops it quietly — but
  /// it would make the diff lie about what was saved.
  Map<String, dynamic> _changes() {
    final out = <String, dynamic>{};

    for (final entry in _controllers.entries) {
      final next = entry.value.text.trim();
      if (next == _raw(entry.key)) continue;

      // The numeric columns are nullable ints; an emptied box means null, not
      // an empty string, which the server would refuse.
      if (_isNumeric(entry.key)) {
        out[entry.key] = next.isEmpty ? null : int.tryParse(next);
      } else {
        out[entry.key] = next;
      }
    }

    for (final entry in _choices.entries) {
      if ((entry.value ?? '') != _raw(entry.key)) {
        out[entry.key] = entry.value ?? '';
      }
    }

    for (final entry in _flags.entries) {
      if (entry.value != (widget.profile.raw[entry.key] == true)) {
        out[entry.key] = entry.value;
      }
    }

    return out;
  }

  bool _isNumeric(String field) =>
      field.endsWith('_year') ||
      field.endsWith('_max_marks') ||
      field.endsWith('_obtained_marks');

  Future<void> _save() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!(_form.currentState?.validate() ?? false)) return;

    final changes = _changes();
    if (changes.isEmpty) {
      context.showMessage('Nothing to save.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(usersRepositoryProvider).updateTutorProfile(changes);
      if (!mounted) return;
      ref.invalidate(tutorProfileProvider);
      context.showMessage('Education saved.');
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      setState(() {
        _saving = false;
        _fieldErrors = failure.fieldErrors;
        // The marks and CGPA rules come back per field; a banner as well would
        // say the same thing twice.
        _error = failure.fieldErrors.isEmpty ? failure.message : null;
      });
      return;
    }
    if (mounted) setState(() => _saving = false);
  }
}
