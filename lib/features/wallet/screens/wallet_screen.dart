import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/payment_record.dart';
import 'package:tht_app/core/models/wallet.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/ui/async_view.dart';
import 'package:tht_app/core/ui/pill.dart';
import 'package:tht_app/core/ui/section_header.dart';
import 'package:tht_app/core/ui/states.dart';
import 'package:tht_app/core/ui/tht_card.dart';
import 'package:tht_app/core/ui/tone.dart';
import 'package:tht_app/core/utils/formatters.dart';
import 'package:tht_app/features/wallet/providers/wallet_providers.dart';

/// Credits, validity and where they went.
///
/// Credits are the least intuitive thing in this app — unlocking a lead costs
/// nothing up front, and the validity clock does not start on the day you pay —
/// so this screen explains the rules rather than only reporting a number.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    // Institutes have a read-only wallet — balance and history, no top-up.
    final canBuy = ref.watch(authProvider).role != UserRole.institution;

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
              _BalanceCard(wallet: w, canBuy: canBuy),
              if (canBuy && (w.isExpired || w.isExpiringSoon)) ...[
                const SizedBox(height: AppSpacing.base),
                _RenewalNotice(wallet: w),
              ],
              if (!w.validityActivated && w.pendingValidityDays > 0) ...[
                const SizedBox(height: AppSpacing.base),
                _PausedClockNotice(wallet: w),
              ],
              const SizedBox(height: AppSpacing.base),
              _AtAGlance(wallet: w),
              const SizedBox(height: AppSpacing.xl),
              const _HowCreditsWork(),
              const SizedBox(height: AppSpacing.xl),
              const _History(),
              const SizedBox(height: AppSpacing.xl),
              const _Payments(),
              const SizedBox(height: AppSpacing.xl),
              const _GoodToKnow(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Balance ──────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet, required this.canBuy});

  final Wallet wallet;

  /// False for institutes: no institute credit packages exist, so a checkout
  /// entrance would open an empty list.
  final bool canBuy;

  @override
  Widget build(BuildContext context) {
    final days = wallet.daysRemaining;
    // The wallet is a tab on both the parent and teacher bars, so the card
    // takes the role's colour rather than a literal — orange beside a blue
    // Home would read as a bug, not as branding.
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, Color.lerp(primary, Colors.black, 0.18)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 17,
                color: Colors.white70,
              ),
              SizedBox(width: 7),
              Text(
                'Available credits',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
          // No purchase flow exists for institutes — there are no institute
          // credit packages to sell — so the wallet is informational for them
          // rather than offering a checkout that would open an empty list.
          if (canBuy) ...[
            const SizedBox(height: AppSpacing.base),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/packages'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(wallet.hasCredits ? 'Add credits' : 'Buy credits'),
              ),
            ),
          ],
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

// ── At a glance ──────────────────────────────────────────────────────────────

/// Three numbers on one row, so the state of the account reads in a glance
/// without scrolling into the history.
class _AtAGlance extends ConsumerWidget {
  const _AtAGlance({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = ref.watch(walletTransactionsProvider).valueOrNull;

    final spent = transactions
        ?.where((t) => !t.isCredit)
        .fold<int>(0, (sum, t) => sum + t.amount.abs());

    final String validityValue;
    final String validityLabel;
    if (!wallet.validityActivated && wallet.pendingValidityDays > 0) {
      validityValue = '${wallet.pendingValidityDays}';
      validityLabel = 'Days waiting';
    } else if (wallet.isExpired) {
      validityValue = '0';
      validityLabel = 'Days left';
    } else if (wallet.daysRemaining != null) {
      validityValue = '${wallet.daysRemaining}';
      validityLabel = 'Days left';
    } else {
      validityValue = '∞';
      validityLabel = 'No expiry';
    }

    return THTCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _GlanceCell(
                icon: Icons.toll_rounded,
                tone: Tone.accent,
                value: Fmt.number(wallet.balance),
                label: 'Credits',
              ),
            ),
            _GlanceDivider(isDark: isDark),
            Expanded(
              child: _GlanceCell(
                icon: Icons.hourglass_bottom_rounded,
                tone: wallet.isExpired
                    ? Tone.critical
                    : wallet.isExpiringSoon
                        ? Tone.warning
                        : Tone.info,
                value: validityValue,
                label: validityLabel,
              ),
            ),
            _GlanceDivider(isDark: isDark),
            Expanded(
              child: _GlanceCell(
                icon: Icons.lock_open_rounded,
                tone: Tone.success,
                value: spent == null ? '—' : Fmt.number(spent),
                label: 'Credits spent',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlanceCell extends StatelessWidget {
  const _GlanceCell({
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Tone tone;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: tone.foreground(brightness)),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.4,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: isDark ? AppColors.slate50 : AppColors.slate900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
      ],
    );
  }
}

class _GlanceDivider extends StatelessWidget {
  const _GlanceDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      indent: 4,
      endIndent: 4,
      color: isDark ? AppColors.darkBorder : AppColors.slate200,
    );
  }
}

// ── Explainers ───────────────────────────────────────────────────────────────

/// The four rules of the credit system, in the order a teacher meets them.
///
/// Every line here is written against [UnlockStatus]'s contract: unlocking is a
/// commitment, not a purchase. Copy that says "one credit reveals the number"
/// would be wrong, and would have teachers hoarding credits they never needed
/// to spend.
class _HowCreditsWork extends StatelessWidget {
  const _HowCreditsWork();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'How your credits work',
          subtitle: 'Four things worth knowing before you spend one.',
          icon: Icons.school_rounded,
          iconTone: Tone.accent,
        ),
        SizedBox(height: AppSpacing.md),
        THTCard(
          child: Column(
            children: [
              _Step(
                emoji: '💳',
                title: 'Buy a plan',
                body: 'Credits land in your wallet as soon as the payment '
                    'clears. Nothing is held back.',
              ),
              _StepGap(),
              _Step(
                emoji: '🔓',
                title: 'Unlocking is free',
                body: 'Revealing a parent\'s number costs nothing up front. '
                    'You only need at least one credit in your wallet to be '
                    'allowed to unlock at all.',
              ),
              _StepGap(),
              _Step(
                emoji: '🤝',
                title: 'Turn up, and it stays yours',
                body: 'A credit is deducted later only if you never visit the '
                    'family. Go to the demo and the credit is never spent.',
              ),
              _StepGap(),
              _Step(
                emoji: '⏳',
                title: 'Your clock starts on the first unlock',
                body: 'Validity days sit paused from the day you buy them. '
                    'They begin counting the first time you unlock a lead, not '
                    'a moment earlier.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.emoji, required this.title, required this.body});

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate800 : AppColors.slate100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepGap extends StatelessWidget {
  const _StepGap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: AppSpacing.base);
}

/// The edge cases that otherwise arrive as a surprise.
class _GoodToKnow extends StatelessWidget {
  const _GoodToKnow();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Good to know',
          icon: Icons.lightbulb_outline_rounded,
          iconTone: Tone.warning,
        ),
        const SizedBox(height: AppSpacing.md),
        THTCard(
          background: Tone.info.background(brightness),
          borderColor: Tone.info.border(brightness),
          child: const Column(
            children: [
              _Note(
                icon: Icons.groups_rounded,
                text: 'Some leads cap how many teachers can unlock them. Once '
                    'that cap is full, nobody else can see that parent — so a '
                    'fresh lead is worth moving on.',
              ),
              SizedBox(height: AppSpacing.md),
              _Note(
                icon: Icons.more_time_rounded,
                text: 'Validity-only plans add days to credits you already '
                    'hold. They do not add new credits.',
              ),
              SizedBox(height: AppSpacing.md),
              _Note(
                icon: Icons.autorenew_rounded,
                text: 'Renew before your validity lapses and whatever you have '
                    'not spent carries over.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = Tone.info.foreground(brightness);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: fg),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, height: 1.5, color: fg),
          ),
        ),
      ],
    );
  }
}

// ── Notices ──────────────────────────────────────────────────────────────────

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

/// Bought days that have not started counting yet.
///
/// This is the single most confusing state in the wallet — the number on the
/// card is real, but nothing is ticking — so it gets said out loud rather than
/// left for someone to work out from a balance that never moves.
class _PausedClockNotice extends StatelessWidget {
  const _PausedClockNotice({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    const tone = Tone.info;

    return THTCard(
      background: tone.background(brightness),
      borderColor: tone.border(brightness),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.pause_circle_outline_rounded,
            size: 19,
            color: tone.foreground(brightness),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Fmt.plural(wallet.pendingValidityDays, 'day')} on hold',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tone.foreground(brightness),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nothing is ticking yet. Your validity starts the first time '
                  'you unlock a lead, so there is no rush to use it.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: tone.foreground(brightness).withValues(alpha: 0.95),
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

// ── History ──────────────────────────────────────────────────────────────────

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

/// What was actually charged, as opposed to what the credits did.
///
/// Hidden entirely when nobody has ever paid — a heading over "no payments" is
/// noise on a wallet that has only ever held free credits.
class _Payments extends ConsumerWidget {
  const _Payments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(walletPaymentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AsyncView<List<PaymentRecord>>(
      value: payments,
      onRetry: () => ref.invalidate(walletPaymentsProvider),
      loading: const SizedBox.shrink(),
      compactError: true,
      data: (list) => list.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  'Payments',
                  icon: Icons.credit_card_rounded,
                  iconTone: Tone.neutral,
                  subtitle: '${Fmt.plural(list.length, 'payment')} on record',
                ),
                const SizedBox(height: AppSpacing.md),
                THTCard(
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
                        _PaymentRow(payment: list[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final muted = isDark ? AppColors.slate400 : AppColors.slate500;

    final tone = payment.isSuccessful
        ? Tone.success
        : payment.isFailed
            ? Tone.critical
            : Tone.warning;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: tone.background(brightness),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              payment.isSuccessful
                  ? Icons.check_rounded
                  : payment.isFailed
                      ? Icons.close_rounded
                      : Icons.schedule_rounded,
              size: 17,
              color: tone.foreground(brightness),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Fmt.date(payment.createdAt),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.slate100 : AppColors.slate800,
                  ),
                ),
                if (payment.reference.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  // The reference support asks for. Kept on one line and
                  // truncated at the front, because a Razorpay id's tail is the
                  // part that distinguishes it.
                  Text(
                    payment.reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Fmt.rupees(payment.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? AppColors.slate50 : AppColors.slate900,
                ),
              ),
              const SizedBox(height: 3),
              Pill(payment.statusLabel, tone: tone, dense: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final WalletTransaction transaction;

  /// A top-up, an unlock and an admin correction all move credits, but they are
  /// not the same event — give each its own mark so the history is scannable.
  (IconData, Tone) get _mark {
    final text =
        '${transaction.type} ${transaction.description}'.toLowerCase();

    if (transaction.isCredit) {
      if (text.contains('refund') || text.contains('revert')) {
        return (Icons.undo_rounded, Tone.info);
      }
      if (text.contains('bonus') || text.contains('referral')) {
        return (Icons.card_giftcard_rounded, Tone.accent);
      }
      if (text.contains('admin') || text.contains('adjust')) {
        return (Icons.tune_rounded, Tone.neutral);
      }
      return (Icons.add_card_rounded, Tone.success);
    }

    if (text.contains('unlock') || text.contains('contact')) {
      return (Icons.lock_open_rounded, Tone.accent);
    }
    if (text.contains('admin') || text.contains('adjust')) {
      return (Icons.tune_rounded, Tone.neutral);
    }
    return (Icons.arrow_upward_rounded, Tone.neutral);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final credit = transaction.isCredit;
    final (icon, tone) = _mark;

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
            child: Icon(icon, size: 15, color: tone.foreground(brightness)),
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
