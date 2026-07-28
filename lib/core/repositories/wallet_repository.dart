import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/wallet.dart';
import 'package:tht_app/core/repositories/repository.dart';

/// Credits, plans and payments — everything under `/api/wallet/`.
class WalletRepository extends Repository {
  WalletRepository([super.dio]);

  /// Balance, validity window and recent transactions in one call.
  Future<Wallet> wallet() async => Wallet.fromJson(await getMap('/api/wallet/me/'));

  Future<List<WalletTransaction>> transactions() async =>
      (await getList('/api/wallet/transactions/'))
          .map(WalletTransaction.fromJson)
          .toList();

  /// Plans available to buy.
  Future<List<CreditPackage>> packages() async =>
      (await getList('/api/wallet/packages/'))
          .map(CreditPackage.fromJson)
          .where((p) => p.isActive)
          .toList();

  /// Opens a Razorpay order for [packageId]; returns the order the checkout
  /// sheet needs (`order_id`, `amount`, `currency`, `key`).
  Future<Map<String, dynamic>> createOrder(int packageId) =>
      postMap('/api/wallet/create-order/', body: {'package_id': packageId});

  /// Confirms a completed Razorpay payment so the credits actually land.
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) =>
      postMap('/api/wallet/verify-payment/', body: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      });

  /// Whether the plan is close to lapsing — drives the renewal prompt.
  Future<Map<String, dynamic>> expiryStatus() =>
      getMap('/api/wallet/expiry-status/');

  /// A renewal offer being held for this user, if any.
  Future<Map<String, dynamic>> currentOffer() => getMap('/api/wallet/offer/');

  /// Past payments, for receipts.
  Future<List<Map<String, dynamic>>> payments() => getList('/api/wallet/payments/');
}

final walletRepositoryProvider =
    Provider<WalletRepository>((ref) => WalletRepository());
