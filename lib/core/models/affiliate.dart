import 'package:tht_app/core/utils/json_x.dart';

/// A teacher's referral standing: their code, who joined on it, and what they
/// have earned.
class Affiliate {
  const Affiliate({
    this.code = '',
    this.link = '',
    this.totalReferred = 0,
    this.totalEarned = 0,
    this.pendingPayout = 0,
    this.recentEarnings = const [],
    this.referredUsers = const [],
  });

  final String code;

  /// The full signup URL, already carrying `?ref=` and the teacher role.
  final String link;

  final int totalReferred;

  /// Everything earned, paid out or not.
  final double totalEarned;

  /// What is owed but not yet paid — the figure a payout request is for.
  final double pendingPayout;

  final List<AffiliateEarning> recentEarnings;
  final List<ReferredUser> referredUsers;

  /// The server refuses a payout under this.
  static const minimumPayout = 500.0;

  bool get canRequestPayout => pendingPayout >= minimumPayout;

  /// What is still needed before a payout can be asked for.
  double get shortfall =>
      (minimumPayout - pendingPayout).clamp(0, minimumPayout).toDouble();

  /// How many of the people who joined went on to buy a plan — the only ones
  /// that pay anything.
  int get convertedCount =>
      referredUsers.where((u) => u.purchasedPlan).length;

  factory Affiliate.fromJson(Map<String, dynamic> json) => Affiliate(
        code: asString(json, 'referral_code'),
        link: asString(json, 'referral_link'),
        totalReferred: asInt(json, 'total_referred'),
        totalEarned: asDoubleOrNull(json, 'total_earned') ?? 0,
        pendingPayout: asDoubleOrNull(json, 'pending_payout') ?? 0,
        recentEarnings: asMapList(json, 'recent_earnings')
            .map(AffiliateEarning.fromJson)
            .toList(),
        referredUsers: asMapList(json, 'referred_users')
            .map(ReferredUser.fromJson)
            .toList(),
      );
}

/// One credited amount.
class AffiliateEarning {
  const AffiliateEarning({
    required this.id,
    this.type = '',
    this.amount = 0,
    this.description = '',
    this.isPaidOut = false,
    this.createdAt,
  });

  final int id;

  /// `PLAN` when a referred teacher bought a plan; other types are bonuses.
  final String type;

  final double amount;
  final String description;
  final bool isPaidOut;
  final DateTime? createdAt;

  String get typeLabel =>
      type.toUpperCase() == 'PLAN' ? 'Plan purchase' : _title(type);

  factory AffiliateEarning.fromJson(Map<String, dynamic> json) =>
      AffiliateEarning(
        id: asInt(json, 'id'),
        type: asString(json, 'earning_type'),
        amount: asDoubleOrNull(json, 'amount') ?? 0,
        description: asString(json, 'description'),
        isPaidOut: asBool(json, 'is_paid_out'),
        createdAt: asDateOrNull(json, 'created_at'),
      );
}

/// Someone who signed up on this teacher's code.
class ReferredUser {
  const ReferredUser({
    this.name = 'Teacher',
    this.joinedAt,
    this.purchasedPlan = false,
  });

  final String name;
  final DateTime? joinedAt;

  /// Only a referral who buys a plan earns anything.
  final bool purchasedPlan;

  factory ReferredUser.fromJson(Map<String, dynamic> json) => ReferredUser(
        name: asString(json, 'name', fallback: 'Teacher'),
        joinedAt: asDateOrNull(json, 'joined_at'),
        purchasedPlan: asBool(json, 'purchased_plan'),
      );
}

/// Turns `PLAN_BONUS` into `Plan bonus`.
///
/// Deliberately not on the shared `Fmt` — a second class of that name in scope
/// would shadow the app's formatter wherever both are imported.
String _title(String raw) {
  final words = raw.replaceAll('_', ' ').trim().toLowerCase();
  if (words.isEmpty) return 'Earning';
  return words[0].toUpperCase() + words.substring(1);
}
