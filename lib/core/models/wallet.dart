import 'package:tht_app/core/utils/json_x.dart';

/// The credit balance behind every contact unlock, from `GET /api/wallet/me/`.
///
/// Credits are what a parent spends to see a teacher's number, and what a
/// teacher spends to see a lead. A plan can also carry a validity window that
/// only starts counting once it is activated.
class Wallet {
  const Wallet({
    this.balance = 0,
    this.validUntil,
    this.validityActivated = false,
    this.pendingValidityDays = 0,
    this.updatedAt,
    this.transactions = const [],
  });

  final int balance;
  final DateTime? validUntil;
  final bool validityActivated;

  /// Days bought but not yet started — the clock begins on first unlock.
  final int pendingValidityDays;

  final DateTime? updatedAt;
  final List<WalletTransaction> transactions;

  bool get hasCredits => balance > 0;

  /// Null when there is no validity window on the account at all.
  int? get daysRemaining {
    if (validUntil == null) return null;
    final diff = validUntil!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isExpired => validityActivated && (daysRemaining ?? 1) <= 0;

  /// Worth warning about in the UI before it lapses.
  bool get isExpiringSoon {
    final d = daysRemaining;
    return validityActivated && d != null && d > 0 && d <= 7;
  }

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        balance: asInt(json, 'balance'),
        validUntil: asDateOrNull(json, 'valid_until'),
        validityActivated: asBool(json, 'validity_activated'),
        pendingValidityDays: asInt(json, 'pending_validity_days'),
        updatedAt: asDateOrNull(json, 'updated_at'),
        transactions: asMapList(json, 'transactions')
            .map(WalletTransaction.fromJson)
            .toList(),
      );
}

/// A single credit movement — a top-up, an unlock, an admin adjustment.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.description = '',
    this.createdAt,
  });

  final int id;
  final int amount;

  /// The backend's `transaction_type`, e.g. `CREDIT` / `DEBIT`.
  final String type;

  final String description;
  final DateTime? createdAt;

  /// True when credits came in rather than went out.
  bool get isCredit => amount > 0 && !type.toUpperCase().contains('DEBIT');

  /// `+40` / `-1`, ready to render.
  String get signedAmount => '${isCredit ? '+' : '−'}${amount.abs()}';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: asInt(json, 'id'),
        amount: asInt(json, 'amount'),
        type: asString(json, 'transaction_type'),
        description: asString(json, 'description'),
        createdAt: asDateOrNull(json, 'created_at'),
      );
}

/// A purchasable plan from `GET /api/wallet/packages/`.
class CreditPackage {
  const CreditPackage({
    required this.id,
    required this.name,
    required this.price,
    this.credits = 0,
    this.validityDays = 0,
    this.features = const [],
    this.targetRole = '',
    this.isValidityOnly = false,
    this.isActive = true,
  });

  final int id;
  final String name;
  final double price;
  final int credits;

  /// Days the credits stay spendable. Zero means they never expire.
  final int validityDays;

  /// Marketing bullets the admin writes per plan.
  final List<String> features;

  /// `PARENT` | `TEACHER` | `INSTITUTION` — who the plan is sold to.
  ///
  /// The list endpoint only filters on this when asked to, so the app both asks
  /// and re-checks: a warm server-side cache can still hand back every role's
  /// plans, and a teacher shown "Parent Starter" has no way to know it is not
  /// for them.
  final String targetRole;

  /// A plan that extends time rather than adding credits.
  final bool isValidityOnly;

  final bool isActive;

  /// `₹12 per credit` — the comparison a buyer actually makes.
  double? get pricePerCredit => credits > 0 ? price / credits : null;

  bool get isLifetime => validityDays == 0 && !isValidityOnly;

  /// `Lifetime` / `Valid 180 days`.
  ///
  /// Pluralised by hand rather than through `Fmt`, so the models layer stays
  /// clear of intl — the same reason [Job] carries its own digit grouping.
  String get validityLabel => validityDays == 0
      ? 'Lifetime'
      : 'Valid $validityDays ${validityDays == 1 ? 'day' : 'days'}';

  bool matchesRole(String? role) =>
      role == null || targetRole.isEmpty || targetRole.toUpperCase() == role;

  factory CreditPackage.fromJson(Map<String, dynamic> json) => CreditPackage(
        id: asInt(json, 'id'),
        name: asString(json, 'name'),
        price: asDouble(json, 'price'),
        credits: asInt(json, 'credit_amount'),
        validityDays: asInt(json, 'validity_days'),
        features: asStringList(json, 'features'),
        targetRole: asString(json, 'target_role'),
        isValidityOnly: asBool(json, 'is_validity_only'),
        isActive: asBool(json, 'is_active', fallback: true),
      );
}

/// A renewal discount being held for one user, from `GET /api/wallet/offer/`.
///
/// The server resolves this from the signed-in user and applies it at order
/// creation whether or not the client sends the code — so an app that does not
/// show it quotes a price it will not charge. This type exists so the price on
/// the card and the price on the payment sheet are the same number.
class RenewalOffer {
  const RenewalOffer({
    this.valid = false,
    this.code = '',
    this.percentOff = 0,
    this.expiresAt,
  });

  final bool valid;
  final String code;

  /// Comes over the wire as a decimal string, e.g. `"20.00"`.
  final double percentOff;

  final DateTime? expiresAt;

  static const none = RenewalOffer();

  bool get isLive =>
      valid &&
      percentOff > 0 &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  /// Mirrors the server's `RenewalOffer.apply_to`, including its ₹1 floor.
  ///
  /// An estimate, not a receipt: the server quantises to paise and this rounds
  /// to whole rupees, so treat the payment sheet as authoritative.
  double discounted(double price) {
    final off = price * (100 - percentOff) / 100;
    return off < 1 ? 1 : off;
  }

  factory RenewalOffer.fromJson(Map<String, dynamic> json) => RenewalOffer(
        valid: asBool(json, 'valid'),
        code: asString(json, 'code'),
        percentOff: asDouble(json, 'percent_off'),
        expiresAt: asDateOrNull(json, 'expires_at'),
      );
}

/// Validity standing from `GET /api/wallet/expiry-status/`.
///
/// [canBuyValidity] is the one that matters on the plans page: the server
/// rejects a validity-only purchase from anyone who has never bought credits,
/// so without this the app offers a button that can only ever fail.
class WalletExpiryStatus {
  const WalletExpiryStatus({
    this.canBuyValidity = true,
    this.expiredCredits = 0,
    this.daysRemaining,
  });

  /// Defaults to true so a failed probe never blocks a legitimate purchase —
  /// the server still enforces the rule either way.
  final bool canBuyValidity;

  final double expiredCredits;
  final int? daysRemaining;

  static const unknown = WalletExpiryStatus();

  bool get hasExpiredCredits => expiredCredits > 0;

  factory WalletExpiryStatus.fromJson(Map<String, dynamic> json) =>
      WalletExpiryStatus(
        canBuyValidity: asBool(json, 'can_buy_validity', fallback: true),
        expiredCredits: asDouble(json, 'expired_credits'),
        daysRemaining: json['days_remaining'] == null
            ? null
            : asInt(json, 'days_remaining'),
      );
}
