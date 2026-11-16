import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/repositories/jobs_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_type.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// "Tell us your teacher requirement" — for a school, college or coaching
/// institute that wants us to shortlist, with no account at all.
///
/// A school with a vacancy is not a parent with a child, and it must not have
/// to pretend to be one. Without this screen an institute's only doors were
/// signup or the parent requirement wizard, which asks for a student's name,
/// gender and board — so "we need three Physics faculty for the NEET batch"
/// would have reached the desk looking like one child needing a home tutor.
///
/// Not the same thing as [PostVacancyScreen]: that one posts a vacancy to the
/// jobs board for teachers to apply to, and needs an institute account. This
/// one hands the requirement to the institutional desk and asks them to call —
/// the website's `SchoolRequirementForm`, field for field, posting to the same
/// filer (`register_institute_requirement`, one lead per institute whichever
/// door it came through).
class SchoolRequirementScreen extends ConsumerStatefulWidget {
  const SchoolRequirementScreen({super.key});

  @override
  ConsumerState<SchoolRequirementScreen> createState() =>
      _SchoolRequirementScreenState();
}

class _SchoolRequirementScreenState
    extends ConsumerState<SchoolRequirementScreen> {
  final _form = GlobalKey<FormState>();

  final _instituteName = TextEditingController();
  final _area = TextEditingController();
  final _requirement = TextEditingController();
  final _positions = TextEditingController();
  final _qualification = TextEditingController();
  final _salary = TextEditingController();
  final _timing = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _extra = TextEditingController();

  bool _sending = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  /// Set once the desk has it. The screen then shows nothing but the
  /// confirmation: a form still on screen behind a success message is an
  /// invitation to send the same requirement twice.
  bool _done = false;

  /// True when the server recognised this as a requirement it already holds.
  /// Worth saying out loud — the alternative is an institute wondering whether
  /// their second attempt went through at all.
  bool _duplicate = false;

  @override
  void dispose() {
    for (final c in [
      _instituteName,
      _area,
      _requirement,
      _positions,
      _qualification,
      _salary,
      _timing,
      _name,
      _phone,
      _extra,
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
      appBar: AppBar(title: const Text('Teacher requirement')),
      body: _done
          ? _Received(phone: _phone.text.trim(), duplicate: _duplicate)
          : Form(
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
                    'For schools, colleges and coaching institutes. No account '
                    'needed — the name and the requirement are enough to '
                    'start, the rest just helps us shortlist faster.',
                    style: TextStyle(fontSize: ThtType.body, height: 1.5, color: muted),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  TextFormField(
                    controller: _instituteName,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'School / coaching name *',
                      hintText: 'Sunrise Public School',
                      errorText: _fieldErrors['institute_name'],
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Tell us the institute name'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.base),

                  TextFormField(
                    controller: _area,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'City / area',
                      hintText: 'Gomti Nagar, Lucknow',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  TextFormField(
                    controller: _requirement,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Teachers you need *',
                      hintText: 'Physics faculty for Class 11-12 / NEET batch',
                      alignLabelWithHint: true,
                      errorText: _fieldErrors['requirement'],
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Tell us what you need'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.base),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _positions,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'How many teachers',
                            hintText: '3',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _salary,
                          decoration: const InputDecoration(
                            labelText: 'Salary you offer',
                            hintText: '25,000 - 35,000',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.base),

                  TextFormField(
                    controller: _qualification,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Qualification / experience',
                      hintText: 'M.Sc Physics, 3+ years',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  TextFormField(
                    controller: _timing,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Timing / joining',
                      hintText: 'Morning shift, joining immediately',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      hintText: 'Contact person',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: 'WhatsApp number *',
                      hintText: '10-digit mobile',
                      prefixText: '+91  ',
                      errorText: _fieldErrors['phone'],
                    ),
                    // Same three checks the server runs, said in the order
                    // someone fixes them in.
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'We need a number to call you on';
                      if (s.length != 10) return 'A mobile number is 10 digits';
                      if (!'6789'.contains(s[0])) {
                        return 'Must start with 6, 7, 8 or 9';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.base),

                  TextFormField(
                    controller: _extra,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Anything else we should know',
                      hintText: 'Board, batch size, interview process, '
                          'anything at all',
                      alignLabelWithHint: true,
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    NoteBox(message: _error!),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send requirement'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const NoteBox(
                    tone: Tone.info,
                    message: 'Our institutional team calls you, shortlists on '
                        'your behalf and shares matching teacher profiles. '
                        'Nothing to pay to send this.',
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
      _sending = true;
      _error = null;
    });

    try {
      final duplicate =
          await ref.read(jobsRepositoryProvider).submitInstituteRequirement({
        'institute_name': _instituteName.text.trim(),
        'area': _area.text.trim(),
        'requirement': _requirement.text.trim(),
        'positions': _positions.text.trim(),
        'qualification': _qualification.text.trim(),
        'salary': _salary.text.trim(),
        'timing': _timing.text.trim(),
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'extra': _extra.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _sending = false;
        _done = true;
        _duplicate = duplicate;
      });
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      setState(() {
        _sending = false;
        _fieldErrors = failure.fieldErrors;
        _error = failure.fieldErrors.isEmpty ? failure.message : null;
      });
    }
  }
}

/// The confirmation, in place of the form.
class _Received extends StatelessWidget {
  const _Received({required this.phone, required this.duplicate});

  final String phone;

  /// The desk already held this requirement. Said plainly, because the usual
  /// reason to send a second time is doubt that the first one landed.
  final bool duplicate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: Tone.success.foreground(Theme.of(context).brightness),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              duplicate ? 'Already with us' : 'Requirement received',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ThtType.headline,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isDark ? AppColors.slate50 : AppColors.slate900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              duplicate
                  ? 'We already have this requirement on the desk, so nothing '
                      'has been duplicated. Our institutional team will call '
                      'you on $phone.'
                  : 'Our institutional team will call you on $phone and share '
                      'matching teacher profiles. You do not need to create '
                      'an account for this.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ThtType.bodyStrong,
                height: 1.5,
                color: isDark ? AppColors.slate400 : AppColors.slate500,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              // Popped where there is somewhere to pop to; a deep link
              // straight here has nothing behind it, so it lands home.
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
