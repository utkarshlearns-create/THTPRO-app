import 'package:tht_app/core/utils/json_x.dart';

/// A Razorpay order the checkout sheet can be opened with.
///
/// The server decides the amount — proration on an upgrade, any renewal
/// discount — and hands back the final figure. The app never computes a price;
/// it only displays what came back and passes the result to verification.
class PaymentOrder {
  const PaymentOrder({
    required this.orderId,
    required this.amountPaise,
    required this.keyId,
    this.currency = 'INR',
    this.packageName = '',
    this.credits = 0,
    this.validityDays = 0,
    this.isValidityOnly = false,
    this.offerApplied = false,
    this.offerPercent,
  });

  final String orderId;

  /// Razorpay works in the smallest currency unit.
  final int amountPaise;

  final String keyId;
  final String currency;
  final String packageName;
  final int credits;
  final int validityDays;
  final bool isValidityOnly;

  /// True when a renewal discount was applied server-side.
  final bool offerApplied;

  final String? offerPercent;

  double get amount => amountPaise / 100;

  factory PaymentOrder.fromJson(Map<String, dynamic> json) => PaymentOrder(
        orderId: asString(json, 'order_id'),
        amountPaise: asInt(json, 'amount'),
        keyId: asString(json, 'key_id'),
        currency: asString(json, 'currency', fallback: 'INR'),
        packageName: asString(json, 'package_name'),
        credits: asInt(json, 'credits'),
        validityDays: asInt(json, 'validity_days'),
        isValidityOnly: asBool(json, 'is_validity_only'),
        offerApplied: asBool(json, 'offer_applied'),
        offerPercent: asStringOrNull(json, 'offer_percent'),
      );
}
