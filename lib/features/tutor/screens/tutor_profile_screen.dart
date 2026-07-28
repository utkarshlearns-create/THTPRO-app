import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/network/api_config.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/tutor/providers/tutor_dashboard_provider.dart';
import 'package:tht_app/features/tutor/widgets/edit_profile_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// The teacher's profile — what families see, and how complete it is.
///
/// The fields worth changing from a phone are editable here. The education
/// timeline (three levels, each with university, year, marks and CGPA
/// validation) is shown read-only with a link to the website: it is filled in
/// once, and a form that long is worse on a phone than on a laptop.
class TutorProfileScreen extends ConsumerWidget {
  const TutorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(tutorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: AsyncView<TutorProfile>(
        value: profile,
        onRetry: () => ref.invalidate(tutorProfileProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              SkeletonBox(height: 120, radius: AppRadius.lg),
              SizedBox(height: AppSpacing.lg),
              SkeletonList(count: 3, itemHeight: 80),
            ],
          ),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tutorProfileProvider);
            await ref.read(tutorProfileProvider.future);
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
              const SizedBox(height: AppSpacing.base),
              _Completeness(profile: p),
              const SizedBox(height: AppSpacing.xl),
              _Teaching(profile: p),
              const SizedBox(height: AppSpacing.xl),
              _Reach(profile: p),
              const SizedBox(height: AppSpacing.xl),
              _Preferences(profile: p),
              const SizedBox(height: AppSpacing.xl),
              _Qualifications(profile: p),
              const SizedBox(height: AppSpacing.xl),
              const _Verification(),
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
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

// ── Identity ─────────────────────────────────────────────────────────────────

class _Identity extends ConsumerWidget {
  const _Identity({required this.profile});

  final TutorProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final name = profile.fullName.trim().isNotEmpty
        ? profile.fullName
        : (user?.displayName ?? '');

    return THTCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          THTAvatar(
            name: name,
            imageUrl: profile.imageUrl,
            size: 60,
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Fmt.titleCase(name),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                if (user?.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    Fmt.phone(user!.phone),
                    style: TextStyle(
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
                if (profile.aboutMe.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    profile.aboutMe.trim(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? AppColors.slate300 : AppColors.slate600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => EditProfileSheet.show(context, profile, ProfileSection.about),
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: 'Edit your details',
          ),
        ],
      ),
    );
  }
}

// ── Completeness ─────────────────────────────────────────────────────────────

class _Completeness extends StatelessWidget {
  const _Completeness({required this.profile});

  final TutorProfile profile;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final pct = profile.completionPercentage.clamp(0, 100);
    final weak = profile.weakestSpot;
    final tone = profile.isWellFilled ? Tone.success : Tone.warning;

    return THTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profile strength',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate100 : AppColors.slate800,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: tone.foreground(brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 7,
              backgroundColor: isDark ? AppColors.slate800 : AppColors.slate200,
              valueColor: AlwaysStoppedAnimation(tone.foreground(brightness)),
            ),
          ),
          if (weak != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              weak,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: isDark ? AppColors.slate400 : AppColors.slate500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Teaching ─────────────────────────────────────────────────────────────────

class _Teaching extends StatelessWidget {
  const _Teaching({required this.profile});

  final TutorProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Teaching',
          actionLabel: 'Edit',
          onAction: () =>
              EditProfileSheet.show(context, profile, ProfileSection.teaching),
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _Row(
                label: 'Experience',
                value: profile.experienceYears == 0
                    ? 'Not set'
                    : Fmt.plural(profile.experienceYears, 'year'),
              ),
              const Divider(height: 1),
              _Row(
                label: 'Expected fee',
                value: profile.expectedFee == null || profile.expectedFee == 0
                    ? 'Not set'
                    : '${Fmt.rupees(profile.expectedFee)} / month',
              ),
              const Divider(height: 1),
              _Row(
                label: 'Teaching mode',
                value: _mode(profile.teachingMode),
              ),
              const Divider(height: 1),
              _Chips(
                label: 'Subjects',
                values: profile.subjects,
                emptyHint: 'Set on the website',
              ),
              const Divider(height: 1),
              _Chips(
                label: 'Classes',
                values: profile.classes,
                emptyHint: 'Set on the website',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _mode(String raw) {
    switch (raw.toUpperCase()) {
      case 'HOME':
        return 'At the student’s home';
      case 'ONLINE':
        return 'Online';
      case 'BOTH':
        return 'Home or online';
      default:
        return raw.isEmpty ? 'Not set' : raw;
    }
  }
}

// ── Reach ────────────────────────────────────────────────────────────────────

class _Reach extends StatelessWidget {
  const _Reach({required this.profile});

  final TutorProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Where you teach',
          actionLabel: 'Edit',
          onAction: () =>
              EditProfileSheet.show(context, profile, ProfileSection.location),
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _Row(
                label: 'Base',
                value: [profile.locality, profile.city, profile.state]
                        .where((s) => s.trim().isNotEmpty)
                        .join(', ')
                        .ifEmpty('Not set'),
              ),
              const Divider(height: 1),
              _Row(
                label: 'Pincode',
                value: profile.pincode.ifEmpty('Not set'),
              ),
              const Divider(height: 1),
              _Chips(
                label: 'Areas you cover',
                values: profile.preferredLocations,
                emptyHint: 'Add areas so nearby leads reach you',
              ),
              const Divider(height: 1),
              _Chips(
                label: 'Boards',
                values: profile.preferredBoards,
                emptyHint: 'Any board',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Preferences ──────────────────────────────────────────────────────────────

class _Preferences extends ConsumerStatefulWidget {
  const _Preferences({required this.profile});

  final TutorProfile profile;

  @override
  ConsumerState<_Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends ConsumerState<_Preferences> {
  String? _saving;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Preferences'),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _Toggle(
                title: 'Open to institute jobs',
                subtitle: 'Coaching centres and schools can also reach you.',
                value: p.openToInstituteJobs,
                busy: _saving == 'open_to_institute_jobs',
                onChanged: (v) => _save('open_to_institute_jobs', v),
              ),
              const Divider(height: 1),
              _Toggle(
                title: 'Let counsellors share my number',
                subtitle:
                    'Parents can be given your number directly instead of '
                    'going through a counsellor first.',
                value: p.allowDirectContactUnlock,
                busy: _saving == 'allow_direct_contact_unlock',
                onChanged: (v) => _save('allow_direct_contact_unlock', v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save(String field, bool value) async {
    setState(() => _saving = field);
    try {
      await ref.read(usersRepositoryProvider).updateTutorProfile({field: value});
      ref.invalidate(tutorProfileProvider);
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }
}

// ── Qualifications (read-only) ───────────────────────────────────────────────

class _Qualifications extends StatelessWidget {
  const _Qualifications({required this.profile});

  final TutorProfile profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final certifications = <String>[
      if (profile.raw['is_bed'] == true) 'B.Ed',
      if (profile.raw['is_btc'] == true) 'BTC',
      if (profile.raw['is_tet'] == true) 'TET',
      if (profile.raw['is_ctet'] == true) 'CTET',
      if (profile.raw['is_net'] == true) 'NET',
      if (profile.raw['is_mphil'] == true) 'M.Phil',
      if (profile.raw['is_phd'] == true) 'PhD',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Qualifications',
          subtitle: 'Your education record is edited on the website',
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.highestQualification.trim().isEmpty
                    ? 'No qualification recorded'
                    : profile.highestQualification,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.slate100 : AppColors.slate800,
                ),
              ),
              if (certifications.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final c in certifications)
                      Pill(c, tone: Tone.info, dense: true),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.base),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('${ApiConfig.siteUrl}/tutor'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('Edit education on the website'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Verification shortcut ────────────────────────────────────────────────────

class _Verification extends ConsumerWidget {
  const _Verification();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kyc = ref.watch(kycStatusProvider).valueOrNull;
    if (kyc == null) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    final tone = kyc.isVerified
        ? Tone.success
        : kyc.isRejected
            ? Tone.critical
            : Tone.warning;

    return THTCard(
      onTap: () => context.go('/tutor-kyc'),
      child: Row(
        children: [
          Icon(
            kyc.isVerified ? Icons.verified_rounded : Icons.badge_outlined,
            size: 20,
            color: tone.foreground(brightness),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kyc.shortLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tone.foreground(brightness),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kyc.isVerified
                      ? 'Families see an ID-verified badge on your profile.'
                      : 'Tap to manage your documents.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.slate400
                        : AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

// ── Small shared rows ────────────────────────────────────────────────────────

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

class _Chips extends StatelessWidget {
  const _Chips({
    required this.label,
    required this.values,
    required this.emptyHint,
  });

  final String label;
  final List<String> values;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (values.isEmpty)
            Text(
              emptyHint,
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.slate500 : AppColors.slate400,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final v in values) Pill(v, dense: true)],
            ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: busy ? null : onChanged,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.slate400
                : AppColors.slate500,
          ),
        ),
      ),
    );
  }
}

extension _Fallback on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
