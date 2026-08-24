import 'package:tht_app/core/utils/json_x.dart';

/// What it costs to move to a bigger plan part-way through the current one.
///
/// The server prorates: whatever is left of the plan already paid for is
/// credited against the new one, so [upgradePrice] is below the plan's list
/// price. [upgradeCredits] is the *delta* granted, not the new plan's nominal
/// total — quoting the total would promise credits the upgrade does not add.
class UpgradeQuote {
  const UpgradeQuote({
    required this.packageId,
    this.packageName = '',
    this.packagePrice = 0,
    this.packageCredits = 0,
    this.packageValidityDays = 0,
    this.remainingValue = 0,
    this.upgradePrice = 0,
    this.upgradeCredits = 0,
    this.currentPlanName,
  });

  final int packageId;
  final String packageName;

  /// The plan's list price, before anything is credited back.
  final double packagePrice;

  final int packageCredits;
  final int packageValidityDays;

  /// What the unused part of the current plan is worth.
  final double remainingValue;

  /// The prorated price actually payable.
  final double upgradePrice;

  /// Credits this upgrade adds on top of what is already held.
  final int upgradeCredits;

  final String? currentPlanName;

  /// True when there is genuinely something to credit back. Without an active
  /// plan the "upgrade" is just a purchase at full price, and calling it an
  /// upgrade would be a discount that is not there.
  bool get isRealUpgrade => remainingValue > 0 && upgradePrice < packagePrice;

  /// What the buyer saves by upgrading now rather than starting over.
  double get saving =>
      (packagePrice - upgradePrice).clamp(0, packagePrice).toDouble();

  factory UpgradeQuote.fromJson(Map<String, dynamic> json) {
    final current = asMapOrNull(json, 'current_plan');
    return UpgradeQuote(
      packageId: asInt(json, 'package_id'),
      packageName: asString(json, 'package_name'),
      packagePrice: asDoubleOrNull(json, 'package_price') ?? 0,
      packageCredits: asInt(json, 'package_credits'),
      packageValidityDays: asInt(json, 'package_validity_days'),
      remainingValue: asDoubleOrNull(json, 'remaining_value') ?? 0,
      upgradePrice: asDoubleOrNull(json, 'upgrade_price') ?? 0,
      upgradeCredits: asInt(json, 'upgrade_credits'),
      currentPlanName: current == null
          ? null
          : (asString(current, 'name').trim().isEmpty
              ? null
              : asString(current, 'name').trim()),
    );
  }
}
