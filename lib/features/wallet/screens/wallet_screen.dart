import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/models/wallet.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/wallet/providers/wallet_providers.dart';

/// Credits, validity and where they went.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: AsyncView<Wallet>(
        value: wallet,
        onRetry: () => ref.invalidate(walletProvider),
        loading: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              SkeletonBox(height: 190, radius: AppRadius.xl),
              SizedBox(height: AppSpacing.xl),
              SkeletonList(count: 3, itemHeight: 70),
            ],
          ),
        ),
        data: (w) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(walletProvider);
            ref.invalidate(walletTransactionsProvider);
            await ref.read(walletProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              _BalanceCard(wallet: w),
              if (w.isExpired || w.isExpiringSoon) ...[
                const SizedBox(height: AppSpacing.base),
                _RenewalNotice(wallet: w),
              ],
              const SizedBox(height: AppSpacing.xl),
              const _History(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final days = wallet.daysRemaining;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryOrange, AppColors.primaryOrangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available credits',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Fmt.number(wallet.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 15, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _validity(days),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/packages'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryOrangeDark,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(wallet.hasCredits ? 'Add credits' : 'Buy credits'),
            ),
          ),
        ],
      ),
    );
  }

  String _validity(int? days) {
    if (!wallet.validityActivated && wallet.pendingValidityDays > 0) {
      return '${Fmt.plural(wallet.pendingValidityDays, 'day')} of validity '
          'waiting — it starts on your first unlock.';
    }
    if (wallet.isExpired) return 'Your validity has run out.';
    if (days != null) return 'Valid for another ${Fmt.plural(days, 'day')}.';
    return wallet.hasCredits
        ? 'No expiry on your credits.'
        : 'Buy a plan to start unlocking leads.';
  }
}

class _RenewalNotice extends StatelessWidget {
  const _RenewalNotice({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tone = wallet.isExpired ? Tone.critical : Tone.warning;
    final days = wallet.daysRemaining ?? 0;

    return THTCard(
      onTap: () => context.push('/packages'),
      background: tone.background(brightness),
      borderColor: tone.border(brightness),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 19,
            color: tone.foreground(brightness),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.isExpired
                      ? 'Your plan has expired'
                      : 'Expiring in ${Fmt.plural(days, 'day')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tone.foreground(brightness),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wallet.isExpired
                      ? 'Renew to start unlocking leads again.'
                      : 'Renew now and your remaining credits carry over.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: tone.foreground(brightness).withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: tone.foreground(brightness)),
        ],
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(walletTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Recent activity',
          icon: Icons.receipt_long_rounded,
          iconTone: Tone.info,
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncView<List<WalletTransaction>>(
          value: transactions,
          onRetry: () => ref.invalidate(walletTransactionsProvider),
          loading: const SkeletonList(count: 3, itemHeight: 64),
          compactError: true,
          data: (list) => list.isEmpty
              ? const THTCard(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nothing here yet',
                    message: 'Top-ups and credit usage will show up here.',
                    compact: true,
                  ),
                )
              : THTCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.slate200,
                          ),
                        _TransactionRow(transaction: list[i]),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final credit = transaction.isCredit;
    final tone = credit ? Tone.success : Tone.neutral;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: tone.background(brightness),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              credit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 15,
              color: tone.foreground(brightness),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.trim().isEmpty
                      ? (credit ? 'Credits added' : 'Credit used')
                      : transaction.description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (transaction.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    Fmt.dateTime(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            transaction.signedAmount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: credit
                  ? Tone.success.foreground(brightness)
                  : (isDark ? AppColors.slate200 : AppColors.slate700),
            ),
          ),
        ],
      ),
    );
  }
}
