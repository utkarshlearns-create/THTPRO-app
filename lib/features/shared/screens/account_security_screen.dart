import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/core/utils/formatters.dart';

/// Password and phone number, for every role.
///
/// One screen rather than three: the endpoints behind it are role-agnostic, and
/// a parent, a teacher and an institute all need exactly these two things.
class AccountSecurityScreen extends ConsumerWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(currentUserProvider).valueOrNull?.phone;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final canDelete =
        UsersRepository.canSelfDelete(ref.watch(authProvider).role);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign-in and security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.base,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          const SectionHeader(
            'Password',
            icon: Icons.lock_outline_rounded,
            iconTone: Tone.neutral,
          ),
          const SizedBox(height: AppSpacing.md),
          THTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use at least 8 characters. Changing it here changes it on '
                  'the website too — it is one account.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: muted),
                ),
                const SizedBox(height: AppSpacing.base),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _ChangePasswordSheet.show(context),
                    icon: const Icon(Icons.key_outlined, size: 18),
                    label: const Text('Change password'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            'Phone number',
            icon: Icons.smartphone_outlined,
            iconTone: Tone.neutral,
          ),
          const SizedBox(height: AppSpacing.md),
          THTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phone == null || phone.isEmpty
                      ? 'No number on the account'
                      : Fmt.phone(phone),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is how you sign in, so a change has to be confirmed by '
                  'an OTP sent to the new number.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: muted),
                ),
                const SizedBox(height: AppSpacing.base),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _ChangePhoneSheet.show(context),
                    icon: const Icon(Icons.sync_alt_rounded, size: 18),
                    label: const Text('Change phone number'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            'Close account',
            icon: Icons.person_off_outlined,
            iconTone: Tone.critical,
          ),
          const SizedBox(height: AppSpacing.md),
          THTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canDelete
                      ? 'Closing your account signs you out everywhere and '
                          'removes your profile from search and from every job '
                          'you have applied to. Your number is freed, so you '
                          'can sign up again later if you change your mind.'
                      : 'An institute account is closed by our team, because '
                          'the vacancies and hires made under it have to be '
                          'settled first. Tell us below and we will call you.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: muted),
                ),
                const SizedBox(height: AppSpacing.base),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => canDelete
                        ? _DeleteAccountSheet.show(context)
                        : _RequestClosureSheet.show(context),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(canDelete
                        ? 'Delete my account'
                        : 'Request account closure'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
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

// ── Close account ────────────────────────────────────────────────────────────

/// Deleting an account is the one action on this screen that cannot be undone
/// from the app, so it asks for the word rather than for a tap: a destructive
/// confirm that only needs a second tap is the same as no confirm at all on a
/// phone, where the button lands under a thumb already moving.
class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  static const confirmWord = 'DELETE';

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const _DeleteAccountSheet(),
      );

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _form = GlobalKey<FormState>();
  final _confirm = TextEditingController();
  final _reason = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _confirm.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(usersRepositoryProvider)
          .deleteMyAccount(reason: _reason.text);
      if (!mounted) return;
      // The token died with is_active, so every provider holding account data
      // is now holding something unreachable. Close the sheet first, then sign
      // out: the router watches auth and sends an unauthenticated app to
      // /login on its own, and a sheet still mounted over that is a dead layer
      // the user has to dismiss to reach the login form.
      Navigator.of(context).pop();
      await ref.read(authProvider.notifier).logout();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
        title: 'Delete my account',
        saving: _saving,
        actionLabel: 'Delete my account',
        destructive: true,
        onSave: _save,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NoteBox(
                tone: Tone.critical,
                title: 'This signs you out and hides your profile',
                message: 'Your applications, credits and tuition history are '
                    'kept as a record with our team, but your profile stops '
                    'appearing anywhere and you will not be able to sign in. '
                    'Your phone number is freed, so you can register again '
                    'with it later.',
              ),
              const SizedBox(height: AppSpacing.base),
              TextFormField(
                controller: _reason,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Why are you leaving? (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              TextFormField(
                controller: _confirm,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                  prefixIcon: Icon(Icons.warning_amber_rounded, size: 20),
                ),
                validator: (v) =>
                    (v ?? '').trim().toUpperCase() ==
                            _DeleteAccountSheet.confirmWord
                        ? null
                        : 'Type DELETE exactly to confirm',
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                NoteBox(message: _error!),
              ],
            ],
          ),
        ),
      );
}

/// The institute door. The server refuses a self-delete for anything but a
/// teacher or a parent, so offering the same button to an institute would be a
/// button that 403s. This files the request through the support enquiry the app
/// already has, which lands on the desk that can actually settle the account.
class _RequestClosureSheet extends ConsumerStatefulWidget {
  const _RequestClosureSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const _RequestClosureSheet(),
      );

  @override
  ConsumerState<_RequestClosureSheet> createState() =>
      _RequestClosureSheetState();
}

class _RequestClosureSheetState extends ConsumerState<_RequestClosureSheet> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    final user = ref.read(currentUserProvider).valueOrNull;
    try {
      await ref.read(usersRepositoryProvider).raiseEnquiry(
            name: user?.firstName.trim().isNotEmpty == true
                ? user!.firstName.trim()
                : 'Institute',
            subject: 'Account closure request',
            message: _reason.text.trim(),
            phone: user?.phone,
            email: user?.email,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      context.showMessage('Request sent. Our team will call you to confirm.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
        title: 'Request account closure',
        saving: _saving,
        actionLabel: 'Send request',
        destructive: true,
        onSave: _save,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NoteBox(
                tone: Tone.warning,
                message: 'We will call you on the number on this account to '
                    'confirm before anything is closed. Nothing changes until '
                    'then.',
              ),
              const SizedBox(height: AppSpacing.base),
              TextFormField(
                controller: _reason,
                maxLines: 4,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tell us why',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v ?? '').trim().length < 5
                    ? 'A line or two is enough'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                NoteBox(message: _error!),
              ],
            ],
          ),
        ),
      );
}

// ── Password ─────────────────────────────────────────────────────────────────

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const _ChangePasswordSheet(),
      );

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _saving = false;
  bool _reveal = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(usersRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      context.showMessage('Password changed.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
        title: 'Change password',
        saving: _saving,
        actionLabel: 'Change password',
        onSave: _save,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _current,
                obscureText: !_reveal,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _reveal = !_reveal),
                    icon: Icon(
                      _reveal
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    tooltip: _reveal ? 'Hide' : 'Show',
                  ),
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter your current password' : null,
              ),
              const SizedBox(height: AppSpacing.base),
              TextFormField(
                controller: _next,
                obscureText: !_reveal,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  helperText: 'At least 8 characters',
                  prefixIcon: Icon(Icons.key_outlined, size: 20),
                ),
                validator: (v) {
                  final s = v ?? '';
                  if (s.length < 8) return 'Use at least 8 characters';
                  if (s == _current.text) {
                    return 'That is your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.base),
              TextFormField(
                controller: _confirm,
                obscureText: !_reveal,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.check_circle_outline_rounded, size: 20),
                ),
                validator: (v) =>
                    v == _next.text ? null : 'The two do not match',
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                NoteBox(message: _error!),
              ],
            ],
          ),
        ),
      );
}

// ── Phone ────────────────────────────────────────────────────────────────────

class _ChangePhoneSheet extends ConsumerStatefulWidget {
  const _ChangePhoneSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const _ChangePhoneSheet(),
      );

  @override
  ConsumerState<_ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends ConsumerState<_ChangePhoneSheet> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  /// False while asking for password + number, true once the OTP is out.
  bool _awaitingOtp = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_password, _phone, _otp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(usersRepositoryProvider).requestPhoneChange(
            currentPassword: _password.text,
            newPhone: _phone.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _awaitingOtp = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }

  Future<void> _confirmOtp() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(usersRepositoryProvider).confirmPhoneChange(
            newPhone: _phone.text.trim(),
            otp: _otp.text.trim(),
          );
      if (!mounted) return;
      // The account record now holds a different number — drop the cached copy
      // so every screen showing the phone stops showing the old one.
      ref.invalidate(currentUserProvider);
      Navigator.of(context).pop();
      context.showMessage('Phone number updated. Use it to sign in next time.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
        title: 'Change phone number',
        saving: _saving,
        actionLabel: _awaitingOtp ? 'Confirm and change' : 'Send OTP',
        onSave: _awaitingOtp ? _confirmOtp : _requestOtp,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _password,
                obscureText: true,
                enabled: !_awaitingOtp,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter your password' : null,
              ),
              const SizedBox(height: AppSpacing.base),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                enabled: !_awaitingOtp,
                decoration: const InputDecoration(
                  labelText: 'New phone number',
                  prefixIcon: Icon(Icons.smartphone_outlined, size: 20),
                ),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return 'Enter a 10-digit number';
                  return null;
                },
              ),
              if (_awaitingOtp) ...[
                const SizedBox(height: AppSpacing.base),
                TextFormField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    helperText: 'Sent to the new number',
                    prefixIcon: Icon(Icons.password_outlined, size: 20),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter the code' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                const NoteBox(
                  tone: Tone.warning,
                  message: 'Once this goes through, the new number is what you '
                      'sign in with. The old one stops working.',
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                NoteBox(message: _error!),
              ],
            ],
          ),
        ),
      );
}

// ── Shared sheet chrome ──────────────────────────────────────────────────────

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.child,
    required this.saving,
    required this.actionLabel,
    required this.onSave,
    this.destructive = false,
  });

  final String title;
  final Widget child;
  final bool saving;
  final String actionLabel;
  final Future<void> Function() onSave;

  /// Paints the action red. A delete and a save must not look alike — the
  /// confirm word is the real guard, but the colour is what stops the tap.
  final bool destructive;

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
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              child,
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: AppColors.error)
                      : null,
                  onPressed: saving ? null : () => onSave(),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
