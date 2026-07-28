import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/models/payment_order.dart';
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

  /// Opens a Razorpay order for [packageId].
  ///
  /// The server sets the amount: full price, an upgrade prorated against the
  /// remaining value of the current plan, or a renewal discount. The app never
  /// computes a price of its own.
  Future<PaymentOrder> createOrder(
    int packageId, {
    bool upgrade = false,
    String? offerCode,
  }) async =>
      PaymentOrder.fromJson(await postMap('/api/wallet/create-order/', body: {
        'package_id': packageId,
        if (upgrade) 'upgrade': true,
        if (offerCode != null && offerCode.isNotEmpty) 'offer_code': offerCode,
      }));

  /// Confirms a completed Razorpay payment so the credits actually land.
  ///
  /// The webhook credits the wallet too; this is the fallback for when it is
  /// delayed. Both paths deduplicate on the order id, so calling it is safe.
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    int? packageId,
  }) =>
      postMap('/api/wallet/verify-payment/', body: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
        if (packageId != null) 'package_id': packageId,
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
