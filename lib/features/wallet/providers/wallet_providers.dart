import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Plans available to buy, cheapest first so the entry price is visible.
final creditPackagesProvider = FutureProvider.autoDispose<List<CreditPackage>>(
  (ref) async {
    final packages = await ref.watch(walletRepositoryProvider).packages();
    return packages..sort((a, b) => a.price.compareTo(b.price));
  },
);

/// A renewal discount being held for this user, if any.
final walletOfferProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.watch(walletRepositoryProvider).currentOffer(),
);
