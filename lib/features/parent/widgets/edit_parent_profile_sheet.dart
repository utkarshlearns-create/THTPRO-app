import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/app_user.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// Edits the handful of fields a parent account actually holds.
///
/// One sheet, not the teacher's three: a parent record is name, email and an
/// address, where the teacher model is long enough that a single form would be
/// a scroll of unrelated questions.
class EditParentProfileSheet extends ConsumerStatefulWidget {
  const EditParentProfileSheet({super.key, required this.user});

  final AppUser user;

  static Future<void> show(BuildContext context, AppUser user) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => EditParentProfileSheet(user: user),
      );

  @override
  ConsumerState<EditParentProfileSheet> createState() =>
      _EditParentProfileSheetState();
}

class _EditParentProfileSheetState
    extends ConsumerState<EditParentProfileSheet> {
  final _form = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.user.firstName);
  late final _email = TextEditingController(text: widget.user.email ?? '');
  late final _city = TextEditingController(text: widget.user.city ?? '');
  late final _area = TextEditingController(text: widget.user.area ?? '');
  late final _address = TextEditingController(text: widget.user.address ?? '');

  bool _saving = false;

  /// Per-field messages the API rejected the last submission with.
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    for (final c in [_name, _email, _city, _area, _address]) {
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
        initialChildSize: 0.8,
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
                      'Your details',
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
                  children: _fields(isDark),
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

  List<Widget> _fields(bool isDark) => [
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Full name',
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            errorText: _fieldErrors['first_name'],
          ),
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return 'Enter your name';
            if (s.length < 2) return 'That looks too short';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.base),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Optional',
            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
            errorText: _fieldErrors['email'],
          ),
          validator: (v) {
            final s = (v ?? '').trim();
            if (s.isEmpty) return null;
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
              return 'That does not look like an email address';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.base),
        // Read-only on purpose. The serializer accepts a phone change, but the
        // number is the login credential and nothing here re-verifies it by
        // OTP — a successful edit would lock the account's owner out of it.
        _ReadOnlyPhone(phone: widget.user.phone, isDark: isDark),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'WHERE YOU LIVE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Teachers near you are matched on this.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        // Free text rather than dropdowns: the app's location constant is a
        // state→cities map and this record has no state field, so a dropdown
        // would reject a city the backend already holds.
        TextFormField(
          controller: _city,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'City',
            prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
            errorText: _fieldErrors['city'],
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        TextFormField(
          controller: _area,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Area or locality',
            prefixIcon: const Icon(Icons.map_outlined, size: 20),
            errorText: _fieldErrors['area'],
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        TextFormField(
          controller: _address,
          maxLines: 3,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Full address',
            hintText: 'Shown only to a teacher you have hired',
            errorText: _fieldErrors['address'],
          ),
        ),
      ];

  /// Only what actually changed, so a partial edit never clears a field this
  /// sheet doesn't show.
  ///
  /// `role` is writable on this serializer, so the payload is built key by key
  /// rather than from the whole form — a stray key here moves the account to
  /// another role.
  Map<String, dynamic> _changes() {
    final u = widget.user;
    final out = <String, dynamic>{};

    void put(String key, Object? next, Object? current) {
      if (next != current) out[key] = next;
    }

    put('first_name', _name.text.trim(), u.firstName);
    put('email', _email.text.trim(), u.email ?? '');
    put('city', _city.text.trim(), u.city ?? '');
    put('area', _area.text.trim(), u.area ?? '');
    put('address', _address.text.trim(), u.address ?? '');

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
      await ref.read(usersRepositoryProvider).updateMe(changes);
      if (!mounted) return;
      ref.invalidate(currentUserProvider);
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

class _ReadOnlyPhone extends StatelessWidget {
  const _ReadOnlyPhone({required this.phone, required this.isDark});

  final String? phone;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.slate50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.slate200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (phone ?? '').trim().isEmpty ? 'No number on file' : phone!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This is how you sign in. Contact support to change it.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
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
