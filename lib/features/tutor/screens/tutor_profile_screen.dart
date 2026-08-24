import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tht_app/core/models/tutor_profile.dart';
import 'package:tht_app/core/models/upload_file.dart';
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
import 'package:tht_app/features/tutor/widgets/class_subjects_sheet.dart';
import 'package:tht_app/features/tutor/widgets/edit_profile_sheet.dart';
import 'package:tht_app/features/tutor/widgets/reach_sheet.dart';
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
              const SizedBox(height: AppSpacing.base),
              _IntroVideo(profile: p),
              const SizedBox(height: AppSpacing.xl),
              _Reach(profile: p),
              const SizedBox(height: AppSpacing.xl),
              _Preferences(profile: p),
              const SizedBox(height: AppSpacing.xl),
              _Qualifications(profile: p),
              const SizedBox(height: AppSpacing.xl),
              const _Verification(),
              const SizedBox(height: AppSpacing.xl),
              _Account(profile: p),
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

class _Identity extends ConsumerStatefulWidget {
  const _Identity({required this.profile});

  final TutorProfile profile;

  @override
  ConsumerState<_Identity> createState() => _IdentityState();
}

class _IdentityState extends ConsumerState<_Identity> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final name = profile.fullName.trim().isNotEmpty
        ? profile.fullName
        : (user?.displayName ?? '');

    return THTCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A photo is the first thing a family looks at, so it is editable
          // where it is shown rather than behind the details sheet.
          Stack(
            children: [
              THTAvatar(
                name: name,
                imageUrl: profile.imageUrl,
                size: 60,
                onTap: _uploading ? null : _pickPhoto,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: _uploading
                      ? const SizedBox(
                          width: 11,
                          height: 11,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.photo_camera_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
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
            onPressed: () =>
                EditProfileSheet.show(context, profile, ProfileSection.about),
            icon: const Icon(Icons.edit_outlined, size: 19),
            tooltip: 'Edit your details',
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        // A profile photo is displayed at 60–120px; a full-resolution phone
        // photo is megabytes of upload for no visible gain.
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploading = true);
      await ref.read(usersRepositoryProvider).updateProfilePhoto(
            UploadFile(
              bytes: await picked.readAsBytes(),
              filename: picked.name,
            ),
          );
      if (!mounted) return;
      ref.invalidate(tutorProfileProvider);
      context.showMessage('Photo updated.');
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
          icon: Icons.menu_book_rounded,
          iconTone: Tone.accent,
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ClassSubjects(profile: profile),
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

/// The class-by-class breakdown, and the way into editing it.
///
/// Its own card rather than two rows of chips: this is the field every match
/// runs on, and the pairing matters — "Class 10 · Maths, Science" says
/// something that two separate lists of classes and subjects do not.
class _ClassSubjects extends StatelessWidget {
  const _ClassSubjects({required this.profile});

  final TutorProfile profile;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final map = profile.classSubjects;

    return THTCard(
      onTap: () => ClassSubjectsSheet.show(context, profile),
      borderColor: map.isEmpty ? Tone.warning.border(brightness) : null,
      background: map.isEmpty ? Tone.warning.background(brightness) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Classes and subjects',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: map.isEmpty
                        ? Tone.warning.foreground(brightness)
                        : (isDark ? AppColors.slate100 : AppColors.slate800),
                  ),
                ),
              ),
              Icon(Icons.edit_outlined, size: 17, color: muted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (map.isEmpty)
            Text(
              'Not set yet — no job can match you until you add at least one '
              'class and its subjects.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Tone.warning.foreground(brightness),
              ),
            )
          else
            for (final entry in map.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                      color: isDark ? AppColors.slate200 : AppColors.slate700,
                    ),
                    children: [
                      TextSpan(
                        text: '${entry.key}  ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: entry.value.isEmpty
                            ? 'no subjects yet'
                            : entry.value.join(', '),
                        style: entry.value.isEmpty
                            ? TextStyle(
                                color: muted, fontStyle: FontStyle.italic)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// A short clip families watch before choosing.
///
/// No video player is bundled, so an existing clip opens in the device's own
/// player rather than half-working inline.
class _IntroVideo extends ConsumerStatefulWidget {
  const _IntroVideo({required this.profile});

  final TutorProfile profile;

  @override
  ConsumerState<_IntroVideo> createState() => _IntroVideoState();
}

class _IntroVideoState extends ConsumerState<_IntroVideo> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final url = widget.profile.introVideoUrl;
    final has = url != null && url.trim().isNotEmpty;

    return THTCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: (has ? Tone.success : Tone.neutral).background(brightness),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              has ? Icons.play_arrow_rounded : Icons.videocam_outlined,
              size: 20,
              color: (has ? Tone.success : Tone.neutral).foreground(brightness),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Intro video',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate100 : AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  has
                      ? 'Families can watch this on your profile.'
                      : 'A short clip introducing yourself helps families '
                          'choose you.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (_uploading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            if (has)
              IconButton(
                onPressed: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                tooltip: 'Watch',
              ),
            TextButton(
              onPressed: _pick,
              child: Text(has ? 'Replace' : 'Add'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Record a video'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picked = await ImagePicker().pickVideo(
        source: source,
        // The website caps uploads at 50 MB and nothing enforces that here, so
        // the length is capped instead — a minute is more than enough for an
        // introduction and keeps the file inside that budget.
        maxDuration: const Duration(minutes: 1),
      );
      if (picked == null || !mounted) return;

      setState(() => _uploading = true);
      await ref.read(usersRepositoryProvider).updateIntroVideo(
            UploadFile(
              bytes: await picked.readAsBytes(),
              filename: picked.name,
            ),
          );
      if (!mounted) return;
      ref.invalidate(tutorProfileProvider);
      context.showMessage('Intro video updated.');
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _uploading = false);
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
          icon: Icons.place_rounded,
          iconTone: Tone.info,
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
                onTap: () => ReachSheet.show(
                  context,
                  profile,
                  ReachField.locations,
                ),
              ),
              const Divider(height: 1),
              _Chips(
                label: 'Boards',
                values: profile.preferredBoards,
                emptyHint: 'Any board',
                onTap: () =>
                    ReachSheet.show(context, profile, ReachField.boards),
              ),
              const Divider(height: 1),
              _Chips(
                label: 'When you are free',
                values: profile.availableTimeSlots,
                emptyHint: 'Add your hours to be matched on timing',
                onTap: () =>
                    ReachSheet.show(context, profile, ReachField.timeSlots),
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
        const SectionHeader(
          'Preferences',
          icon: Icons.tune_rounded,
          iconTone: Tone.neutral,
        ),
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
      await ref
          .read(usersRepositoryProvider)
          .updateTutorProfile({field: value});
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
          icon: Icons.school_rounded,
          iconTone: Tone.success,
          subtitle: 'Degrees, marks and teaching certifications',
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/tutor-education'),
                  icon: const Icon(Icons.school_outlined, size: 17),
                  label: const Text('Edit your education'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Account ──────────────────────────────────────────────────────────────────

/// The things that belong to the account rather than the teaching profile.
///
/// Attendance history sits here as a second entrance — its first is the icon on
/// My tuitions, where a teacher goes between sessions.
class _Account extends StatelessWidget {
  const _Account({required this.profile});

  final TutorProfile profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> open(String path) => launchUrl(
          Uri.parse('${ApiConfig.siteUrl}$path'),
          mode: LaunchMode.externalApplication,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Account',
          icon: Icons.settings_outlined,
          iconTone: Tone.neutral,
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // What families actually see. A teacher tuning their profile
              // has no other way to check the result.
              _AccountRow(
                icon: Icons.visibility_outlined,
                label: 'Preview my public profile',
                onTap: () => context.push('/tutors/${profile.id}'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _AccountRow(
                icon: Icons.forum_outlined,
                label: 'Messages',
                onTap: () => context.push('/messages'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _AccountRow(
                icon: Icons.card_giftcard_outlined,
                label: 'Refer and earn',
                onTap: () => context.push('/tutor-referrals'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _AccountRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Your score and rank',
                onTap: () => context.push('/tutor-score'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _AccountRow(
                icon: Icons.event_note_outlined,
                label: 'Attendance history',
                onTap: () => context.push('/tutor-attendance'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _AccountRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => context.go('/tutor-notifications'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _AccountRow(
                icon: Icons.help_outline_rounded,
                label: 'Help and support',
                onTap: () => context.push('/support'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _AccountRow(
                icon: Icons.lock_outline_rounded,
                label: 'Sign-in and security',
                onTap: () => context.push('/account-security'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _AccountRow(
                icon: Icons.description_outlined,
                label: 'Terms of service',
                external: true,
                onTap: () => open('/terms'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _AccountRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy policy',
                external: true,
                // The site serves this at /privacy-policy; /privacy is a 404.
                onTap: () => open('/privacy-policy'),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.external = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool external;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.base,
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: muted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.slate100 : AppColors.slate800,
                ),
              ),
            ),
            Icon(
              external
                  ? Icons.open_in_new_rounded
                  : Icons.chevron_right_rounded,
              size: external ? 15 : 20,
              color: muted,
            ),
          ],
        ),
      ),
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
    this.onTap,
  });

  final String label;
  final List<String> values;
  final String emptyHint;

  /// Makes the whole row an entrance to editing this list.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.edit_outlined, size: 15, color: muted),
              ],
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
