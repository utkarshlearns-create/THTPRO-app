import 'package:tht_app/core/ui/tht_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/detail_row.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/api_error.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/explore/providers/tutor_search_provider.dart';
import 'package:tht_app/features/wallet/providers/wallet_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// A teacher's full profile, and the decision to contact them.
class TutorDetailScreen extends ConsumerWidget {
  const TutorDetailScreen({super.key, required this.tutorId});

  final int tutorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutor = ref.watch(tutorProvider(tutorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher'),
        actions: [
          tutor.maybeWhen(
            data: (t) => IconButton(
              onPressed: () => _toggleFavourite(context, ref),
              tooltip:
                  t.isFavourite ? 'Remove from saved' : 'Save this teacher',
              icon: Icon(
                t.isFavourite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: t.isFavourite ? AppColors.rose : null,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncView<PublicTutor>(
        value: tutor,
        onRetry: () => ref.invalidate(tutorProvider(tutorId)),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 140),
        ),
        data: (t) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tutorProvider(tutorId));
            await ref.read(tutorProvider(tutorId).future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
            children: [
              // Full-bleed: the cover band runs edge to edge, so this one
              // section brings no page padding of its own.
              _Header(tutor: t),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    _ContactCard(tutor: t),
                    if (t.introVideoUrl != null &&
                        t.introVideoUrl!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _IntroVideo(url: t.introVideoUrl!.trim()),
                    ],
                    if (t.aboutMe.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const SectionHeader('About'),
                      const SizedBox(height: AppSpacing.md),
                      THTCard(
                        child: Text(
                          t.aboutMe.trim(),
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _Teaches(tutor: t),
                    if (t.availableTimeSlots.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _Schedule(tutor: t),
                    ],
                    if (t.preferredLocations.isNotEmpty ||
                        t.preferredBoards.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _Coverage(tutor: t),
                    ],
                    if (t.hasRatings) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _Ratings(tutor: t),
                    ],
                    if (t.reviews.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _Reviews(tutor: t),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavourite(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(usersRepositoryProvider).toggleFavourite(tutorId);
      ref.invalidate(tutorProvider(tutorId));
    } catch (e) {
      if (context.mounted) context.showFailure(e);
    }
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

/// A cover band with the portrait breaking out of its lower edge.
///
/// The headline beneath the name is [PublicTutor.credentialLine] — the getter
/// already existed for the search card and says the one thing a parent wants
/// first: how long they have taught, what they hold, and where they are.
class _Header extends StatelessWidget {
  const _Header({required this.tutor});

  final PublicTutor tutor;

  static const double _bandHeight = 116;
  static const double _avatarSize = 88;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final primary = Theme.of(context).colorScheme.primary;
    final credentials = tutor.credentialLine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explicit height, and the avatar is a fully-constrained Positioned —
        // no intrinsic pass, so this cannot become the unbounded-height crash.
        SizedBox(
          height: _bandHeight + _avatarSize / 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _bandHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary,
                        Color.lerp(primary, Colors.black, 0.25)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                bottom: 0,
                width: _avatarSize,
                height: _avatarSize,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: THTAvatar(
                    name: tutor.name,
                    imageUrl: tutor.imageUrl,
                    size: _avatarSize - 6,
                    verified: tutor.isKycVerified,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tutor.name.trim().isEmpty
                    ? 'Teacher'
                    : Fmt.titleCase(tutor.name),
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
              if (credentials.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  credentials,
                  style: TextStyle(fontSize: 13.5, height: 1.45, color: muted),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (tutor.isKycVerified)
                    const Pill(
                      'ID verified',
                      tone: Tone.info,
                      icon: Icons.verified_rounded,
                      dense: true,
                    ),
                  if (tutor.hasRatings)
                    Pill(
                      '${tutor.avgRating!.toStringAsFixed(1)} '
                      '(${Fmt.number(tutor.ratingCount)})',
                      tone: Tone.success,
                      icon: Icons.star_rounded,
                      dense: true,
                    ),
                  // Teaching qualifications, on the model since it was written
                  // and never shown on this screen until now.
                  if (tutor.isBed)
                    const Pill('B.Ed', tone: Tone.info, dense: true),
                  if (tutor.isTet)
                    const Pill('TET qualified', tone: Tone.info, dense: true),
                  if (tutor.memberSince != null)
                    Pill('On THT since ${tutor.memberSince!.year}',
                        dense: true),
                ],
              ),
              if (tutor.ongoingTuitions > 0 || tutor.scheduledDemos > 0) ...[
                const SizedBox(height: AppSpacing.md),
                _ActivityLine(tutor: tutor, muted: muted),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// How busy this teacher is.
///
/// Only drawn when there is something to report — a row of zeroes on a teacher
/// who has just joined reads as a warning rather than as a blank slate.
class _ActivityLine extends StatelessWidget {
  const _ActivityLine({required this.tutor, required this.muted});

  final PublicTutor tutor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (tutor.ongoingTuitions > 0)
        '${Fmt.plural(tutor.ongoingTuitions, 'tuition')} running',
      if (tutor.scheduledDemos > 0)
        '${Fmt.plural(tutor.scheduledDemos, 'demo')} scheduled',
    ];

    return Row(
      children: [
        Icon(Icons.insights_rounded, size: 14, color: muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: TextStyle(fontSize: 12.5, color: muted),
          ),
        ),
      ],
    );
  }
}

// ── Intro video ──────────────────────────────────────────────────────────────

/// The teacher's introduction, opened externally.
///
/// There is no video player in this app's dependencies, and adding one to play
/// a clip most teachers have not uploaded is not the trade. The card makes the
/// hand-off obvious rather than pretending to be a player.
class _IntroVideo extends StatelessWidget {
  const _IntroVideo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Introduction',
          icon: Icons.play_circle_outline_rounded,
          iconTone: Tone.info,
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          onTap: () => launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: 0.14),
                    primary.withValues(alpha: 0.28),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Watch their introduction',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Schedule ─────────────────────────────────────────────────────────────────

/// When they are free. Was buried as one row inside "What they teach", where a
/// parent working out whether the times suit them had to hunt for it.
class _Schedule extends StatelessWidget {
  const _Schedule({required this.tutor});

  final PublicTutor tutor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'When they are free',
          icon: Icons.schedule_rounded,
          iconTone: Tone.warning,
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final slot in tutor.availableTimeSlots)
                Pill(slot, tone: Tone.warning, dense: true),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Coverage ─────────────────────────────────────────────────────────────────

/// Where they will travel and which boards they know.
///
/// Boards are shown here as information about the teacher. Note the search has
/// no board filter — this is a fact on a profile, not a facet.
class _Coverage extends StatelessWidget {
  const _Coverage({required this.tutor});

  final PublicTutor tutor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Reach',
          icon: Icons.travel_explore_rounded,
          iconTone: Tone.success,
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tutor.preferredLocations.isNotEmpty)
                DetailChips(
                  label: 'Also travels to',
                  values: tutor.preferredLocations,
                  emptyHint: 'Not listed',
                ),
              if (tutor.preferredLocations.isNotEmpty &&
                  tutor.preferredBoards.isNotEmpty)
                const Divider(height: 1),
              if (tutor.preferredBoards.isNotEmpty)
                DetailChips(
                  label: 'Boards they teach',
                  values: tutor.preferredBoards,
                  emptyHint: 'Not listed',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Contact / unlock ─────────────────────────────────────────────────────────

class _ContactCard extends ConsumerStatefulWidget {
  const _ContactCard({required this.tutor});

  final PublicTutor tutor;

  @override
  ConsumerState<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends ConsumerState<_ContactCard> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tutor;
    return t.isUnlocked && t.contact != null && !t.contact!.isEmpty
        ? _unlocked()
        : _locked();
  }

  Widget _unlocked() {
    final brightness = Theme.of(context).brightness;
    final contact = widget.tutor.contact!;
    final phone = contact.phone;
    final whatsapp = contact.whatsapp ?? phone;

    return THTCard(
      background: Tone.success.background(brightness),
      borderColor: Tone.success.border(brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_open_rounded,
                size: 18,
                color: Tone.success.foreground(brightness),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Contact unlocked',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Tone.success.foreground(brightness),
                ),
              ),
            ],
          ),
          if (phone != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              Fmt.phone(phone),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              if (phone != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _open('tel:$phone', 'phone app'),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call'),
                  ),
                ),
              if (phone != null && whatsapp != null)
                const SizedBox(width: AppSpacing.sm),
              if (whatsapp != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _open('https://wa.me/${_intl(whatsapp)}', 'WhatsApp'),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Unlocking is back on this side.
  ///
  /// Both directions of contact now exist and they are not the same product:
  /// a teacher buys a *family's* number on a job, and a parent spends a credit
  /// here for a *teacher's* number. Neither replaces the other, so this card
  /// keeps offering "post a requirement" underneath as the free route.
  ///
  /// The teacher's opt-out is invisible to us — `allow_direct_contact_unlock`
  /// is not on the public profile — so the button is always offered and the
  /// 403 is caught and explained rather than thrown at the parent as an error.
  Widget _locked() {
    final signedIn = ref.watch(authProvider).isAuthenticated;
    final brightness = Theme.of(context).brightness;
    final wallet = signedIn ? ref.watch(walletProvider).valueOrNull : null;
    final hasCredits = (wallet?.balance ?? 0) > 0;

    return THTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            // Top-aligned: the heading wraps to three lines at large text
            // scales, and a vertically centred icon floats away from it.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Tone.info.foreground(brightness),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Expanded, not bare: the heading has to wrap at large text
              // scales rather than run off the side of the card.
              Expanded(
                child: Text(
                  'Contact details are hidden',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Tone.info.foreground(brightness),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            signedIn
                ? 'Unlock to see this teacher’s phone and WhatsApp number. '
                    'One credit is used, and the contact stays unlocked for you.'
                : 'Sign in to see this teacher’s phone and WhatsApp number.',
            style: const TextStyle(fontSize: 13.5, height: 1.55),
          ),
          if (wallet != null) ...[
            const SizedBox(height: AppSpacing.base),
            Pill(
              '${Fmt.number(wallet.balance)} credits in your wallet',
              tone: hasCredits ? Tone.neutral : Tone.critical,
              icon: Icons.account_balance_wallet_outlined,
              dense: true,
            ),
          ],
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: !signedIn
                ? FilledButton.icon(
                    onPressed: () => context.push('/login'),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Sign in to unlock'),
                  )
                : hasCredits
                    ? FilledButton.icon(
                        onPressed: _working ? null : _unlock,
                        icon: _working
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.lock_open_rounded, size: 18),
                        label: Text(
                          _working ? 'Unlocking…' : 'Unlock contact (1 credit)',
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: () => context.push('/packages'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add credits to unlock'),
                      ),
          ),

          // The free route, always underneath. A parent who does not want to
          // spend anything still has a way to reach this teacher.
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () =>
                  context.push(signedIn ? '/post-requirement' : '/login'),
              child: const Text('Or post a requirement — it is free'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Use one credit?'),
        content: Text(
          'You’ll see ${Fmt.titleCase(widget.tutor.name)}’s phone and '
          'WhatsApp number, and it stays unlocked for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    try {
      await ref
          .read(usersRepositoryProvider)
          .unlockTutorContact(widget.tutor.id);
      if (!mounted) return;
      ref.invalidate(tutorProvider(widget.tutor.id));
      // A credit was spent, so any balance shown elsewhere is now stale.
      ref.invalidate(walletProvider);
      context.showMessage('Contact unlocked.');
    } on ApiFailure catch (f) {
      if (!mounted) return;
      // 403 is the teacher’s own opt-out. Nothing was charged, and it is not
      // the parent’s mistake, so it gets an explanation with a way forward
      // rather than a red toast reading like a failure.
      if (f.statusCode == 403) {
        await _showOptedOut();
      } else if (f.statusCode == 402) {
        // The balance moved between our check and the tap.
        ref.invalidate(walletProvider);
        context.showMessage('Not enough credits. Add some and try again.');
      } else {
        context.showFailure(f);
      }
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /// What a parent sees when the teacher has switched direct unlocks off.
  Future<void> _showOptedOut() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Fmt.titleCase(widget.tutor.name)} is not sharing their '
                  'number directly',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Some teachers prefer to be approached through a posted '
                  'requirement. Nothing has been charged — your credits are '
                  'untouched.',
                  style: TextStyle(fontSize: 14, height: 1.55),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push('/post-requirement');
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Post a requirement instead'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  String _intl(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 ? '91$digits' : digits;
  }

  Future<void> _open(String uri, String what) async {
    final ok =
        await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
    if (!ok && mounted) context.showMessage("Couldn't open your $what.");
  }
}

// ── What they teach ──────────────────────────────────────────────────────────

class _Teaches extends StatelessWidget {
  const _Teaches({required this.tutor});

  final PublicTutor tutor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    Widget group(String label, List<String> values, {String? empty}) {
      if (values.isEmpty && empty == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: muted)),
            const SizedBox(height: AppSpacing.sm),
            if (values.isEmpty)
              Text(
                empty!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: muted,
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

    Widget row(String label, String value, {bool emphasise = false}) => Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              Expanded(
                child:
                    Text(label, style: TextStyle(fontSize: 13, color: muted)),
              ),
              // Flexible so a long value wraps under itself instead of
              // running off the card at large text scales.
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: emphasise ? FontWeight.w700 : FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('What they teach'),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          padding: EdgeInsets.zero,
          child: Column(
            // Stretch, or the chip groups shrink-wrap and drift to the centre
            // while the label/value rows beside them stay full width. Safe on a
            // Column: the cross axis is horizontal and the card bounds it.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              group('Subjects', tutor.subjects, empty: 'Not listed'),
              const Divider(height: 1),
              group('Classes', tutor.classes, empty: 'Not listed'),
              const Divider(height: 1),
              row(
                'How they teach',
                tutor.modeLabel.isEmpty ? 'Not set' : tutor.modeLabel,
              ),
              if (tutor.expectedFee != null && tutor.expectedFee! > 0) ...[
                const Divider(height: 1),
                row(
                  'Expected fee',
                  '${Fmt.rupees(tutor.expectedFee)} / month',
                  emphasise: true,
                ),
              ],
              if (tutor.locality.trim().isNotEmpty) ...[
                const Divider(height: 1),
                row(
                  'Based in',
                  [tutor.locality, tutor.city]
                      .where((s) => s.trim().isNotEmpty)
                      .join(', '),
                ),
              ],
              // Availability has its own section now — it is a scheduling
              // question, not a "what do they teach" one.
            ],
          ),
        ),
      ],
    );
  }
}

// ── Ratings ──────────────────────────────────────────────────────────────────

class _Ratings extends StatelessWidget {
  const _Ratings({required this.tutor});

  final PublicTutor tutor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final total = tutor.ratingCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Ratings',
          subtitle: 'From ${Fmt.plural(total, 'parent')} who hired them',
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    tutor.avgRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -1,
                      color: isDark ? AppColors.slate50 : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.star_rounded,
                    size: 17,
                    color: Tone.success.foreground(brightness),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    for (var star = 5; star >= 1; star--)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              child: Text(
                                '$star',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                  color: isDark
                                      ? AppColors.slate400
                                      : AppColors.slate500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                child: LinearProgressIndicator(
                                  value: total == 0
                                      ? 0
                                      : (tutor.ratingBreakdown[star] ?? 0) /
                                          total,
                                  minHeight: 6,
                                  backgroundColor: isDark
                                      ? AppColors.slate800
                                      : AppColors.slate200,
                                  valueColor: AlwaysStoppedAnimation(
                                    Tone.success.foreground(brightness),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 20,
                              child: Text(
                                '${tutor.ratingBreakdown[star] ?? 0}',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                  color: isDark
                                      ? AppColors.slate400
                                      : AppColors.slate500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reviews ──────────────────────────────────────────────────────────────────

class _Reviews extends StatelessWidget {
  const _Reviews({required this.tutor});

  final PublicTutor tutor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('What parents say'),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < tutor.reviews.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          THTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tutor.reviews[i].name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var s = 0; s < 5; s++)
                          Icon(
                            s < tutor.reviews[i].rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: s < tutor.reviews[i].rating
                                ? AppColors.amber
                                : muted,
                          ),
                      ],
                    ),
                  ],
                ),
                if (tutor.reviews[i].role.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tutor.reviews[i].role,
                    style: TextStyle(fontSize: 11.5, color: muted),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  tutor.reviews[i].text,
                  style: const TextStyle(fontSize: 13.5, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
