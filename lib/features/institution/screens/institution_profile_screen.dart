import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/institution_profile.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/institution/providers/institution_providers.dart';

/// The institute's own details — what a teacher sees before applying.
class InstitutionProfileScreen extends ConsumerWidget {
  const InstitutionProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(institutionProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institute profile'),
        actions: [
          IconButton(
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: AsyncView<InstitutionProfile>(
        value: profile,
        onRetry: () => ref.invalidate(institutionProfileProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 90),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(institutionProfileProvider);
            await ref.read(institutionProfileProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              _Identity(profile: p),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                'Details',
                actionLabel: 'Edit',
                onAction: () => EditInstitutionSheet.show(context, p),
              ),
              const SizedBox(height: AppSpacing.md),
              THTCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(
                      label: 'Contact person',
                      value: p.contactPerson.orNotSet,
                    ),
                    const Divider(height: 1),
                    _Row(
                      label: 'Established',
                      value: p.establishedYear?.toString() ?? 'Not set',
                    ),
                    const Divider(height: 1),
                    _Row(label: 'Address', value: p.address.orNotSet),
                    const Divider(height: 1),
                    _Row(label: 'Website', value: p.website.orNotSet),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                'About',
                subtitle: 'Teachers read this before applying',
              ),
              const SizedBox(height: AppSpacing.md),
              THTCard(
                onTap: () => EditInstitutionSheet.show(context, p),
                child: Text(
                  p.about.trim().isEmpty
                      ? 'Nothing written yet. A few honest lines about your '
                          'institute, what you teach and who you are looking '
                          'for will get better applicants.'
                      : p.about.trim(),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    fontStyle: p.about.trim().isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: p.about.trim().isEmpty
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.slate400
                            : AppColors.slate500)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          "You'll need your phone number and password to sign back in.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(authProvider.notifier).logout();
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile});

  final InstitutionProfile profile;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return THTCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryOrangeLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              Fmt.initials(profile.name),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryOrangeDark,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.trim().isEmpty
                      ? 'Unnamed institute'
                      : profile.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Pill(
                  profile.isVerified ? 'Verified' : 'Not verified yet',
                  tone: profile.isVerified ? Tone.success : Tone.warning,
                  icon: profile.isVerified
                      ? Icons.verified_rounded
                      : Icons.shield_outlined,
                  dense: true,
                ),
                if (!profile.isVerified) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Our team verifies institutes before their vacancies go '
                    'out widely.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.slate400 : AppColors.slate500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit sheet ───────────────────────────────────────────────────────────────

class EditInstitutionSheet extends ConsumerStatefulWidget {
  const EditInstitutionSheet({super.key, required this.profile});

  final InstitutionProfile profile;

  static Future<void> show(BuildContext context, InstitutionProfile profile) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => EditInstitutionSheet(profile: profile),
      );

  @override
  ConsumerState<EditInstitutionSheet> createState() =>
      _EditInstitutionSheetState();
}

class _EditInstitutionSheetState extends ConsumerState<EditInstitutionSheet> {
  final _form = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.profile.name);
  late final _contact = TextEditingController(text: widget.profile.contactPerson);
  late final _year = TextEditingController(
    text: widget.profile.establishedYear?.toString() ?? '',
  );
  late final _address = TextEditingController(text: widget.profile.address);
  late final _website = TextEditingController(text: widget.profile.website);
  late final _about = TextEditingController(text: widget.profile.about);

  bool _saving = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    for (final c in [_name, _contact, _year, _address, _website, _about]) {
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
                      'Institute details',
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
              child: Form(
                key: _form,
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Institute name',
                        errorText: _fieldErrors['institution_name'],
                      ),
                      validator: (v) => (v ?? '').trim().length < 2
                          ? 'Please enter your institute name'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    TextFormField(
                      controller: _contact,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Contact person',
                        errorText: _fieldErrors['contact_person'],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    TextFormField(
                      controller: _year,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Year established',
                        errorText: _fieldErrors['established_year'],
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return null;
                        final year = int.tryParse(s);
                        final now = DateTime.now().year;
                        if (year == null || year < 1800 || year > now) {
                          return 'Enter a year between 1800 and $now';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.base),
                    TextFormField(
                      controller: _address,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        alignLabelWithHint: true,
                        errorText: _fieldErrors['address'],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    TextFormField(
                      controller: _website,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'Website (optional)',
                        hintText: 'https://…',
                        errorText: _fieldErrors['website'],
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return null;
                        final uri = Uri.tryParse(s);
                        // The backend uses a URLField, which rejects a bare
                        // domain — catch it here rather than after a round trip.
                        return uri != null && uri.hasScheme && uri.host.isNotEmpty
                            ? null
                            : 'Include https:// at the start';
                      },
                    ),
                    const SizedBox(height: AppSpacing.base),
                    TextFormField(
                      controller: _about,
                      maxLines: 5,
                      maxLength: 800,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'About your institute',
                        hintText: 'What you teach, how long you have run, and '
                            'what you look for in a teacher.',
                        alignLabelWithHint: true,
                        errorText: _fieldErrors['about'],
                      ),
                    ),
                  ],
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

  Map<String, dynamic> _changes() {
    final p = widget.profile;
    final out = <String, dynamic>{};

    void put(String key, Object? next, Object? current) {
      if (next != current) out[key] = next;
    }

    put('institution_name', _name.text.trim(), p.name);
    put('contact_person', _contact.text.trim(), p.contactPerson);
    put('established_year', int.tryParse(_year.text.trim()), p.establishedYear);
    put('address', _address.text.trim(), p.address);
    put('website', _website.text.trim(), p.website);
    put('about', _about.text.trim(), p.about);

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
      await ref.read(usersRepositoryProvider).updateInstitutionProfile(changes);
      if (!mounted) return;
      ref.invalidate(institutionProfileProvider);
      Navigator.of(context).pop();
      context.showMessage('Institute details updated.');
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      setState(() {
        _saving = false;
        _fieldErrors = failure.fieldErrors;
      });
      if (failure.fieldErrors.isEmpty) context.showFailure(failure);
    }
  }
}

extension _Fallback on String {
  String get orNotSet => trim().isEmpty ? 'Not set' : trim();
}
