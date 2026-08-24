import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/upgrade_quote.dart';
import 'package:tht_app/core/models/wallet.dart';
import 'package:tht_app/core/repositories/wallet_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/wallet/providers/wallet_providers.dart';
import 'package:tht_app/features/wallet/services/checkout_service.dart';

/// The plans a user can buy, and the checkout that follows.
class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  /// The plan currently going through checkout, so only its button spins.
  int? _busyPackageId;

  @override
  Widget build(BuildContext context) {
    final packages = ref.watch(creditPackagesProvider);
    final wallet = ref.watch(walletProvider).valueOrNull;

    // Both fall back to safe defaults on failure, so neither can strand the
    // page — read them without an AsyncView.
    final offer = ref.watch(walletOfferProvider).valueOrNull ?? RenewalOffer.none;
    final expiry =
        ref.watch(walletExpiryProvider).valueOrNull ?? WalletExpiryStatus.unknown;

    return Scaffold(
      appBar: AppBar(title: const Text('Add credits')),
      body: AsyncView<List<CreditPackage>>(
        value: packages,
        onRetry: () => ref.invalidate(creditPackagesProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SkeletonList(count: 3, itemHeight: 130),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.sell_outlined,
              title: 'No plans available',
              message: 'Plans are being updated. Please check back shortly.',
            );
          }

          final credit = list.where((p) => !p.isValidityOnly).toList();
          final validity = list.where((p) => p.isValidityOnly).toList();
          final bestValueId = _bestValueId(credit);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(creditPackagesProvider);
              ref.invalidate(walletProvider);
              ref.invalidate(walletOfferProvider);
              ref.invalidate(walletExpiryProvider);
              await ref.read(creditPackagesProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                if (wallet != null) ...[
                  _CurrentPlan(wallet: wallet),
                  const SizedBox(height: AppSpacing.base),
                ],
                if (offer.isLive) ...[
                  _OfferBanner(offer: offer),
                  const SizedBox(height: AppSpacing.base),
                ],
                if (!CheckoutService.isSupported) ...[
                  const _WebNotice(),
                  const SizedBox(height: AppSpacing.base),
                ],
                const SizedBox(height: AppSpacing.xs),
                const SectionHeader(
                  'Credit plans',
                  subtitle: 'Credits let you unlock a parent’s contact.',
                  icon: Icons.toll_rounded,
                  iconTone: Tone.accent,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final p in credit) ...[
                  _PlanCard(
                    package: p,
                    offer: offer,
                    busy: _busyPackageId == p.id,
                    disabled: _busyPackageId != null,
                    // Cheapest per credit, not cheapest overall — that is the
                    // comparison a buyer is actually making between plans.
                    bestValue: p.id == bestValueId,
                    onBuy: () => _buy(p, offer),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (validity.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.base),
                  const SectionHeader(
                    'Extend your validity',
                    subtitle: 'Adds days to credits you already hold. '
                        'These do not add new credits.',
                    icon: Icons.more_time_rounded,
                    iconTone: Tone.info,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final p in validity) ...[
                    _PlanCard(
                      package: p,
                      offer: offer,
                      busy: _busyPackageId == p.id,
                      disabled: _busyPackageId != null,
                      // The server rejects this outright for anyone who has
                      // never bought credits. Say so here rather than letting
                      // the tap come back as a raw error.
                      lockedReason: expiry.canBuyValidity
                          ? null
                          : 'Buy a credit plan first — this only extends '
                              'credits you already hold.',
                      onBuy: () => _buy(p, offer),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// The plan with the lowest price per credit, or null when fewer than two
  /// plans are comparable — a single option is not a "best" one.
  int? _bestValueId(List<CreditPackage> packages) {
    final comparable =
        packages.where((p) => (p.pricePerCredit ?? 0) > 0).toList();
    if (comparable.length < 2) return null;
    comparable.sort((a, b) => a.pricePerCredit!.compareTo(b.pricePerCredit!));
    return comparable.first.id;
  }

  Future<void> _buy(CreditPackage package, RenewalOffer offer) async {
    setState(() => _busyPackageId = package.id);
    final repo = ref.read(walletRepositoryProvider);

    try {
      final order = await repo.createOrder(
        package.id,
        // The server resolves the user's offer with or without this, but naming
        // it keeps the code honest about the price the card just quoted.
        offerCode: offer.isLive ? offer.code : null,
      );
      if (!mounted) return;

      final result = await CheckoutService().open(
        order: order,
        user: ref.read(currentUserProvider).valueOrNull,
      );
      if (!mounted) return;

      switch (result) {
        case CheckoutCancelled():
          // Changing your mind is not an error worth a message.
          break;

        case CheckoutFailed(:final message):
          context.showMessage(message);

        case CheckoutPaid(:final orderId, :final paymentId, :final signature):
          await repo.verifyPayment(
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
            packageId: package.id,
          );
          if (!mounted) return;
          ref.invalidate(walletProvider);
          ref.invalidate(walletTransactionsProvider);
          // An offer is single-use, and buying validity changes whether more
          // validity may be bought.
          ref.invalidate(walletOfferProvider);
          ref.invalidate(walletExpiryProvider);
          context.showMessage(
            package.isValidityOnly
                ? 'Validity extended by ${Fmt.plural(package.validityDays, 'day')}.'
                : '${Fmt.number(package.credits)} credits added to your wallet.',
          );
      }
    } catch (e) {
      if (mounted) context.showFailure(e);
    } finally {
      if (mounted) setState(() => _busyPackageId = null);
    }
  }
}

// ── Current standing ─────────────────────────────────────────────────────────

class _CurrentPlan extends StatelessWidget {
  const _CurrentPlan({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final days = wallet.daysRemaining;

    return THTCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.slate400
                        : AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Fmt.plural(wallet.balance, 'credit'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (wallet.isExpired)
            const Pill('Expired',
                tone: Tone.critical, icon: Icons.timer_off_outlined)
          else if (days != null)
            Pill(
              '${Fmt.plural(days, 'day')} left',
              tone: wallet.isExpiringSoon ? Tone.warning : Tone.neutral,
              icon: Icons.schedule_rounded,
            )
          else if (wallet.pendingValidityDays > 0)
            Pill(
              '${Fmt.plural(wallet.pendingValidityDays, 'day')} not started',
              tone: Tone.info,
              icon: Icons.schedule_rounded,
            ),
        ],
      ),
    );
  }
}

/// The discount the server is already applying.
///
/// Without this the page quotes full price and the payment sheet charges less,
/// which reads as a pricing bug even though the user is better off.
class _OfferBanner extends StatelessWidget {
  const _OfferBanner({required this.offer});

  final RenewalOffer offer;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = Tone.success.foreground(brightness);
    final pct = offer.percentOff;
    final label = pct == pct.roundToDouble()
        ? pct.toStringAsFixed(0)
        : pct.toStringAsFixed(1);

    return THTCard(
      background: Tone.success.background(brightness),
      borderColor: Tone.success.border(brightness),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded, size: 19, color: fg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label% off your renewal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  offer.expiresAt == null
                      ? 'Applied automatically at checkout.'
                      : 'Applied automatically at checkout · ends '
                          '${Fmt.relative(offer.expiresAt).toLowerCase()}.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: fg.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebNotice extends StatelessWidget {
  const _WebNotice();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return THTCard(
      background: Tone.info.background(brightness),
      borderColor: Tone.info.border(brightness),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.phone_iphone_rounded,
            size: 18,
            color: Tone.info.foreground(brightness),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Payments work in the Android and iOS app. You can browse plans '
              'here, but buying one needs the app on your phone.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Tone.info.foreground(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── One plan ─────────────────────────────────────────────────────────────────

class _PlanCard extends ConsumerWidget {
  const _PlanCard({
    required this.package,
    required this.offer,
    required this.busy,
    required this.disabled,
    required this.onBuy,
    this.bestValue = false,
    this.lockedReason,
  });

  final CreditPackage package;
  final RenewalOffer offer;
  final bool busy;
  final bool disabled;
  final VoidCallback onBuy;

  /// Lowest cost per credit of the plans on offer.
  final bool bestValue;

  /// Why this plan cannot be bought right now, or null when it can.
  final String? lockedReason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final locked = lockedReason != null;
    final discounted = offer.isLive;

    // Only quoted for a plan that can actually be bought, and only shown when
    // the server says there is real value to credit back — a quote that fails
    // or has nothing to prorate leaves the card exactly as it was.
    final quote = locked
        ? null
        : ref.watch(upgradeQuoteProvider(package.id)).valueOrNull;
    final upgrade = quote != null && quote.isRealUpgrade ? quote : null;
    final payable =
        discounted ? offer.discounted(package.price) : package.price;

    // Per the price actually payable, not the struck-through one — a discounted
    // ₹479 plan sitting above "₹200 per credit" invites the buyer to check the
    // arithmetic and conclude one of the two numbers is lying.
    final perCredit = package.credits > 0 ? payable / package.credits : null;

    // A validity plan carries no credits, so leading with "0" would be a lie —
    // for those the days are the headline.
    final heroValue = package.isValidityOnly
        ? Fmt.number(package.validityDays)
        : Fmt.number(package.credits);
    final heroUnit = package.isValidityOnly
        ? (package.validityDays == 1 ? 'day' : 'days')
        : (package.credits == 1 ? 'credit' : 'credits');

    return THTCard(
      elevated: bestValue,
      borderColor: bestValue ? Theme.of(context).colorScheme.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bestValue) ...[
            const Pill(
              'Best value per credit',
              tone: Tone.accent,
              icon: Icons.savings_outlined,
              dense: true,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          heroValue,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            letterSpacing: -1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color:
                                isDark ? AppColors.slate50 : AppColors.slate900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            heroUnit,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      package.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (discounted)
                    Text(
                      Fmt.rupees(package.price),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: muted,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: muted,
                      ),
                    ),
                  Text(
                    Fmt.rupees(payable),
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.4,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark ? AppColors.slate50 : AppColors.slate900,
                    ),
                  ),
                  if (perCredit != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '₹${perCredit.toStringAsFixed(0)} per credit',
                      style: TextStyle(fontSize: 11.5, color: muted),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              // A validity plan's hero number already *is* its validity, so
              // repeating it in a pill says the same thing twice.
              if (!package.isValidityOnly)
                Pill(
                  package.validityLabel,
                  tone: package.isLifetime ? Tone.success : Tone.info,
                  icon: package.isLifetime
                      ? Icons.all_inclusive_rounded
                      : Icons.schedule_rounded,
                  dense: true,
                ),
              if (discounted)
                Pill(
                  '${offer.percentOff.toStringAsFixed(0)}% OFF',
                  tone: Tone.success,
                  icon: Icons.local_offer_rounded,
                  dense: true,
                ),
            ],
          ),
          if (package.features.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _FeatureList(features: package.features),
          ],
          if (locked) ...[
            const SizedBox(height: AppSpacing.md),
            _LockedNote(reason: lockedReason!),
          ],
          if (upgrade != null) ...[
            const SizedBox(height: AppSpacing.md),
            _UpgradeNote(quote: upgrade),
          ],
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: disabled || locked ? null : onBuy,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Buy for ${Fmt.rupees(payable)}'),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the plan costs given what is left of the current one.
///
/// Deliberately additive rather than replacing the headline price: the buy
/// button charges the plan's own price, and quoting the prorated figure in the
/// hero slot would put a number on the card that the payment sheet then
/// contradicts. Upgrading is arranged by our team, so this tells the teacher
/// what to ask for.
class _UpgradeNote extends StatelessWidget {
  const _UpgradeNote({required this.quote});

  final UpgradeQuote quote;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = Tone.info.foreground(brightness);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Tone.info.background(brightness),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Tone.info.border(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upgrade_rounded, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                'Upgrade for ${Fmt.rupees(quote.upgradePrice)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${Fmt.rupees(quote.remainingValue)} left on '
            '${quote.currentPlanName ?? 'your current plan'} comes off the '
            'price'
            '${quote.upgradeCredits > 0 ? ', and you gain ${Fmt.plural(quote.upgradeCredits, 'credit')}' : ''}'
            '. Ask your counsellor to apply it.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: fg.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

/// The admin's bullets for a plan.
///
/// Kept below the structured facts on purpose: these are free text that can
/// duplicate — and occasionally contradict — the real validity and credit
/// figures above, so they read as supporting copy, not as the specification.
class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.features});

  final List<String> features;

  static const int _max = 4;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final shown = features.where((f) => f.trim().isNotEmpty).take(_max).toList();
    final extra = features.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Tone.success.foreground(brightness),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    f.trim(),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: isDark ? AppColors.slate300 : AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (extra > 0)
          Text(
            '+$extra more',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
      ],
    );
  }
}

class _LockedNote extends StatelessWidget {
  const _LockedNote({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = Tone.warning.foreground(brightness);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Tone.warning.background(brightness),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Tone.warning.border(brightness)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(fontSize: 12.5, height: 1.45, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
