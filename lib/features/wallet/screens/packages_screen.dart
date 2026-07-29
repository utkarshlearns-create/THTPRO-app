import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/wallet.dart';
import 'package:tht_app/core/repositories/wallet_repository.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/wallet/providers/wallet_providers.dart';
import 'package:tht_app/features/wallet/services/checkout_service.dart';

/// The plans a teacher can buy, and the checkout that follows.
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

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(creditPackagesProvider);
              ref.invalidate(walletProvider);
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
                if (wallet != null) _CurrentPlan(wallet: wallet),
                const SizedBox(height: AppSpacing.lg),
                if (!CheckoutService.isSupported) ...[
                  const _WebNotice(),
                  const SizedBox(height: AppSpacing.lg),
                ],
                for (final p in credit) ...[
                  _PackageCard(
                    package: p,
                    busy: _busyPackageId == p.id,
                    disabled: _busyPackageId != null,
                    // Cheapest per credit, not cheapest overall — that is the
                    // comparison a buyer is actually making between plans.
                    bestValue: p.id == _bestValueId(credit),
                    onBuy: () => _buy(p),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (validity.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'EXTEND YOUR VALIDITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.slate400
                          : AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'These add days to credits you already hold. They do not add '
                    'new credits.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.slate400
                          : AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final p in validity) ...[
                    _PackageCard(
                      package: p,
                      busy: _busyPackageId == p.id,
                      disabled: _busyPackageId != null,
                      onBuy: () => _buy(p),
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

  Future<void> _buy(CreditPackage package) async {
    setState(() => _busyPackageId = package.id);
    final repo = ref.read(walletRepositoryProvider);

    try {
      final order = await repo.createOrder(package.id);
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
            const Pill('Expired', tone: Tone.critical, icon: Icons.timer_off_outlined)
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

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.busy,
    required this.disabled,
    required this.onBuy,
    this.bestValue = false,
  });

  final CreditPackage package;
  final bool busy;
  final bool disabled;
  final VoidCallback onBuy;

  /// Lowest cost per credit of the plans on offer.
  final bool bestValue;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;
    final perCredit = package.pricePerCredit;

    return THTCard(
      elevated: bestValue,
      borderColor: bestValue ? AppColors.primaryOrange : null,
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
                    Text(
                      package.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(),
                      style: TextStyle(fontSize: 12.5, height: 1.45, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Fmt.rupees(package.price),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
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
          if (package.description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              package.description.trim(),
              style: TextStyle(fontSize: 12.5, height: 1.5, color: muted),
            ),
          ],
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: disabled ? null : onBuy,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Buy for ${Fmt.rupees(package.price)}'),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    if (package.isValidityOnly) {
      return 'Adds ${Fmt.plural(package.validityDays, 'day')} to your existing '
          'credits';
    }
    final credits = '${Fmt.number(package.credits)} credits';
    return package.validityDays > 0
        ? '$credits, valid ${Fmt.plural(package.validityDays, 'day')}'
        : credits;
  }
}
