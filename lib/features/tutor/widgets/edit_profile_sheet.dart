import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/constants/search_constants.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_type.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';

/// Which group of fields the sheet is editing.
///
/// Split by what a teacher comes here to change, not by how the model is laid
/// out — one long form covering all of it would be worse than three short ones.
enum ProfileSection { about, teaching, location }

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.profile,
    required this.section,
  });

  final TutorProfile profile;
  final ProfileSection section;

  static Future<void> show(
    BuildContext context,
    TutorProfile profile,
    ProfileSection section,
  ) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => EditProfileSheet(profile: profile, section: section),
      );

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _form = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _about = TextEditingController(text: widget.profile.aboutMe);
  late final _whatsapp =
      TextEditingController(text: widget.profile.whatsappNumber);
  late final _alternate =
      TextEditingController(text: widget.profile.alternateNumber);
  late final _experience = TextEditingController(
    text: widget.profile.experienceYears == 0
        ? ''
        : '${widget.profile.experienceYears}',
  );
  late final _fee = TextEditingController(
    text: widget.profile.expectedFee == null || widget.profile.expectedFee == 0
        ? ''
        : widget.profile.expectedFee!.toStringAsFixed(0),
  );
  late final _locality = TextEditingController(text: widget.profile.locality);
  late final _pincode = TextEditingController(text: widget.profile.pincode);

  // The address detail lives only in `raw` — the app models the fields it
  // edits, and these were not edited until now.
  late final _houseNo = TextEditingController(text: _raw('house_no'));
  late final _area = TextEditingController(text: _raw('area'));
  late final _landmark = TextEditingController(text: _raw('landmark'));
  late final _localAddress = TextEditingController(text: _raw('local_address'));
  late final _permanentAddress =
      TextEditingController(text: _raw('permanent_address'));

  String _raw(String key) {
    final v = widget.profile.raw[key];
    return v == null ? '' : v.toString();
  }

  late String? _gender =
      widget.profile.gender.trim().isEmpty ? null : widget.profile.gender;
  late DateTime? _dob = widget.profile.dob;
  late String? _mode = widget.profile.teachingMode.trim().isEmpty
      ? null
      : widget.profile.teachingMode.toUpperCase();
  late String? _state =
      widget.profile.state.trim().isEmpty ? null : widget.profile.state;
  late String? _city =
      widget.profile.city.trim().isEmpty ? null : widget.profile.city;

  bool _saving = false;

  /// Per-field messages the API rejected the last submission with.
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    for (final c in [
      _name,
      _about,
      _whatsapp,
      _alternate,
      _experience,
      _fee,
      _locality,
      _pincode,
      _houseNo,
      _area,
      _landmark,
      _localAddress,
      _permanentAddress,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
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
                      _title,
                      style: TextStyle(
                        fontSize: ThtType.title,
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
              child: Form(
                key: _form,
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: _fields(),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
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
                        : const Text('Save changes'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _title {
    switch (widget.section) {
      case ProfileSection.about:
        return 'Your details';
      case ProfileSection.teaching:
        return 'Teaching';
      case ProfileSection.location:
        return 'Where you teach';
    }
  }

  /// Opens the writer, and puts its answer in the field as a DRAFT.
  ///
  /// Deliberately not saved: the teacher reads it, edits it, and taps Save like
  /// any other change. A profile line that appeared on the public listing
  /// without the teacher ever having agreed to the words would be our sentence
  /// in their voice.
  Future<void> _writeAboutMe() async {
    final written = await _AboutWriterSheet.show(
      context,
      profile: widget.profile,
      currentAbout: _about.text,
    );
    if (written == null || !mounted) return;
    setState(() {
      _about.text = written.length > 600 ? written.substring(0, 600) : written;
      _fieldErrors.remove('about_me');
    });
  }

  List<Widget> _fields() {
    switch (widget.section) {
      case ProfileSection.about:
        return [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full name',
              errorText: _fieldErrors['full_name'],
            ),
            validator: (v) => (v ?? '').trim().length < 2
                ? 'Please enter your full name'
                : null,
          ),
          const SizedBox(height: AppSpacing.base),
          _Choices(
            label: 'Gender',
            hint: 'Gender-specific jobs need this to be set',
            options: const {'Male': 'Male', 'Female': 'Female'},
            value: _gender,
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: AppSpacing.base),
          _DateField(
            label: 'Date of birth',
            value: _dob,
            onChanged: (v) => setState(() => _dob = v),
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: _about,
            maxLines: 5,
            maxLength: 600,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'About you',
              hintText: 'How you teach, what you are known for, results your '
                  'students have had.',
              alignLabelWithHint: true,
              errorText: _fieldErrors['about_me'],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _writeAboutMe,
              icon: const Icon(Icons.auto_awesome_outlined, size: 18),
              label: const Text('Help me write this'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _whatsapp,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: 'WhatsApp number',
              prefixText: '+91 ',
              errorText: _fieldErrors['whatsapp_number'],
            ),
            validator: _phoneValidator,
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: _alternate,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: 'Alternate number (optional)',
              prefixText: '+91 ',
              errorText: _fieldErrors['alternate_number'],
            ),
            validator: _phoneValidator,
          ),
        ];

      case ProfileSection.teaching:
        return [
          TextFormField(
            controller: _experience,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              labelText: 'Years of teaching experience',
              errorText: _fieldErrors['teaching_experience_years'],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: _fee,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: 'Expected fee per month',
              prefixText: '₹ ',
              helperText: 'Used to match you to leads in your range',
              errorText: _fieldErrors['expected_fee'],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          _Choices(
            label: 'Teaching mode',
            options: const {
              'HOME': 'At their home',
              'ONLINE': 'Online',
              'BOTH': 'Either',
            },
            value: _mode,
            onChanged: (v) => setState(() => _mode = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Subjects and classes have their own picker — close this and tap '
            'What you teach on your profile. Keeping them there is what gets '
            'you matched to the right leads.',
            style: TextStyle(
              fontSize: ThtType.body,
              height: 1.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.slate400
                  : AppColors.slate500,
            ),
          ),
        ];

      case ProfileSection.location:
        final cities = _state == null
            ? <String>[]
            : (SearchConstants.locationData[_state!] ?? const []);

        return [
          _Dropdown(
            label: 'State',
            value: _state,
            options: SearchConstants.locationData.keys.toList(),
            onChanged: (v) => setState(() {
              _state = v;
              _city = null; // the old city no longer belongs to this state
            }),
          ),
          const SizedBox(height: AppSpacing.base),
          _Dropdown(
            label: 'City',
            value: _city,
            options: cities,
            enabled: _state != null,
            disabledHint: 'Choose a state first',
            onChanged: (v) => setState(() => _city = v),
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: _locality,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Your locality',
              hintText: 'Gomti Nagar',
              errorText: _fieldErrors['locality'],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: _pincode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: 'Pincode',
              errorText: _fieldErrors['pincode'],
            ),
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return null;
              return s.length == 6 ? null : 'A pincode is 6 digits';
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your address',
            style: TextStyle(
              fontSize: ThtType.bodyStrong,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.slate100
                  : AppColors.slate800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Only our team sees this. Families never get your address — they '
            'get yours only after you agree to teach them.',
            style: TextStyle(
              fontSize: ThtType.body,
              height: 1.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.slate400
                  : AppColors.slate500,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: _houseNo,
            decoration: InputDecoration(
              labelText: 'House / flat number',
              errorText: _fieldErrors['house_no'],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: _area,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Area',
              hintText: 'Sector 4',
              errorText: _fieldErrors['area'],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: _landmark,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Landmark',
              hintText: 'Near the community centre',
              errorText: _fieldErrors['landmark'],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: _localAddress,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Where you live now',
              alignLabelWithHint: true,
              errorText: _fieldErrors['local_address'],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          TextFormField(
            controller: _permanentAddress,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Permanent address',
              hintText: 'If different from above',
              alignLabelWithHint: true,
              errorText: _fieldErrors['permanent_address'],
            ),
          ),
        ];
    }
  }

  String? _phoneValidator(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (s.length != 10) return 'A mobile number is 10 digits';
    if (!'6789'.contains(s[0])) return 'Must start with 6, 7, 8 or 9';
    return null;
  }

  /// Only what actually changed, so a partial edit never clears a field that
  /// this sheet doesn't show.
  Map<String, dynamic> _changes() {
    final p = widget.profile;
    final out = <String, dynamic>{};

    void put(String key, Object? next, Object? current) {
      if (next != current) out[key] = next;
    }

    switch (widget.section) {
      case ProfileSection.about:
        put('full_name', _name.text.trim(), p.fullName);
        put('gender', _gender ?? '', p.gender);
        put(
          'dob',
          _dob?.toIso8601String().split('T').first,
          p.dob?.toIso8601String().split('T').first,
        );
        put('about_me', _about.text.trim(), p.aboutMe);
        put('whatsapp_number', _whatsapp.text.trim(), p.whatsappNumber);
        put('alternate_number', _alternate.text.trim(), p.alternateNumber);

      case ProfileSection.teaching:
        put(
          'teaching_experience_years',
          int.tryParse(_experience.text.trim()) ?? 0,
          p.experienceYears,
        );
        put(
          'expected_fee',
          double.tryParse(_fee.text.trim()),
          p.expectedFee,
        );
        put('teaching_mode', _mode ?? '', p.teachingMode.toUpperCase());

      case ProfileSection.location:
        put('state', _state ?? '', p.state);
        put('city', _city ?? '', p.city);
        put('locality', _locality.text.trim(), p.locality);
        put('pincode', _pincode.text.trim(), p.pincode);
        put('house_no', _houseNo.text.trim(), _raw('house_no'));
        put('area', _area.text.trim(), _raw('area'));
        put('landmark', _landmark.text.trim(), _raw('landmark'));
        put('local_address', _localAddress.text.trim(), _raw('local_address'));
        put('permanent_address', _permanentAddress.text.trim(),
            _raw('permanent_address'));
    }

    return out;
  }

  Future<void> _save() async {
    setState(() => _fieldErrors = const {});
    if (!(_form.currentState?.validate() ?? false)) return;

    final changes = _changes();
    if (changes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(usersRepositoryProvider).updateTutorProfile(changes);
      if (!mounted) return;
      ref.invalidate(tutorProfileProvider);
      Navigator.of(context).pop();
      context.showMessage('Profile updated.');
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      setState(() {
        _saving = false;
        _fieldErrors = failure.fieldErrors;
      });
      // Only fall back to a banner when the error isn't already pinned to a
      // field the form is showing.
      if (failure.fieldErrors.isEmpty) context.showFailure(failure);
    }
  }
}

// ── Inputs ───────────────────────────────────────────────────────────────────

class _Choices extends StatelessWidget {
  const _Choices({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final Map<String, String> options;
  final String? value;
  final String? hint;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ThtType.body,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final entry in options.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: value == entry.key,
                showCheckmark: false,
                onSelected: (_) =>
                    onChanged(value == entry.key ? null : entry.key),
                selectedColor: AppColors.primaryOrangeLight,
                labelStyle: TextStyle(
                  fontSize: ThtType.body,
                  fontWeight:
                      value == entry.key ? FontWeight.w700 : FontWeight.w500,
                  color:
                      value == entry.key ? AppColors.primaryOrangeDark : null,
                ),
                side: value == entry.key
                    ? const BorderSide(color: AppColors.primaryOrange)
                    : BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.slate200,
                      ),
              ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            style: TextStyle(
              fontSize: ThtType.caption,
              color: isDark ? AppColors.slate500 : AppColors.slate400,
            ),
          ),
        ],
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.disabledHint,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      decoration: InputDecoration(labelText: label),
      hint: enabled ? null : Text(disabledHint ?? ''),
      items: [
        for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year - 28),
          // A teacher on this platform is an adult; the range keeps the picker
          // from opening decades away from a plausible answer.
          firstDate: DateTime(now.year - 70),
          lastDate: DateTime(now.year - 18),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value == null
              ? 'Not set'
              : '${value!.day} ${_month(value!.month)} ${value!.year}',
          style: const TextStyle(fontSize: ThtType.bodyStrong),
        ),
      ),
    );
  }

  String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];
}


/// Four questions, then an About Me written from the answers.
///
/// The questions are the ones the model cannot guess and the teacher answers in
/// a sentence: how they teach, a result they are proud of, what sets them apart.
/// Everything else -- subjects, classes, years, city -- is read off the profile
/// and the open form, so the teacher is never asked to retype what we already
/// have.
class _AboutWriterSheet extends ConsumerStatefulWidget {
  const _AboutWriterSheet({required this.profile, required this.currentAbout});

  final TutorProfile profile;
  final String currentAbout;

  static Future<String?> show(
    BuildContext context, {
    required TutorProfile profile,
    required String currentAbout,
  }) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _AboutWriterSheet(
          profile: profile,
          currentAbout: currentAbout,
        ),
      );

  @override
  ConsumerState<_AboutWriterSheet> createState() => _AboutWriterSheetState();
}

class _AboutWriterSheetState extends ConsumerState<_AboutWriterSheet> {
  static const _tones = ['Professional', 'Friendly', 'Confident', 'Simple'];

  final _style = TextEditingController();
  final _achievement = TextEditingController();
  final _unique = TextEditingController();

  String _tone = _tones.first;
  bool _running = false;
  String? _error;
  String? _result;

  @override
  void dispose() {
    for (final c in [_style, _achievement, _unique]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _running = true;
      _error = null;
    });

    final p = widget.profile;
    try {
      final written = await ref.read(usersRepositoryProvider).enhanceAboutMe(
            currentAbout: widget.currentAbout,
            // The picker writes class_subjects; subjects and classes are
            // read-only derivations of it, so flattening the map is the only
            // way to describe a teacher who has never used the website.
            subjects: p.classSubjects.values
                .expand((s) => s)
                .where((s) => s.trim().isNotEmpty)
                .toSet()
                .toList(),
            classes: p.classSubjects.keys.toList(),
            experience: p.experienceYears > 0 ? '${p.experienceYears}' : null,
            qualifications: p.highestQualification.trim().isEmpty
                ? null
                : p.highestQualification,
            city: p.city.trim().isEmpty ? null : p.city,
            teachingStyle: _style.text.trim(),
            achievement: _achievement.text.trim(),
            unique: _unique.text.trim(),
            tone: _tone,
          );
      if (!mounted) return;
      setState(() {
        _running = false;
        _result = written;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

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
                      'Help me write this',
                      style: TextStyle(
                        fontSize: ThtType.title,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _running ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (_result == null) ...[
                Text(
                  'Answer what you can in a line each. Your subjects, classes '
                  'and years are already filled in from your profile.',
                  style: TextStyle(fontSize: ThtType.body, height: 1.5, color: muted),
                ),
                const SizedBox(height: AppSpacing.base),
                TextField(
                  controller: _style,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'How do you teach?',
                    hintText: 'Concept first, then past papers',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                TextField(
                  controller: _achievement,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'A result you are proud of',
                    hintText: 'Took a Class 10 student from 48% to 81%',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                TextField(
                  controller: _unique,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'What makes you different?',
                    hintText: 'Weekly test and a parent update every Sunday',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                _Choices(
                  label: 'Tone',
                  options: {for (final t in _tones) t: t},
                  value: _tone,
                  onChanged: (v) => setState(() => _tone = v ?? _tones.first),
                ),
              ] else ...[
                Text(
                  'Read it before you keep it. Nothing is saved until you tap '
                  'Save on your profile.',
                  style: TextStyle(fontSize: ThtType.body, height: 1.5, color: muted),
                ),
                const SizedBox(height: AppSpacing.base),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate800 : AppColors.slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.slate700 : AppColors.slate200,
                    ),
                  ),
                  child: Text(
                    _result!,
                    style: TextStyle(
                      fontSize: ThtType.bodyStrong,
                      height: 1.6,
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                NoteBox(message: _error!),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (_result == null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _running ? null : _run,
                    child: _running
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Write it'),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _running
                            ? null
                            : () => setState(() => _result = null),
                        child: const Text('Try again'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(_result),
                        child: const Text('Use this'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
