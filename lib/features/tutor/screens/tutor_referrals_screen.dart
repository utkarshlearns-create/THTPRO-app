import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/affiliate.dart';
import 'package:tht_app/core/repositories/affiliate_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/note_box.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';

final affiliateProvider = FutureProvider.autoDispose<Affiliate>(
  (ref) => ref.watch(affiliateRepositoryProvider).dashboard(),
);

/// Refer & Earn: the teacher's code, who joined on it, and the money.
class TutorReferralsScreen extends ConsumerStatefulWidget {
  const TutorReferralsScreen({super.key});

  @override
  ConsumerState<TutorReferralsScreen> createState() =>
      _TutorReferralsScreenState();
}

class _TutorReferralsScreenState extends ConsumerState<TutorReferralsScreen> {
  bool _requesting = false;

  @override
  Widget build(BuildContext context) {
    final affiliate = ref.watch(affiliateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Refer and earn')),
      body: AsyncView<Affiliate>(
        value: affiliate,
        onRetry: () => ref.invalidate(affiliateProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              SkeletonBox(height: 150, radius: AppRadius.xl),
              SizedBox(height: AppSpacing.lg),
              SkeletonList(count: 3, itemHeight: 64),
            ],
          ),
        ),
        data: (a) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(affiliateProvider);
            await ref.read(affiliateProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.base,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: _body(a),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(Affiliate a) => [
        _CodeCard(affiliate: a, onShare: () => _share(a)),
        const SizedBox(height: AppSpacing.base),
        _Totals(affiliate: a),
        const SizedBox(height: AppSpacing.base),
        _payout(a),
        const SizedBox(height: AppSpacing.xl),
        if (a.recentEarnings.isNotEmpty) ...[
          const SectionHeader(
            'Recent earnings',
            icon: Icons.payments_outlined,
            iconTone: Tone.success,
          ),
          const SizedBox(height: AppSpacing.md),
          THTCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < a.recentEarnings.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _EarningRow(earning: a.recentEarnings[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        SectionHeader(
          'Who joined',
          icon: Icons.group_add_outlined,
          iconTone: Tone.info,
          subtitle: a.referredUsers.isEmpty
              ? null
              : '${a.convertedCount} of ${a.referredUsers.length} '
                  'bought a plan',
        ),
        const SizedBox(height: AppSpacing.md),
        if (a.referredUsers.isEmpty)
          const THTCard(
            child: EmptyState(
              icon: Icons.person_add_alt_outlined,
              title: 'Nobody yet',
              message: 'Share your link with teachers you know. You earn when '
                  'they join and buy a plan.',
              compact: true,
            ),
          )
        else
          THTCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < a.referredUsers.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _ReferredRow(user: a.referredUsers[i]),
                ],
              ],
            ),
          ),
      ];

  /// The payout ask, or what stands between the teacher and one.
  Widget _payout(Affiliate a) {
    if (a.pendingPayout <= 0) {
      return const NoteBox(
        tone: Tone.info,
        message: 'Nothing owing right now. You earn when someone who joins on '
            'your link buys a plan.',
      );
    }

    if (!a.canRequestPayout) {
      return NoteBox(
        tone: Tone.warning,
        title: 'Payouts start at ${Fmt.rupees(Affiliate.minimumPayout)}',
        message: '${Fmt.rupees(a.shortfall)} more and you can ask for '
            'the ${Fmt.rupees(a.pendingPayout)} you have earned.',
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _requesting ? null : _requestPayout,
        icon: _requesting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.account_balance_outlined, size: 18),
        label: Text('Request ${Fmt.rupees(a.pendingPayout)} payout'),
      ),
    );
  }

  Future<void> _share(Affiliate a) async {
    if (a.link.isEmpty) return;
    await Clipboard.setData(ClipboardData(
      text: 'Join The Home Tuitions as a teacher and start getting tuitions '
          'near you: ${a.link}',
    ));
    if (mounted) context.showMessage('Invite copied — paste it anywhere.');
  }

  Future<void> _requestPayout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request your payout?'),
        content: const Text(
          'We pay out everything you are owed, not a part of it. Our team '
          'reviews the request and transfers it — you cannot raise another '
          'while one is pending.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Request it'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _requesting = true);
    try {
      await ref.read(affiliateRepositoryProvider).requestPayout();
      if (!mounted) return;
      ref.invalidate(affiliateProvider);
      context.showMessage('Payout requested. We will be in touch.');
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }
}

// ── The code ─────────────────────────────────────────────────────────────────

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.affiliate, required this.onShare});

  final Affiliate affiliate;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, Color.lerp(primary, Colors.black, 0.18)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your referral code',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  affiliate.code.isEmpty ? '—' : affiliate.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: affiliate.code.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: affiliate.code),
                        );
                        if (context.mounted) {
                          context.showMessage('Code copied.');
                        }
                      },
                icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                tooltip: 'Copy code',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: affiliate.link.isEmpty ? null : onShare,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                  ),
                  icon: const Icon(Icons.share_outlined, size: 17),
                  label: const Text('Copy invite'),
                ),
              ),
              if (affiliate.link.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: () => launchUrl(
                    Uri.parse(affiliate.link),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded,
                      color: Colors.white70),
                  tooltip: 'Open the link',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.affiliate});

  final Affiliate affiliate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return THTCard(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Figure(
              value: '${affiliate.totalReferred}',
              label: 'Joined on your link',
            ),
            VerticalDivider(
              width: AppSpacing.md,
              thickness: 1,
              color: isDark ? AppColors.slate800 : AppColors.slate200,
            ),
            _Figure(
              value: Fmt.rupees(affiliate.totalEarned),
              label: 'Earned in total',
              tone: Tone.success,
            ),
            VerticalDivider(
              width: AppSpacing.md,
              thickness: 1,
              color: isDark ? AppColors.slate800 : AppColors.slate200,
            ),
            _Figure(
              value: Fmt.rupees(affiliate.pendingPayout),
              label: 'Owed to you',
              tone: affiliate.pendingPayout > 0 ? Tone.warning : Tone.neutral,
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.value,
    required this.label,
    this.tone = Tone.neutral,
  });

  final String value;
  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.15,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: tone == Tone.neutral
                  ? (isDark ? AppColors.slate50 : AppColors.slate900)
                  : tone.foreground(brightness),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningRow extends StatelessWidget {
  const _EarningRow({required this.earning});

  final AffiliateEarning earning;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earning.description.trim().isEmpty
                      ? earning.typeLabel
                      : earning.description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.slate100 : AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Fmt.date(earning.createdAt),
                  style: TextStyle(fontSize: 11.5, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '+${Fmt.rupees(earning.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: Tone.success.foreground(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferredRow extends StatelessWidget {
  const _ReferredRow({required this.user});

  final ReferredUser user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Fmt.titleCase(user.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.slate100 : AppColors.slate800,
                  ),
                ),
                if (user.joinedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Joined ${Fmt.relative(user.joinedAt).toLowerCase()}',
                    style: TextStyle(fontSize: 11.5, color: muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // The distinction that matters: only a plan purchase pays.
          user.purchasedPlan
              ? const Pill('Bought a plan', tone: Tone.success, dense: true)
              : const Pill('Not yet', dense: true),
        ],
      ),
    );
  }
}
