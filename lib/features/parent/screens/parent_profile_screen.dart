import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/app_user.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/network/api_config.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/detail_row.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/parent/providers/parent_providers.dart';
import 'package:tht_app/features/parent/widgets/edit_parent_profile_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// The parent's account.
///
/// This screen exists because until now a signed-in parent had nowhere to see
/// their own details and — more pressingly — no way to sign out at all. It also
/// gives the two lists the API has always returned for parents and the app has
/// never shown: teachers they saved, and teachers whose contact they paid for.
class ParentProfileScreen extends ConsumerWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => _confirmSignOut(context, ref),
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AsyncView<AppUser?>(
        value: user,
        onRetry: () => ref.invalidate(currentUserProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              SkeletonBox(height: 110, radius: AppRadius.lg),
              SizedBox(height: AppSpacing.xl),
              SkeletonList(count: 3, itemHeight: 64),
            ],
          ),
        ),
        data: (u) {
          if (u == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Not signed in',
              message: 'Sign in to see your account.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(currentUserProvider)
                ..invalidate(favouriteTutorsProvider)
                ..invalidate(unlockedContactsProvider);
              await ref.read(currentUserProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                _Identity(user: u),
                const SizedBox(height: AppSpacing.xl),
                _Details(user: u),
                const SizedBox(height: AppSpacing.xl),
                const _Saved(),
                const SizedBox(height: AppSpacing.xl),
                const _Unlocked(),
                const SizedBox(height: AppSpacing.xl),
                const _Account(),
              ],
            ),
          );
        },
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

class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return THTCard(
      child: Row(
        children: [
          THTAvatar(
            name: user.displayName,
            imageUrl: user.profilePicture,
            size: 60,
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Fmt.titleCase(user.displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  Fmt.phone(user.phone),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Pill(
                  'Parent',
                  tone: Tone.info,
                  icon: Icons.family_restroom_rounded,
                  dense: true,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => EditParentProfileSheet.show(context, user),
            tooltip: 'Edit your details',
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Details ──────────────────────────────────────────────────────────────────

class _Details extends StatelessWidget {
  const _Details({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    String orNotSet(String? v) =>
        (v ?? '').trim().isEmpty ? 'Not set' : v!.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Your details',
          icon: Icons.person_outline_rounded,
          iconTone: Tone.info,
          actionLabel: 'Edit',
          onAction: () => EditParentProfileSheet.show(context, user),
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              DetailRow(label: 'Phone', value: Fmt.phone(user.phone)),
              const Divider(height: 1),
              DetailRow(label: 'Email', value: orNotSet(user.email)),
              const Divider(height: 1),
              DetailRow(label: 'City', value: orNotSet(user.city)),
              const Divider(height: 1),
              DetailRow(label: 'Area', value: orNotSet(user.area)),
              const Divider(height: 1),
              DetailRow(label: 'Address', value: orNotSet(user.address)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Saved teachers ───────────────────────────────────────────────────────────

/// Teachers the parent has hearted while browsing.
///
/// The endpoint behind this has existed since before the app did and has never
/// had a screen — the heart on a search result had nowhere to lead.
class _Saved extends ConsumerWidget {
  const _Saved();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favouriteTutorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Saved teachers',
          icon: Icons.favorite_border_rounded,
          iconTone: Tone.critical,
          actionLabel: 'Browse',
          onAction: () => context.go('/find-teachers'),
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncView<List<PublicTutor>>(
          value: saved,
          onRetry: () => ref.invalidate(favouriteTutorsProvider),
          loading: const SkeletonList(count: 2, itemHeight: 64),
          compactError: true,
          data: (list) => list.isEmpty
              ? const THTCard(
                  child: EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'Nothing saved yet',
                    message: 'Tap the heart on a teacher to keep them here.',
                    compact: true,
                  ),
                )
              : _TutorList(
                  tutors: list.take(4).toList(),
                  total: list.length,
                  trailing: (t) => IconButton(
                    onPressed: () async {
                      await ref
                          .read(usersRepositoryProvider)
                          .toggleFavourite(t.id);
                      ref.invalidate(favouriteTutorsProvider);
                    },
                    tooltip: 'Remove from saved',
                    icon: Icon(
                      Icons.favorite_rounded,
                      size: 20,
                      color: Tone.critical.foreground(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Unlocked contacts ────────────────────────────────────────────────────────

class _Unlocked extends ConsumerWidget {
  const _Unlocked();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedContactsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Contacts you have unlocked',
          subtitle: 'Teachers you have already spent a credit on.',
          icon: Icons.lock_open_rounded,
          iconTone: Tone.success,
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncView<List<PublicTutor>>(
          value: unlocked,
          onRetry: () => ref.invalidate(unlockedContactsProvider),
          loading: const SkeletonList(count: 2, itemHeight: 64),
          compactError: true,
          data: (list) => list.isEmpty
              ? const THTCard(
                  child: EmptyState(
                    icon: Icons.lock_open_outlined,
                    title: 'No contacts yet',
                    message: 'Unlocked numbers stay here so you never pay '
                        'twice for the same teacher.',
                    compact: true,
                  ),
                )
              : _TutorList(
                  tutors: list.take(4).toList(),
                  total: list.length,
                  trailing: (t) {
                    final phone = t.contact?.phone;
                    if (phone == null || phone.trim().isEmpty) return null;
                    return IconButton(
                      onPressed: () =>
                          launchUrl(Uri.parse('tel:${phone.trim()}')),
                      tooltip: 'Call ${Fmt.titleCase(t.name)}',
                      icon: Icon(
                        Icons.call_rounded,
                        size: 20,
                        color: Tone.success.foreground(
                          Theme.of(context).brightness,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// A short stack of teachers, each a row into their profile.
class _TutorList extends StatelessWidget {
  const _TutorList({
    required this.tutors,
    required this.total,
    required this.trailing,
  });

  final List<PublicTutor> tutors;
  final int total;

  /// Null hides the trailing slot for that row rather than leaving a gap.
  final Widget? Function(PublicTutor) trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hidden = total - tutors.length;

    return THTCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < tutors.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _TutorRow(tutor: tutors[i], trailing: trailing(tutors[i])),
          ],
          if (hidden > 0) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                '+$hidden more',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TutorRow extends StatelessWidget {
  const _TutorRow({required this.tutor, this.trailing});

  final PublicTutor tutor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push('/tutors/${tutor.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            THTAvatar(
              name: tutor.name,
              imageUrl: tutor.imageUrl,
              size: 40,
              verified: tutor.isKycVerified,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Fmt.titleCase(tutor.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tutor.subjects.isEmpty
                        ? 'Teacher'
                        : Fmt.list(tutor.subjects, max: 2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ── Account ──────────────────────────────────────────────────────────────────

/// Notifications lives here as well as behind the bell.
///
/// The bottom bar traded its Alerts tab for this screen, so this is the second
/// way in — a tab was removed, not an entrance.
class _Account extends StatelessWidget {
  const _Account();

  @override
  Widget build(BuildContext context) {
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
              _LinkRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
              const Divider(height: 1),
              // The hero card only offers this while a teacher is assigned;
              // this is the entrance that is always there.
              _LinkRow(
                icon: Icons.person_pin_outlined,
                label: 'Your teacher',
                onTap: () => context.push('/current-tutor'),
              ),
              const Divider(height: 1),
              _LinkRow(
                icon: Icons.forum_outlined,
                label: 'Messages',
                onTap: () => context.push('/messages'),
              ),
              const Divider(height: 1),
              _LinkRow(
                icon: Icons.help_outline_rounded,
                label: 'Help and support',
                onTap: () => context.push('/support'),
              ),
              const Divider(height: 1),
              _LinkRow(
                icon: Icons.lock_outline_rounded,
                label: 'Sign-in and security',
                onTap: () => context.push('/account-security'),
              ),
              const Divider(height: 1),
              _LinkRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Credits and plans',
                onTap: () => context.go('/wallet'),
              ),
              const Divider(height: 1),
              _LinkRow(
                icon: Icons.description_outlined,
                label: 'Terms of service',
                external: true,
                onTap: () => open('/terms'),
              ),
              const Divider(height: 1),
              _LinkRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy policy',
                external: true,
                // The site serves this at /privacy-policy; /privacy is a 404.
                onTap: () => open('/privacy-policy'),
              ),
              const Divider(height: 1),
              _LinkRow(
                icon: Icons.receipt_long_outlined,
                label: 'Refund policy',
                external: true,
                onTap: () => open('/refund-policy'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.external = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Leaves the app — say so with the icon rather than a surprise.
  final bool external;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Row(
          children: [
            Icon(icon, size: 19, color: muted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              external
                  ? Icons.open_in_new_rounded
                  : Icons.chevron_right_rounded,
              size: external ? 16 : 20,
              color: muted,
            ),
          ],
        ),
      ),
    );
  }
}
