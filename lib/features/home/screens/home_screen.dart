import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/network/api_config.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/explore/providers/tutor_search_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// The public landing screen.
///
/// Someone here has not signed in, and may not have decided to. So it does two
/// things in order: let them look at real teachers without an account, and then
/// let them say which of the three things they are. Everything used to funnel
/// into /signup, including the "Find a Tutor" button — which asked for a phone
/// number before showing a single teacher.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    const _FeaturedTutors(),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'GET STARTED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'What brings you here?',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    const _RolePaths(),
                    const SizedBox(height: AppSpacing.xxl),
                    const _TrustRow(),
                    const SizedBox(height: AppSpacing.lg),
                    const _Legal(),
                    const SizedBox(height: AppSpacing.xxl),
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

// ── Real teachers, not an illustration ───────────────────────────────────────

class _FeaturedTutors extends ConsumerWidget {
  const _FeaturedTutors();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredTutorsProvider);

    return featured.when(
      // A landing screen must not show an error box to someone who has not even
      // signed in yet — if this cannot load, the section simply is not there.
      error: (_, __) => const SizedBox.shrink(),
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader('Teachers on the platform'),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(height: 132, radius: AppRadius.lg),
        ],
      ),
      data: (tutors) {
        if (tutors.isEmpty) return const SizedBox.shrink();
        final shown = tutors.take(8).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              'Teachers on the platform',
              icon: Icons.groups_rounded,
              iconTone: Tone.accent,
              actionLabel: 'See all',
              onAction: () => context.push('/explore'),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: shown.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (_, i) => _TutorPreview(tutor: shown[i]),
              ),
            ),
          ],
        ).animate(delay: 160.ms).fadeIn(duration: 400.ms);
      },
    );
  }
}

class _TutorPreview extends StatelessWidget {
  const _TutorPreview({required this.tutor});

  final PublicTutor tutor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return SizedBox(
      width: 168,
      child: THTCard(
        onTap: () => context.push('/tutors/${tutor.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            THTAvatar(
              name: tutor.name,
              imageUrl: tutor.imageUrl,
              size: 44,
              verified: tutor.isKycVerified,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              Fmt.titleCase(tutor.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate50 : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tutor.subjects.isEmpty
                  ? 'Teacher'
                  : Fmt.list(tutor.subjects, max: 2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, height: 1.35, color: muted),
            ),
            const Spacer(),
            if (tutor.hasRatings)
              Pill(
                tutor.avgRating!.toStringAsFixed(1),
                tone: Tone.success,
                icon: Icons.star_rounded,
                dense: true,
              )
            else if (tutor.experienceYears > 0)
              Pill(
                '${Fmt.plural(tutor.experienceYears, 'yr')} exp',
                dense: true,
              ),
          ],
        ),
      ),
    );
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

// ── Trust ────────────────────────────────────────────────────────────────────

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Deliberately not "100% verified tutors": the app has a per-teacher
    // is_kyc_verified flag and an explicit verified-only filter, so a blanket
    // claim is contradicted two taps later. This says what is actually true.
    const points = [
      (Icons.verified_user_outlined, 'ID-checked teachers, reviewed by our team'),
      (Icons.rate_review_outlined, 'Ratings come from parents who actually hired'),
      (Icons.support_agent_outlined, 'A real counsellor helps you through it'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.slate50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          for (var i = 0; i < points.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  points[i].$1,
                  size: 17,
                  color: Tone.success.foreground(brightness),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    points[i].$2,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: isDark ? AppColors.slate300 : AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Terms and privacy. Play and the App Store both require these to be reachable
/// without an account, and this is the only screen everyone passes through.
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
