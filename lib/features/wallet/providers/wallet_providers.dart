import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/auth_provider.dart';
import 'package:tht_app/core/models/payment_record.dart';
import 'package:tht_app/core/models/upgrade_quote.dart';
import 'package:tht_app/core/models/wallet.dart';
import 'package:tht_app/core/repositories/wallet_repository.dart';

/// Credit balance and validity. Shared by teachers and parents — both spend
/// credits, so this is not a teacher-only concern.
final walletProvider = FutureProvider.autoDispose<Wallet>(
  (ref) => ref.watch(walletRepositoryProvider).wallet(),
);

/// Full transaction history, beyond the few the wallet payload embeds.
final walletTransactionsProvider =
    FutureProvider.autoDispose<List<WalletTransaction>>(
  (ref) => ref.watch(walletRepositoryProvider).transactions(),
);

/// Plans this user can actually buy, cheapest first so the entry price is
/// visible.
///
/// Role comes from [authProvider] rather than `currentUserProvider`: it is
/// already populated by the time the router lets anyone reach this screen, so
/// asking for it costs nothing, where the user endpoint would add a round-trip
/// and a second loading state to a page someone is trying to pay on.
///
/// The server-side filter is asked for *and* re-checked. Plan lists are cached
/// per role for ten minutes under separate keys, so a warm `packages_all` entry
/// can still answer with every audience's plans.
/// The prorated price to move to one plan from the current one.
///
/// Per package, because the credit for the unused remainder depends on which
/// plan is being moved to. Errors are swallowed by the card that reads it: a
/// quote that will not load should hide the upgrade line, never replace the
/// plan's own price with an error.
final upgradeQuoteProvider =
    FutureProvider.autoDispose.family<UpgradeQuote, int>(
  (ref, packageId) =>
      ref.watch(walletRepositoryProvider).upgradeQuote(packageId),
);

/// Money in, as opposed to credits moved.
///
/// Separate from [walletTransactionsProvider] on purpose: a payment that failed
/// or was abandoned appears here and nowhere else, and that is the one a user
/// goes looking for.
final walletPaymentsProvider =
    FutureProvider.autoDispose<List<PaymentRecord>>(
  (ref) => ref.watch(walletRepositoryProvider).payments(),
);

final creditPackagesProvider = FutureProvider.autoDispose<List<CreditPackage>>(
  (ref) async {
    final role = ref.watch(authProvider).role;
    final all = await ref.watch(walletRepositoryProvider).packages(role: role);

    final mine =
        all.where((p) => p.matchesRole(role?.value)).toList();

    // Falling back is deliberate. Not every audience has plans seeded, and a
    // page reading "no plans available" is a worse answer than one showing a
    // list that is merely broader than it should be.
    final packages = mine.isEmpty ? all : mine;
    return packages..sort((a, b) => a.price.compareTo(b.price));
  },
);

/// A renewal discount being held for this user.
///
/// Failures collapse to [RenewalOffer.none] instead of propagating. The server
/// applies whatever offer the user holds at order creation regardless of what
/// the app sends, so this endpoint only affects what the page *says* — and an
/// optional promo lookup must never take down a checkout screen.
final walletOfferProvider = FutureProvider.autoDispose<RenewalOffer>(
  (ref) async {
    try {
      return await ref.watch(walletRepositoryProvider).currentOffer();
    } catch (_) {
      return RenewalOffer.none;
    }
  },
);

/// Whether validity-only plans are buyable, and what has already lapsed.
///
/// Same treatment as the offer: on failure fall back to permissive defaults and
/// let the server keep enforcing the rule. Blocking a real purchase because a
/// secondary probe failed is the worse error.
final walletExpiryProvider = FutureProvider.autoDispose<WalletExpiryStatus>(
  (ref) async {
    try {
      return await ref.watch(walletRepositoryProvider).expiryStatus();
    } catch (_) {
      return WalletExpiryStatus.unknown;
    }
  },
);
