import 'package:tht_app/core/utils/json_x.dart';

/// One payment attempt against the wallet — a plan bought, or an attempt that
/// never completed.
///
/// Distinct from a `WalletTransaction`: that is the credit ledger, this is the
/// money. A failed payment leaves a record here and nothing there, which is
/// exactly the case a user comes looking for.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    this.orderId = '',
    this.paymentId,
    this.amount,
    this.status = '',
    this.createdAt,
  });

  final int id;

  /// Razorpay's order reference — what support asks for.
  final String orderId;

  /// Null until Razorpay has actually taken the money.
  final String? paymentId;

  final double? amount;

  /// `SUCCESS`, `PENDING`, `FAILED` — cased as the server sends it.
  final String status;

  final DateTime? createdAt;

  bool get isSuccessful => status.toUpperCase() == 'SUCCESS';
  bool get isFailed => status.toUpperCase() == 'FAILED';

  /// An order that was created and then abandoned — no payment id ever came
  /// back. Worth distinguishing from a failure the bank declined.
  bool get isAbandoned => !isSuccessful && !isFailed && paymentId == null;

  String get statusLabel {
    if (isSuccessful) return 'Paid';
    if (isFailed) return 'Failed';
    return isAbandoned ? 'Not completed' : 'Pending';
  }

  /// The reference a user quotes to support: the payment id once there is one,
  /// otherwise the order it was started under.
  String get reference => paymentId?.trim().isNotEmpty == true
      ? paymentId!.trim()
      : orderId.trim();

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: asInt(json, 'id'),
        orderId: asString(json, 'order_id'),
        paymentId: asStringOrNull(json, 'payment_id'),
        amount: asDoubleOrNull(json, 'amount'),
        status: asString(json, 'status'),
        createdAt: asDateOrNull(json, 'created_at'),
      );
}
