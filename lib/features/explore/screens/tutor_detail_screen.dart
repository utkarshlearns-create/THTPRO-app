import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/public_tutor.dart';
import 'package:tht_app/core/repositories/users_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
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
              tooltip: t.isFavourite ? 'Remove from saved' : 'Save this teacher',
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              _Header(tutor: t),
              const SizedBox(height: AppSpacing.lg),
              _ContactCard(tutor: t),
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

class _Header extends StatelessWidget {
  const _Header({required this.tutor});

  final PublicTutor tutor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(tutor: tutor, size: 72),
        const SizedBox(width: AppSpacing.base),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tutor.name.trim().isEmpty ? 'Teacher' : Fmt.titleCase(tutor.name),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.4,
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (tutor.experienceYears > 0)
                    '${Fmt.plural(tutor.experienceYears, 'year')} teaching',
                  if (tutor.highestQualification.trim().isNotEmpty)
                    tutor.highestQualification,
                ].join(' · '),
                style: TextStyle(fontSize: 13, height: 1.4, color: muted),
              ),
              const SizedBox(height: AppSpacing.sm),
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
                      tutor.avgRating!.toStringAsFixed(1),
                      tone: Tone.success,
                      icon: Icons.star_rounded,
                      dense: true,
                    ),
                  if (tutor.memberSince != null)
                    Pill('On THT since ${tutor.memberSince!.year}', dense: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.tutor, this.size = 52});

  final PublicTutor tutor;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryOrangeLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            Fmt.initials(tutor.name),
            style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryOrangeDark,
            ),
          ),
        );

    final url = tutor.imageUrl;
    if (url == null || url.isEmpty) return fallback();

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback(),
        errorWidget: (_, __, ___) => fallback(),
      ),
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

  Widget _locked() {
    final signedIn = ref.watch(authProvider).isAuthenticated;
    final wallet = signedIn ? ref.watch(walletProvider).valueOrNull : null;
    final hasCredits = (wallet?.balance ?? 0) > 0;

    return THTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 18),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Contact details are hidden',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            signedIn
                ? 'Unlock to see this teacher’s phone and WhatsApp number. One '
                    'credit is used, and the contact stays unlocked for you.'
                : 'Sign in to unlock this teacher’s phone and WhatsApp number.',
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
          'You’ll see ${Fmt.titleCase(widget.tutor.name)}’s phone and WhatsApp '
          'number, and it stays unlocked for you.',
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
      await ref.read(usersRepositoryProvider).unlockTutorContact(widget.tutor.id);
      if (!mounted) return;
      ref.invalidate(tutorProvider(widget.tutor.id));
      // A credit was spent, so any balance shown elsewhere is now stale.
      ref.invalidate(walletProvider);
      context.showMessage('Contact unlocked.');
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

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
                child: Text(label, style: TextStyle(fontSize: 13, color: muted)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: emphasise ? FontWeight.w700 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
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
              if (tutor.availableTimeSlots.isNotEmpty) ...[
                const Divider(height: 1),
                group('Available', tutor.availableTimeSlots),
              ],
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
