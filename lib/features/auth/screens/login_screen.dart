import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/network/api_client.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// Sign in with a phone number or email.
///
/// The same credentials as the website — one account, one backend, one session.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPhoneMode = true;
  bool _showPassword = false;
  bool _loading = false;
  String? _error;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final username = _isPhoneMode
          ? _phoneController.text.trim()
          : _emailController.text.trim();

      final response = await ApiClient.instance.post(
        '/api/users/login/',
        data: {'username': username, 'password': _passwordController.text},
      );

      final data = (response.data as Map).cast<String, dynamic>();

      if (data['requires_2fa'] == true) {
        setState(() {
          _error = 'This account uses two-factor authentication. '
              'Please sign in on thehometuitions.com for now.';
          _loading = false;
        });
        return;
      }

      final access = data['access'] as String?;
      final refreshToken = data['refresh'] as String?;

      if (access == null || refreshToken == null) {
        setState(() {
          _error = 'The server did not return a session. Please try again.';
          _loading = false;
        });
        return;
      }

      await ref.read(authProvider.notifier).onLoginSuccess(
            access: access,
            refresh: refreshToken,
            userData: data,
          );
      // GoRouter's redirect takes it from here.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiFailure.from(e).message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _Backdrop()),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      const _LanguagePicker(),
                      const SizedBox(height: AppSpacing.sm),
                      const _Brand(),
                      const SizedBox(height: AppSpacing.base),
                      const _Hero(),
                      const SizedBox(height: AppSpacing.lg),
                      _card(isDark),
                    ]
                        .animate(interval: 60.ms)
                        .fadeIn(duration: 340.ms)
                        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── The one card everything below the illustration sits on ────────────────

  Widget _card(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.slate200.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : AppColors.slate900.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _form(isDark),
          const SizedBox(height: AppSpacing.sm),
          const _SignUpPrompt(),
          const SizedBox(height: AppSpacing.md),
          const _QuickAccess(),
          const SizedBox(height: AppSpacing.lg),
          const _TrustNote(),
        ],
      ),
    );
  }

  Widget _form(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeToggle(
            isPhone: _isPhoneMode,
            onChanged: (phone) => setState(() {
              _isPhoneMode = phone;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.base),
          if (_isPhoneMode)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                // Only paints once the field is focused or filled, so at rest
                // the field reads exactly as the hint alone.
                prefixText: '+91  ',
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'Enter your phone number';
                if (s.length != 10) return 'A mobile number is 10 digits';
                if (!'6789'.contains(s[0])) {
                  return 'Must start with 6, 7, 8 or 9';
                }
                return null;
              },
            )
          else
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                  return 'That does not look like an email address';
                }
                return null;
              },
            ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _loading ? null : _handleLogin(),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
              ),
            ),
            validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ErrorNote(message: _error!),
          ],
          const SizedBox(height: AppSpacing.md),
          _SignInButton(
            loading: _loading,
            onPressed: _loading ? null : _handleLogin,
          ),
        ],
      ),
    );
  }
}

// ── Backdrop ─────────────────────────────────────────────────────────────────

/// The warm page behind everything: a cream wash, a soft peach bloom in the
/// top-left, and the scattered dots and outlines that give the screen its
/// depth without asking for attention.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF15121B),
                  AppColors.slate950,
                  AppColors.slate950,
                ]
              : const [
                  Color(0xFFFCF0E6),
                  Color(0xFFFFF9F5),
                  Color(0xFFFFFDFC),
                ],
          stops: const [0, 0.42, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -110,
            top: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryOrange
                        .withValues(alpha: isDark ? 0.16 : 0.13),
                    AppColors.primaryOrange.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _MotifPainter(
                color: AppColors.primaryOrange
                    .withValues(alpha: isDark ? 0.30 : 0.22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dot grid, ring and diamond — placed in fractions of the viewport so they
/// hold their composition from a small phone up to a tablet.
class _MotifPainter extends CustomPainter {
  const _MotifPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Dot matrix, upper right.
    const cols = 6;
    const rows = 5;
    const gap = 13.0;
    final originX = size.width * 0.78;
    final originY = size.height * 0.16;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        canvas.drawCircle(
          Offset(originX + c * gap, originY + r * gap),
          1.7,
          fill,
        );
      }
    }

    // Loose dots, lower left of the illustration band.
    for (var r = 0; r < 2; r++) {
      for (var c = 0; c < 3; c++) {
        canvas.drawCircle(
          Offset(size.width * 0.09 + c * 11, size.height * 0.40 + r * 11),
          1.6,
          fill,
        );
      }
    }

    // Open ring, right edge.
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.265),
      9,
      stroke,
    );

    // Small diamond, left edge.
    final d = Offset(size.width * 0.07, size.height * 0.325);
    canvas.save();
    canvas.translate(d.dx, d.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 9, height: 9),
      stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MotifPainter oldDelegate) => oldDelegate.color != color;
}

// ── Language ─────────────────────────────────────────────────────────────────

/// The app ships in English only today. The control is real — it opens and it
/// tells the truth — rather than a chip that pretends to switch a locale
/// nothing has been translated into yet.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.slate200,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.slate900.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 17,
                  color: isDark ? AppColors.slate300 : AppColors.slate700,
                ),
                const SizedBox(width: 7),
                Text(
                  'English',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.slate100 : AppColors.slate800,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 19,
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.base,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate700 : AppColors.slate200,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Language',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryOrange,
                ),
                title: Text(
                  'English',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'हिन्दी and other Indian languages are on the way.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Brand ────────────────────────────────────────────────────────────────────

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 74,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'The Home Tuitions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          'Welcome back! 👋',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: isDark ? AppColors.slate50 : AppColors.slate900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Sign in to continue',
          style: TextStyle(
            fontSize: 14.5,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
      ],
    );
  }
}

// ── Illustration ─────────────────────────────────────────────────────────────

/// The tutoring illustration, with the two subject badges floating off its
/// corners the way they do in the design.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            left: 30,
            right: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              child: Image.asset(
                'assets/images/hero-main.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: AppColors.primaryOrangeLight,
                  child: Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 56,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 30,
            child: _FloatingBadge(icon: Icons.menu_book_rounded),
          ),
          const Positioned(
            right: 0,
            top: 6,
            child: _FloatingBadge(icon: Icons.school_rounded),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? AppColors.primaryOrange.withValues(alpha: 0.16)
            : AppColors.primaryOrange.withValues(alpha: 0.11),
      ),
      child: Icon(icon, size: 24, color: AppColors.primaryOrange),
    );
  }
}

// ── Phone / email toggle ─────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isPhone, required this.onChanged});

  final bool isPhone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.slate100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleTab(
              label: 'Phone',
              icon: Icons.phone_outlined,
              selected: isPhone,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleTab(
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              selected: !isPhone,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = selected
        ? AppColors.primaryOrange
        : (isDark ? AppColors.slate400 : AppColors.slate500);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.darkCard : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: selected && !isDark
                ? [
                    BoxShadow(
                      color: AppColors.slate900.withValues(alpha: 0.07),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Primary action ───────────────────────────────────────────────────────────

/// The design's wide orange bar: label dead-centre, arrow riding in a soft
/// circle at the trailing edge.
class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(AppRadius.lg);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.26),
                  blurRadius: 26,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: enabled
            ? AppColors.primaryOrange
            : AppColors.primaryOrange.withValues(alpha: 0.55),
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Error ────────────────────────────────────────────────────────────────────

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Tone.critical.background(brightness),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Tone.critical.border(brightness)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 17,
            color: Tone.critical.foreground(brightness),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Tone.critical.foreground(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign up ──────────────────────────────────────────────────────────────────

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
        TextButton(
          onPressed: () => context.push('/signup'),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

// ── Quick access ─────────────────────────────────────────────────────────────

/// The design's two role shortcuts, wired to signup with the role preselected.
///
/// They read "Continue as", not "Login as", because there is no session to be
/// had without credentials. What was here before wrote a literal
/// 'dev_access_token' straight into secure storage and set a role client-side,
/// letting anyone into the app with a credential the server rejects on the very
/// first call. That is a broken session dressed as a signed-in one, and it
/// shipped. A tile that promises a login it cannot deliver is how that starts.
class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // Tight on purpose: every point taken here is a point the two tiles get
      // back, and "Continue as Parent" has to stay on one line.
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryOrange.withValues(alpha: 0.08)
            : const Color(0xFFFFF6EE),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: isDark ? 0.22 : 0.14),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 17,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 5),
              Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFFFB923C)
                      : AppColors.primaryOrangeDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // IntrinsicHeight so the two tiles match even when one subtitle wraps
          // to a second line and the other does not. Stretching inside the
          // scroll view without it asks the tiles for an infinite height.
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _RoleTile(
                    icon: Icons.family_restroom_rounded,
                    title: 'Continue as Parent',
                    subtitle: 'I am looking for a tutor',
                    role: 'PARENT',
                    tone: Tone.accent,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _RoleTile(
                    icon: Icons.school_rounded,
                    title: 'Continue as Tutor',
                    subtitle: 'I want to teach students',
                    role: 'TEACHER',
                    tone: Tone.info,
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

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.role,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String role;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: () => context.push('/signup?role=$role'),
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.slate200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone.background(brightness),
                ),
                child: Icon(icon, size: 19, color: tone.foreground(brightness)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.35,
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.slate800 : AppColors.slate100,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: isDark ? AppColors.slate300 : AppColors.slate600,
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

// ── Trust ────────────────────────────────────────────────────────────────────

class _TrustNote extends StatelessWidget {
  const _TrustNote();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_rounded,
          size: 16,
          color: AppColors.primaryOrange,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '100% Verified Tutors • Safe & Secure',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
      ],
    );
  }
}
