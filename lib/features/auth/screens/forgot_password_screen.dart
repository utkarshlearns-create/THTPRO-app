import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/network/api_client.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/features/shared/widgets/tht_button.dart';
import 'package:tht_app/features/shared/widgets/tht_text_field.dart';

/// Start a password reset.
///
/// `POST /api/auth/forgot-password/` sends a **reset link over WhatsApp**, not
/// a code — the screen used to promise an OTP and offer a box to type it into,
/// which no part of the backend would ever have accepted. The link opens
/// thehometuitions.com, so the journey finishes on the web and this screen's
/// job ends at "we've sent it".
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _loading = false;
  String? _error;

  /// The number we sent to, once the request has succeeded.
  String? _sentTo;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final phone = _phoneController.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiClient.instance
          .post('/api/auth/forgot-password/', data: {'phone': phone});
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sentTo = phone;
      });
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      setState(() {
        _loading = false;
        // 404 is the one case the server answers plainly — every other outcome
        // is deliberately vague so this form cannot be used to discover which
        // numbers hold accounts.
        _error = failure.isNotFound
            ? 'We could not find an account with that number. '
                'You can create one instead.'
            : failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _sentTo == null ? _buildForm(context) : _buildSent(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reset your password',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter your registered number and we will send a reset link to '
            'that number on WhatsApp.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.slate400
                  : AppColors.slate500,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ThtTextField(
            controller: _phoneController,
            label: 'Phone number',
            hint: '10-digit mobile number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            enabled: !_loading,
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
              if (digits.isEmpty) return 'Enter your phone number';
              // The server takes the last 10 digits, so +91 and 0 prefixes are
              // both fine — only the count matters.
              if (digits.length < 10) return 'That is not a 10-digit number';
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            NoteBox(message: _error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          ThtButton(
            label: 'Send reset link',
            isLoading: _loading,
            isExpanded: true,
            onPressed: _loading ? null : _send,
          ),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to sign in'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.mark_chat_read_outlined,
          size: 44,
          color: Tone.success.foreground(Theme.of(context).brightness),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Check WhatsApp',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'If $_sentTo is registered with us, a reset link is on its way to '
          'that number. Tap it to choose a new password, then come back here '
          'and sign in.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const NoteBox(
          tone: Tone.info,
          title: 'The link opens in your browser',
          message: 'Password reset finishes on thehometuitions.com. Your new '
              'password works here straight away — it is the same account.',
        ),
        const SizedBox(height: AppSpacing.xl),
        ThtButton(
          label: 'Back to sign in',
          isExpanded: true,
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _sentTo = null),
            child: const Text('Use a different number'),
          ),
        ),
      ],
    );
  }
}
