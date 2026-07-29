import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:tht_app/core/network/api_client.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/features/shared/widgets/tht_text_field.dart';
import 'package:tht_app/features/shared/widgets/tht_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Signup screen
/// Multi-step: role selection → phone/email → OTP → password.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.initialRole});

  /// Preselects a role when the user already declared one — tapping "I'm a
  /// teacher" on the home screen and then landing on a form set to Parent is a
  /// small betrayal of a choice they just made.
  final String? initialRole;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  int _step = 0; // 0: role, 1: details, 2: OTP, 3: password
  late String _selectedRole = _validRole(widget.initialRole) ?? 'PARENT';

  /// Only the three roles this app serves may be preselected; anything else in
  /// the URL is ignored rather than trusted.
  static String? _validRole(String? raw) {
    final role = raw?.toUpperCase();
    return const {'PARENT', 'TEACHER', 'INSTITUTION'}.contains(role)
        ? role
        : null;
  }
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: Stack(
        children: [
          // ── Dynamic Background ──
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark 
                    ? AppColors.primaryOrange.withValues(alpha: 0.1) 
                    : const Color(0xFFF3F8FF),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? AppColors.primaryOrange.withValues(alpha: 0.2) : Colors.transparent,
                    blurRadius: 100,
                  )
                ],
              ),
            ).animate().fadeIn(duration: 1.seconds),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark 
                    ? AppColors.violet.withValues(alpha: 0.1) 
                    : const Color(0xFFFFF9ED),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? AppColors.violet.withValues(alpha: 0.2) : Colors.transparent,
                    blurRadius: 100,
                  )
                ],
              ),
            ).animate().fadeIn(duration: 1.seconds),
          ),
          
          // ── Main Content ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildStep(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildRoleStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildOtpStep();
      case 3:
        return _buildPasswordStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRoleStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      key: const ValueKey('role'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'I am a...',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF131D42),
                letterSpacing: -0.5,
              ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          'Choose your role to get started',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 40),
        
        _RoleCard(
          icon: Icons.family_restroom,
          title: 'Parent / Student',
          subtitle: 'Find verified home tutors',
          isSelected: _selectedRole == 'PARENT',
          onTap: () => setState(() => _selectedRole = 'PARENT'),
        ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
        
        const SizedBox(height: 16),
        
        _RoleCard(
          icon: Icons.school_outlined,
          title: 'Tutor / Teacher',
          subtitle: 'Find tuition opportunities',
          isSelected: _selectedRole == 'TEACHER',
          onTap: () => setState(() => _selectedRole = 'TEACHER'),
        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

        const SizedBox(height: 16),

        // Institutes have a full journey in the app — dashboard, vacancies,
        // teacher directory — but no way to sign up for it until now.
        _RoleCard(
          icon: Icons.apartment_outlined,
          title: 'School / Institute',
          subtitle: 'Hire teachers for your centre',
          isSelected: _selectedRole == 'INSTITUTION',
          onTap: () => setState(() => _selectedRole = 'INSTITUTION'),
        ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),

        const Spacer(),
        
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ThtButton(
            label: 'Continue',
            onPressed: () => setState(() => _step = 1),
            isExpanded: true,
          ),
        ).animate().fadeIn(delay: 500.ms).scale(),
        const SizedBox(height: 16),
        
        // ── Login Link ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(
                color: isDark ? AppColors.slate400 : AppColors.slate500,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/login'),
              child: const Text(
                'Log In',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailsStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Your details',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF131D42),
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 32),
        
        ThtTextField(
          controller: _nameController,
          label: 'Full name',
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outlined,
        ),
        const SizedBox(height: 20),
        
        ThtTextField(
          controller: _phoneController,
          label: 'Phone number',
          hint: '10-digit phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        
        ThtTextField(
          controller: _emailController,
          label: 'Email (optional)',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        
        const Spacer(),
        
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ThtButton(
            label: 'Continue',
            isLoading: _isLoading,
            onPressed: _sendOtp,
            isExpanded: true,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOtpStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Verify your number',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF131D42),
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent a 6-digit code to ${_phoneController.text}',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
        const SizedBox(height: 40),
        
        ThtTextField(
          controller: _otpController,
          label: 'OTP',
          hint: 'Enter 6-digit OTP',
          prefixIcon: Icons.message_outlined,
          keyboardType: TextInputType.number,
        ),
        
        const Spacer(),
        
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ThtButton(
            label: 'Verify OTP',
            isLoading: _isLoading,
            onPressed: _verifyOtp,
            isExpanded: true,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPasswordStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      key: const ValueKey('password'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Set password',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF131D42),
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a strong password for your account',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
        const SizedBox(height: 40),
        
        ThtTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Minimum 8 characters',
          prefixIcon: Icons.lock_outlined,
          obscureText: true,
        ),
        
        const Spacer(),
        
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ThtButton(
            label: 'Create Account',
            isLoading: _isLoading,
            onPressed: _signup,
            isExpanded: true,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Logic functions untouched below ---
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _errorMessage = 'Enter a valid 10-digit phone number');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await ApiClient.instance.post('/api/users/auth/send-otp/', data: {'phone': phone});
      setState(() => _step = 2);
    } on DioException catch (e) {
      setState(() => _errorMessage = e.response?.data?['error'] ?? 'Could not send OTP');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit OTP');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await ApiClient.instance.post('/api/users/auth/verify-otp/', data: {
        'phone': phone,
        'otp': otp,
      });
      setState(() => _step = 3);
    } on DioException catch (e) {
      setState(() => _errorMessage = e.response?.data?['error'] ?? 'Invalid OTP');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiClient.instance.post('/api/users/signup/', data: {
        'username': phone,
        'phone': phone,
        'password': password,
        'role': _selectedRole,
        'first_name': name,
        if (_emailController.text.isNotEmpty) 'email': _emailController.text.trim(),
      });

      final data = response.data;
      if (data['access'] != null && data['refresh'] != null) {
        await ref.read(authProvider.notifier).onLoginSuccess(
          access: data['access'],
          refresh: data['refresh'],
          userData: {
            'username': phone,
            'phone': phone,
            'name': name,
            'role': data['role'] ?? _selectedRole,
          },
        );
      }
    } on DioException catch (e) {
      setState(() => _errorMessage = e.response?.data?['error'] ?? 'Signup failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryOrange.withValues(alpha: 0.15) : AppColors.primaryOrangeLight)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primaryOrange.withValues(alpha: 0.2)
                  : (isDark ? Colors.black.withValues(alpha: 0.2) : AppColors.slate200.withValues(alpha: 0.5)),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange
                : (isDark ? AppColors.darkBorder : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryOrange.withValues(alpha: 0.15)
                    : (isDark ? AppColors.slate800 : AppColors.slate50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryOrange
                    : (isDark ? AppColors.slate400 : AppColors.slate500),
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.primaryOrangeDark
                          : (isDark ? Colors.white : AppColors.slate800),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? (isDark ? AppColors.primaryOrange : AppColors.primaryOrangeDark.withValues(alpha: 0.8))
                          : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primaryOrange, size: 28).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }
}
