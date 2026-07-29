import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/network/api_client.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/features/shared/widgets/tht_text_field.dart';
import 'package:tht_app/features/shared/widgets/tht_button.dart';

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
    if (!_formKey.currentState!.validate()) return;

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
        data: {
          'username': username,
          'password': _passwordController.text,
        },
      );

      final data = response.data as Map<String, dynamic>;

      // Check for 2FA requirement
      if (data['requires_2fa'] == true) {
        // TODO: Navigate to 2FA screen
        setState(() {
          _error = '2FA verification required. Coming soon.';
          _loading = false;
        });
        return;
      }

      final access = data['access'] as String?;
      final refreshToken = data['refresh'] as String?;

      if (access == null || refreshToken == null) {
        setState(() {
          _error = 'Invalid response from server.';
          _loading = false;
        });
        return;
      }

      await ref.read(authProvider.notifier).onLoginSuccess(
            access: access,
            refresh: refreshToken,
            userData: data,
          );

      // GoRouter's redirect will handle navigation
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Login failed. Please try again.';
      if (data is Map) {
        message = (data['detail'] ?? data['error'] ?? message).toString();
      }
      setState(() {
        _error = message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Brand mark ──
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'T',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to your account',
                  style: TextStyle(
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Mode toggle (Phone / Email) ──
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.slate100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _ModeTab(
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                        isActive: _isPhoneMode,
                        onTap: () => setState(() => _isPhoneMode = true),
                      ),
                      _ModeTab(
                        label: 'Email',
                        icon: Icons.email_outlined,
                        isActive: !_isPhoneMode,
                        onTap: () => setState(() => _isPhoneMode = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Form ──
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_isPhoneMode)
                        ThtTextField(
                          controller: _phoneController,
                          label: 'Phone number',
                          hint: 'Enter your 10-digit phone',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (v.trim().length != 10) {
                              return 'Enter a valid 10-digit number';
                            }
                            return null;
                          },
                        )
                      else
                        ThtTextField(
                          controller: _emailController,
                          label: 'Email address',
                          hint: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),
                      ThtTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outlined,
                        obscureText: !_showPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.slate400,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                // ── Forgot password ──
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),

                // ── Error ──
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Login button ──
                ThtButton(
                  label: 'Sign In',
                  onPressed: _handleLogin,
                  isLoading: _loading,
                  isExpanded: true,
                ),
                const SizedBox(height: 24),

                // ── Sign up link ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color:
                            isDark ? AppColors.slate400 : AppColors.slate500,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── DEV TOOLS: Easy Login ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🛠️ Developer Shortcuts',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ThtButton(
                              label: 'Login as Parent',
                              onPressed: () {
                                ref.read(authProvider.notifier).onLoginSuccess(
                                  access: 'dev_access_token',
                                  refresh: 'dev_refresh_token',
                                  userData: {
                                    'username': 'dev_parent',
                                    'role': 'PARENT',
                                    'first_name': 'Dev Parent'
                                  },
                                );
                              },
                              variant: ThtButtonVariant.filled,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ThtButton(
                              label: 'Login as Tutor',
                              onPressed: () {
                                ref.read(authProvider.notifier).onLoginSuccess(
                                  access: 'dev_access_token',
                                  refresh: 'dev_refresh_token',
                                  userData: {
                                    'username': 'dev_tutor',
                                    'role': 'TEACHER',
                                    'first_name': 'Dev Tutor'
                                  },
                                );
                              },
                              variant: ThtButtonVariant.outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppColors.slate700 : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? AppColors.primaryOrange
                    : AppColors.slate400,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? (isDark ? Colors.white : AppColors.slate800)
                      : AppColors.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
