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
    this.description = '',
    this.isValidityOnly = false,
    this.isActive = true,
  });

  final int id;
  final String name;
  final double price;
  final int credits;
  final int validityDays;
  final String description;

  /// A plan that extends time rather than adding credits.
  final bool isValidityOnly;

  final bool isActive;

  /// `₹12 per credit` — the comparison a buyer actually makes.
  double? get pricePerCredit => credits > 0 ? price / credits : null;

  factory CreditPackage.fromJson(Map<String, dynamic> json) => CreditPackage(
        id: asInt(json, 'id'),
        name: asString(json, 'name'),
        price: asDouble(json, 'price'),
        credits: asInt(json, 'credit_amount'),
        validityDays: asInt(json, 'validity_days'),
        description: asString(json, 'description'),
        isValidityOnly: asBool(json, 'is_validity_only'),
        isActive: asBool(json, 'is_active', fallback: true),
      );
}
