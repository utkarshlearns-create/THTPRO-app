import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:tht_app/core/models/app_user.dart';
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
  /// Razorpay's Flutter plugin has no web implementation. On web this returns a
  /// failure with an honest message rather than crashing inside the plugin.
  static bool get isSupported => !kIsWeb;

  Future<CheckoutResult> open({
    required PaymentOrder order,
    AppUser? user,
  }) async {
    if (!isSupported) {
      return const CheckoutFailed(
        'Payments are only available in the mobile app. Open The Home Tuitions '
        'on your phone to add credits.',
      );
    }

    final completer = Completer<CheckoutResult>();
    final razorpay = Razorpay();

    void finish(CheckoutResult result) {
      if (completer.isCompleted) return;
      completer.complete(result);
    }

    razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
        final orderId = r.orderId ?? order.orderId;
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
          orderId: orderId,
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
        'key': order.keyId,
        'order_id': order.orderId,
        'amount': order.amountPaise,
        'currency': order.currency,
        'name': 'The Home Tuitions',
        'description': order.packageName.isEmpty
            ? 'Lead credits'
            : order.packageName,
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
