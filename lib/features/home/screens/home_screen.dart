import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/network/api_config.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:url_launcher/url_launcher.dart';

/// The public landing screen.
///
/// Someone here has not signed in and may not have decided to, so it stays
/// short: one line on what this is, a way to look around without an account,
/// and three ways to say who you are. Deliberately no content feed — browsing
/// belongs on the screen built for browsing, and a landing page is judged by
/// how quickly it gets out of the way.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TopBar(),
                    const SizedBox(height: AppSpacing.xl),
                    const _Hero(),
                    const SizedBox(height: AppSpacing.xl),
                    const _GuestActions(),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'What brings you here?',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    const _RolePaths(),
                    const SizedBox(height: AppSpacing.xl),
                    const _TrustLine(),
                    const SizedBox(height: AppSpacing.sm),
                    const _Legal(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 34,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'The Home Tuitions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => context.push('/login'),
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.18,
              letterSpacing: -1,
              color: isDark ? AppColors.slate50 : AppColors.slate900,
            ),
            children: const [
              TextSpan(text: 'The right teacher,\n'),
              TextSpan(
                text: 'at your door.',
                style: TextStyle(color: AppColors.primaryOrange),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Home tuitions across Lucknow and beyond — ID-checked teachers, '
          'matched to your child’s class and board.',
          style: TextStyle(
            fontSize: 14.5,
            height: 1.55,
            color: isDark ? AppColors.slate300 : AppColors.slate600,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}

// ── Look before you sign up ──────────────────────────────────────────────────

class _GuestActions extends StatelessWidget {
  const _GuestActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push('/explore'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
            ),
            icon: const Icon(Icons.search_rounded, size: 19),
            label: const Text('Browse teachers'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/find-jobs'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
            ),
            icon: const Icon(Icons.work_outline_rounded, size: 19),
            label: const Text('Tuition jobs'),
          ),
        ),
      ],
    ).animate(delay: 80.ms).fadeIn(duration: 400.ms);
  }
}

// ── Three ways in ────────────────────────────────────────────────────────────

class _RolePaths extends StatelessWidget {
  const _RolePaths();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _RoleCard(
          icon: Icons.family_restroom_rounded,
          tone: Tone.accent,
          title: 'I need a teacher',
          subtitle: 'Post what your child needs, or pick someone yourself.',
          role: 'PARENT',
        ),
        SizedBox(height: AppSpacing.md),
        _RoleCard(
          icon: Icons.school_rounded,
          tone: Tone.info,
          title: 'I teach',
          subtitle: 'Find tuitions near you and grow a steady income.',
          role: 'TEACHER',
        ),
        SizedBox(height: AppSpacing.md),
        // The institute journey is fully built — dashboard, vacancies, teacher
        // directory — and had no entry point on this screen at all.
        _RoleCard(
          icon: Icons.apartment_rounded,
          tone: Tone.success,
          title: 'I run a school or institute',
          subtitle: 'Hire qualified teachers for your centre.',
          role: 'INSTITUTION',
        ),
      ],
    ).animate(delay: 220.ms).fadeIn(duration: 400.ms);
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    // ignore: unused_element_parameter
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.role,
  });

  final IconData icon;
  final Tone tone;
  final String title;
  final String subtitle;

  /// Carried into signup so the role step opens on the choice just made.
  final String role;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return THTCard(
      onTap: () => context.push('/signup?role=$role'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: tone.background(brightness),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 22, color: tone.foreground(brightness)),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.arrow_forward_rounded,
            size: 19,
            color: isDark ? AppColors.slate400 : AppColors.slate400,
          ),
        ],
      ),
    );
  }
}

/// without an account, and this is the only screen everyone passes through.
/// One quiet line of reassurance.
///
/// Not "100% verified tutors": the app carries a per-teacher is_kyc_verified
/// flag and a verified-only filter in search, so a blanket claim is
/// contradicted two taps later. This says only what is true of every teacher.
class _TrustLine extends StatelessWidget {
  const _TrustLine();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 15,
          color: Tone.success.foreground(brightness),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Teachers are ID-checked by our team',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
        ),
      ],
    );
  }
}

class _Legal extends StatelessWidget {
  const _Legal();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = TextStyle(
      fontSize: 11.5,
      color: isDark ? AppColors.slate400 : AppColors.slate500,
    );

    Future<void> open(String path) => launchUrl(
          Uri.parse('${ApiConfig.siteUrl}$path'),
          mode: LaunchMode.externalApplication,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => open('/terms'),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Terms', style: style),
        ),
        Text('·', style: style),
        TextButton(
          onPressed: () => open('/privacy-policy'),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Privacy', style: style),
        ),
        Text('·', style: style),
        TextButton(
          onPressed: () => open('/refund-policy'),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Refunds', style: style),
        ),
      ],
    );
  }
}
