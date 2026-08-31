import 'package:tht_app/core/utils/json_x.dart';

/// A Razorpay order raised to buy one lead.
///
/// Everything here is decided by the server. [amountPaise] is what Razorpay is
/// told to charge and [leadPrice] is the same figure in rupees for display —
/// the app must never derive one from the other, or invent a price when the
/// server declines to give one.
class LeadOrder {
  const LeadOrder({
    required this.orderId,
    required this.amountPaise,
    required this.keyId,
    required this.leadPrice,
    required this.jobId,
    this.currency = 'INR',
  });

  final String orderId;

  /// Paise, because that is what Razorpay's SDK expects.
  final int amountPaise;

  /// The Razorpay publishable key. Comes from the server so the app never
  /// carries a hardcoded key that would need a rebuild to rotate.
  final String keyId;

  /// Whole rupees, for the button and the receipt line.
  final int leadPrice;

  final int jobId;
  final String currency;

  factory LeadOrder.fromJson(Map<String, dynamic> json) => LeadOrder(
        orderId: asString(json, 'order_id'),
        amountPaise: asInt(json, 'amount'),
        keyId: asString(json, 'key_id'),
        leadPrice: asInt(json, 'lead_price'),
        jobId: asInt(json, 'job_id'),
        currency: asString(json, 'currency', fallback: 'INR'),
      );
}

/// The outcome of a verified lead purchase.
///
/// Only produced by a 200 from the verify endpoint. A Razorpay success callback
/// on the device is not proof of payment — the signature is checked server-side
/// and the contact is only ever revealed from this response.
class LeadPurchase {
  const LeadPurchase({
    this.isUnlocked = false,
    this.isPaid = false,
    this.whatsapp,
    this.amountPaid,
    this.message = '',
  });

  final bool isUnlocked;
  final bool isPaid;

  /// The family's WhatsApp number, revealed by this purchase.
  final String? whatsapp;

  final double? amountPaid;
  final String message;

  factory LeadPurchase.fromJson(Map<String, dynamic> json) => LeadPurchase(
        isUnlocked: asBool(json, 'is_unlocked'),
        isPaid: asBool(json, 'is_paid'),
        whatsapp: asStringOrNull(json, 'whatsapp'),
        amountPaid: asDoubleOrNull(json, 'amount_paid'),
        message: asString(json, 'message'),
      );
}

/// Who else has bought this lead.
///
/// Shown to a teacher deciding whether to buy: three people already holding the
/// number is a materially different proposition from none.
class LeadBuyers {
  const LeadBuyers({this.totalCount = 0, this.buyers = const []});

  final int totalCount;
  final List<LeadBuyer> buyers;

  bool get isEmpty => totalCount == 0;

  factory LeadBuyers.fromJson(Map<String, dynamic> json) => LeadBuyers(
        totalCount: asInt(json, 'total_count'),
        buyers: asMapList(json, 'buyers').map(LeadBuyer.fromJson).toList(),
      );
}

class LeadBuyer {
  const LeadBuyer({this.name = '', this.photo, this.id});

  final String name;
  final String? photo;

  /// The public tutor profile id, when the server sends one.
  final int? id;

  factory LeadBuyer.fromJson(Map<String, dynamic> json) => LeadBuyer(
        name: asString(json, 'name'),
        photo: asStringOrNull(json, 'photo') ?? asStringOrNull(json, 'image'),
        id: asIntOrNull(json, 'id') ?? asIntOrNull(json, 'tutor_id'),
      );
}
