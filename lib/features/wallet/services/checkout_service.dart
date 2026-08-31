import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:tht_app/core/models/app_user.dart';
import 'package:tht_app/core/models/lead_purchase.dart';
import 'package:tht_app/core/models/payment_order.dart';
import 'package:tht_app/core/utils/api_error.dart';

/// What came back from the Razorpay sheet.
sealed class CheckoutResult {
  const CheckoutResult();
}

/// Paid. The three fields are what verification needs to credit the wallet.
class CheckoutPaid extends CheckoutResult {
  const CheckoutPaid({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}

/// The user closed the sheet. Not an error — no message should be shown.
class CheckoutCancelled extends CheckoutResult {
  const CheckoutCancelled();
}

/// The payment was attempted and failed.
class CheckoutFailed extends CheckoutResult {
  const CheckoutFailed(this.message);

  final String message;
}

/// Opens the Razorpay sheet and resolves once the user is done with it.
///
/// Wraps the plugin's callback API in a Future so the calling screen reads as a
/// straight line: create order, open checkout, verify. The plugin is also
/// single-use per flow — it must be disposed or its listeners fire again on the
/// next payment.
class CheckoutService {
  /// Razorpay's Flutter plugin ships Android and iOS only — no web, no desktop.
  /// Anywhere else this returns an honest message instead of throwing a
  /// MissingPluginException from inside the checkout sheet.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Buying credits.
  Future<CheckoutResult> open({
    required PaymentOrder order,
    AppUser? user,
  }) =>
      _open(
        orderId: order.orderId,
        amountPaise: order.amountPaise,
        keyId: order.keyId,
        currency: order.currency,
        description:
            order.packageName.isEmpty ? 'Lead credits' : order.packageName,
        user: user,
        unsupportedMessage:
            'Payments work in the Android and iOS app. Open The Home Tuitions '
            'on your phone to add credits.',
      );

  /// Buying one lead outright — pay-per-lead.
  ///
  /// Same sheet, different money: this buys a single family's contact rather
  /// than topping up a balance, so the description Razorpay shows and the
  /// message on an unsupported platform both differ.
  Future<CheckoutResult> openForLead({
    required LeadOrder order,
    AppUser? user,
  }) =>
      _open(
        orderId: order.orderId,
        amountPaise: order.amountPaise,
        keyId: order.keyId,
        currency: order.currency,
        description: 'Buy this lead — family contact',
        user: user,
        unsupportedMessage:
            'Buying a lead works in the Android and iOS app. Open The Home '
            'Tuitions on your phone to buy this one.',
      );

  Future<CheckoutResult> _open({
    required String orderId,
    required int amountPaise,
    required String keyId,
    required String currency,
    required String description,
    required String unsupportedMessage,
    AppUser? user,
  }) async {
    if (!isSupported) return CheckoutFailed(unsupportedMessage);

    final completer = Completer<CheckoutResult>();
    final razorpay = Razorpay();

    void finish(CheckoutResult result) {
      if (completer.isCompleted) return;
      completer.complete(result);
    }

    razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
        final resolvedOrderId = r.orderId ?? orderId;
        final paymentId = r.paymentId;
        final signature = r.signature;
        if (paymentId == null || signature == null) {
          // Razorpay reported success without the fields verification needs.
          // Treating this as paid would show credits that never landed.
          finish(const CheckoutFailed(
            'The payment went through but could not be confirmed. Your credits '
            'will appear shortly — contact us if they do not.',
          ));
          return;
        }
        finish(CheckoutPaid(
          orderId: resolvedOrderId,
          paymentId: paymentId,
          signature: signature,
        ));
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
        // Code 2 is the user dismissing the sheet. Reporting that as an error
        // would scold someone for changing their mind.
        if (r.code == Razorpay.PAYMENT_CANCELLED) {
          finish(const CheckoutCancelled());
          return;
        }
        finish(CheckoutFailed(_message(r)));
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
        // Handing off to an external wallet app leaves this flow; the webhook
        // credits the wallet when it settles.
        finish(const CheckoutFailed(
          'Finish the payment in your wallet app. Credits appear here once it '
          'settles.',
        ));
      });

    try {
      razorpay.open({
        'key': keyId,
        'order_id': orderId,
        'amount': amountPaise,
        'currency': currency,
        'name': 'The Home Tuitions',
        'description': description,
        'timeout': 300,
        'prefill': {
          if (user?.phone != null) 'contact': user!.phone,
          if (user?.email != null) 'email': user!.email,
        },
        'theme': {'color': '#E1702E'},
      });
    } catch (e) {
      finish(CheckoutFailed(ApiFailure.from(e).message));
    }

    try {
      return await completer.future;
    } finally {
      razorpay.clear();
    }
  }

  String _message(PaymentFailureResponse r) {
    final raw = (r.message ?? '').trim();
    if (raw.isEmpty) return 'The payment did not go through. Please try again.';
    // The plugin sometimes wraps the reason in a JSON blob; show the sentence,
    // not the envelope.
    final match = RegExp(r'"description"\s*:\s*"([^"]+)"').firstMatch(raw);
    return match?.group(1) ?? raw;
  }
}
