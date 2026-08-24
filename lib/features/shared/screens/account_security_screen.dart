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
          const NoteBox(
            tone: Tone.info,
            title: 'Two-factor authentication',
            message: 'If your account uses 2FA, set it up and manage it on '
                'thehometuitions.com — the app does not carry that step yet.',
          ),
        ],
      ),
    );
  }
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
  });

  final String title;
  final Widget child;
  final bool saving;
  final String actionLabel;
  final Future<void> Function() onSave;

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
