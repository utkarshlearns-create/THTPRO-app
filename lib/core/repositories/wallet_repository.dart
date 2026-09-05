import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/auth/user_role.dart';
import 'package:tht_app/core/models/payment_order.dart';
import 'package:tht_app/core/models/payment_record.dart';
import 'package:tht_app/core/models/upgrade_quote.dart';
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
  ///
  /// [role] matters: without it the endpoint returns every audience's plans, so
  /// a teacher is offered "Parent Starter" alongside the identically-priced
  /// "Standard Plan" and cannot tell which one is theirs.
  Future<List<CreditPackage>> packages({UserRole? role}) async =>
      (await getList(
        '/api/wallet/packages/',
        query: role == null ? null : {'role': role.value},
      ))
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

  /// Whether the plan is close to lapsing, and whether validity-only plans may
  /// be bought at all.
  Future<WalletExpiryStatus> expiryStatus() async =>
      WalletExpiryStatus.fromJson(await getMap('/api/wallet/expiry-status/'));

  /// A renewal offer being held for this user, if any.
  ///
  /// Answers `{'valid': false}` rather than 404 when there is none.
  /// The site-wide sale, if one is running.
  ///
  /// Never let this fail a page: it is a bonus, and the server applies the
  /// discount regardless of whether the app asked about it.
  Future<PlatformPromo> platformPromo() async =>
      PlatformPromo.fromJson(await getMap('/api/wallet/promo/'));

  Future<RenewalOffer> currentOffer() async =>
      RenewalOffer.fromJson(await getMap('/api/wallet/offer/'));

  /// Past payments, for receipts.
  /// What it costs to move to [packageId] part-way through the current plan.
  ///
  /// The unused remainder of the plan already paid for is credited against the
  /// new one. Answers a full-price quote with `remaining_value: 0` when there
  /// is no active plan, so callers check [UpgradeQuote.isRealUpgrade] before
  /// calling anything a discount.
  Future<UpgradeQuote> upgradeQuote(int packageId) async =>
      UpgradeQuote.fromJson(await getMap(
        '/api/wallet/upgrade-quote/',
        query: {'package_id': packageId},
      ));

  /// Every payment this user has started, newest first.
  ///
  /// The money, not the credits: a failed or abandoned payment leaves a record
  /// here and none in the transaction ledger, which is precisely the case
  /// someone comes looking for.
  Future<List<PaymentRecord>> payments() async =>
      (await getList('/api/wallet/payments/'))
          .map(PaymentRecord.fromJson)
          .toList();
}

final walletRepositoryProvider =
    Provider<WalletRepository>((ref) => WalletRepository());
