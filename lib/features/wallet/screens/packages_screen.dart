import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/upgrade_quote.dart';
import 'package:tht_app/core/models/wallet.dart';
import 'package:tht_app/core/repositories/wallet_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/theme/app_type.dart';
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

  /// The coupon the server has accepted, or null when none is applied.
  ///
  /// Page state rather than a provider: unlike the sale and the renewal offer,
  /// a coupon is something the buyer typed on this screen, and it should not
  /// outlive it.
  CouponCheck? _coupon;

  @override
  Widget build(BuildContext context) {
    final packages = ref.watch(creditPackagesProvider);
    final wallet = ref.watch(walletProvider).valueOrNull;

    // Both fall back to safe defaults on failure, so neither can strand the
    // page — read them without an AsyncView.
    // Two discounts can be live at once: a renewal offer held by this teacher,
    // and a sale running for everyone. They never stack — the server charges
    // whichever is larger — so the page quotes the same one.
    final offer =
        ref.watch(walletOfferProvider).valueOrNull ?? RenewalOffer.none;
    final promo =
        ref.watch(platformPromoProvider).valueOrNull ?? PlatformPromo.none;
    final best = Discount.better(offer, promo);

    // What the cards must quote. A coupon retires the renewal offer and then
    // competes with the sale — the server charges the larger of the two and
    // never adds them up. See Discount.betterWithCoupon.
    final quoted = Discount.betterWithCoupon(offer, promo, _coupon);

    // Coupons here are staff referral codes, issued on the teacher side; the
    // website shows the box to teachers only, and a parent who typed one would
    // only ever be told it was not valid.
    final isTeacher = ref.watch(authProvider).role == UserRole.teacher;
    final expiry = ref.watch(walletExpiryProvider).valueOrNull ??
        WalletExpiryStatus.unknown;

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
              ref.invalidate(platformPromoProvider);
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
                // Stood down once a coupon is applied: the coupon box then
                // states the effective percentage itself, and two banners
                // quoting different numbers is how a buyer stops believing
                // either of them.
                if (best.isReal && _coupon == null) ...[
                  _OfferBanner(discount: best),
                  const SizedBox(height: AppSpacing.base),
                ],
                if (!CheckoutService.isSupported) ...[
                  const _WebNotice(),
                  const SizedBox(height: AppSpacing.base),
                ],
                if (isTeacher) ...[
                  _CouponBox(
                    applied: _coupon,
                    // The number the buyer will actually be charged off, which
                    // is not always the coupon's own.
                    effectivePercent: quoted.percentOff,
                    onChanged: (c) => setState(() => _coupon = c),
                  ),
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
                    discount: quoted,
                    busy: _busyPackageId == p.id,
                    disabled: _busyPackageId != null,
                    // Cheapest per credit, not cheapest overall — that is the
                    // comparison a buyer is actually making between plans.
                    bestValue: p.id == bestValueId,
                    onBuy: () => _buy(p, offer, _coupon),
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
                      discount: quoted,
                      busy: _busyPackageId == p.id,
                      disabled: _busyPackageId != null,
                      // The server rejects this outright for anyone who has
                      // never bought credits. Say so here rather than letting
                      // the tap come back as a raw error.
                      lockedReason: expiry.canBuyValidity
                          ? null
                          : 'Buy a credit plan first — this only extends '
                              'credits you already hold.',
                      onBuy: () => _buy(p, offer, _coupon),
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

  Future<void> _buy(
    CreditPackage package,
    RenewalOffer offer,
    CouponCheck? coupon,
  ) async {
    setState(() => _busyPackageId = package.id);
    final repo = ref.read(walletRepositoryProvider);

    try {
      final order = await repo.createOrder(
        package.id,
        // The server resolves the user's offer with or without this, but naming
        // it keeps the code honest about the price the card just quoted.
        offerCode: offer.isLive ? offer.code : null,
        // Sent whenever one is applied, discount or not: a coupon is also what
        // credits the staff member who shared it, and that attribution is owed
        // even on a sale that pays more than the coupon would have.
        couponCode: coupon != null && coupon.isValid ? coupon.code : null,
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
          ref.invalidate(platformPromoProvider);
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
                    fontSize: ThtType.body,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.slate400
                        : AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Fmt.plural(wallet.balance, 'credit'),
                  style: const TextStyle(
                    fontSize: ThtType.headline,
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
  const _OfferBanner({required this.discount});

  final Discount discount;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = Tone.success.foreground(brightness);
    final label = discount.percentLabel;

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
                  // A sale is announced by its name — "Teachers' Day 20% off"
                  // is worth more to a buyer than a bare percentage, and the
                  // name comes from the server so the app never has to know
                  // which sale is running.
                  discount.isSale
                      ? '${discount.label} · $label% off'
                      : '$label% off your renewal',
                  style: TextStyle(
                    fontSize: ThtType.bodyStrong,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  discount.endsOn == null
                      ? 'Applied automatically at checkout.'
                      : 'Applied automatically at checkout · ends '
                          '${Fmt.relative(discount.endsOn).toLowerCase()}.',
                  style: TextStyle(
                    fontSize: ThtType.body,
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
                fontSize: ThtType.body,
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

// ── Coupon ────────────────────────────────────────────────────────

/// "Have a coupon code?" — the website's box, in the app.
///
/// It exists so the buyer knows the price before tapping Buy. It does not
/// decide that price: the server re-resolves the code at order creation, so the
/// worst a wrong answer here can do is surprise someone at the payment sheet,
/// which is exactly the surprise this box is for preventing.
class _CouponBox extends ConsumerStatefulWidget {
  const _CouponBox({
    required this.applied,
    required this.effectivePercent,
    required this.onChanged,
  });

  /// The code the server has accepted, or null when none is applied.
  final CouponCheck? applied;

  /// What the buyer will actually be charged off with this coupon in place —
  /// the larger of the sale and the coupon, because the server never stacks
  /// them. Quoting the coupon's own percentage instead would understate a
  /// running sale and read as the coupon having made things worse.
  final double effectivePercent;

  final ValueChanged<CouponCheck?> onChanged;

  @override
  ConsumerState<_CouponBox> createState() => _CouponBoxState();
}

class _CouponBoxState extends ConsumerState<_CouponBox> {
  final _code = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter a coupon code.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final res = await ref.read(walletRepositoryProvider).couponStatus(code);
      if (!mounted) return;
      if (res.isValid) {
        // The server's spelling, not the typed one — that is what checkout
        // sends, so that is what the buyer should see applied.
        widget.onChanged(res);
        setState(() => _checking = false);
      } else {
        setState(() {
          _error = 'That code isn’t valid.';
          _checking = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      // Kept apart from an invalid code on purpose: one means the code is
      // wrong, the other means we could not tell, and telling someone their
      // valid code is invalid is how a sale gets lost.
      setState(() {
        _error = 'Could not check the code just now. Please try again.';
        _checking = false;
      });
    }
  }

  void _remove() {
    widget.onChanged(null);
    _code.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final applied = widget.applied;
    final pct = widget.effectivePercent;
    final pctLabel = pct == pct.roundToDouble()
        ? pct.toStringAsFixed(0)
        : pct.toStringAsFixed(1);

    return THTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Have a coupon code?',
            icon: Icons.sell_outlined,
            iconTone: Tone.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          if (applied != null)
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Tone.success.foreground(brightness),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    pct > 0
                        // A sale can be the one paying, so this says what comes
                        // off rather than what the coupon claims.
                        ? 'Code ${applied.code} applied — $pctLabel% off '
                            'at checkout.'
                        : 'Code ${applied.code} applied.',
                    style: TextStyle(
                      fontSize: ThtType.body,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: Tone.success.foreground(brightness),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: _remove,
                  child: const Text('Remove'),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    enabled: !_checking,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _apply(),
                    decoration: const InputDecoration(
                      hintText: 'Enter coupon code',
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: ThtType.bodyStrong,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _checking ? null : _apply,
                  child: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: ThtType.caption,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Applies when you buy a plan. If a sale is already running, you '
              'get whichever discount is larger — they do not add up.',
              style: TextStyle(fontSize: ThtType.caption, height: 1.45, color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

// ── One plan ─────────────────────────────────────────────────────────────────

class _PlanCard extends ConsumerWidget {
  const _PlanCard({
    required this.package,
    required this.discount,
    required this.busy,
    required this.disabled,
    required this.onBuy,
    this.bestValue = false,
    this.lockedReason,
  });

  final CreditPackage package;
  final Discount discount;
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
    final discounted = discount.isReal;

    // Only quoted for a plan that can actually be bought, and only shown when
    // the server says there is real value to credit back — a quote that fails
    // or has nothing to prorate leaves the card exactly as it was.
    final quote =
        locked ? null : ref.watch(upgradeQuoteProvider(package.id)).valueOrNull;
    final upgrade = quote != null && quote.isRealUpgrade ? quote : null;
    final payable =
        discounted ? discount.applyTo(package.price) : package.price;

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
                            fontSize: ThtType.figure,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            letterSpacing: -1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color:
                                isDark ? AppColors.slate50 : AppColors.slate900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Flexible: the unit sits beside a 32px numeral, and
                        // on a narrow phone a longer one ran off the card.
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              heroUnit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: ThtType.body,
                                fontWeight: FontWeight.w600,
                                color: muted,
                              ),
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
                        fontSize: ThtType.body,
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
                        fontSize: ThtType.body,
                        color: muted,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: muted,
                      ),
                    ),
                  Text(
                    Fmt.rupees(payable),
                    style: TextStyle(
                      fontSize: ThtType.headline,
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
                      style: TextStyle(fontSize: ThtType.caption, color: muted),
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
                  '${discount.percentLabel}% OFF',
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
                  fontSize: ThtType.bodyStrong,
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
              fontSize: ThtType.caption,
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
    final shown =
        features.where((f) => f.trim().isNotEmpty).take(_max).toList();
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
                      fontSize: ThtType.body,
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
              fontSize: ThtType.caption,
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
              style: TextStyle(fontSize: ThtType.body, height: 1.45, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
