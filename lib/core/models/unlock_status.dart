import 'package:tht_app/core/utils/json_x.dart';

/// Whether this teacher holds the contact behind a lead, and what stands
/// between them and it.
///
/// From `GET /api/users/jobs/<id>/unlock-contact/`.
///
/// Contact is now **bought**, not unlocked for free. The teacher pays THT a
/// per-lead fee, gets the family's WhatsApp number, and deals with them
/// directly — THT takes no commission on the tuition. The old free-unlock POST
/// against this same path is gone; the server answers it with 403.
///
/// The credit [balance] survives only because the payload still carries it. It
/// no longer gates anything on this screen.
class UnlockStatus {
  const UnlockStatus({
    this.isUnlocked = false,
    this.isPaid = false,
    this.isApproved = false,
    this.balance = 0,
    this.unlockCount = 0,
    this.maxUnlocks = 0,
    this.limitReached = false,
    this.whatsapp,
  });

  final bool isUnlocked;

  /// True when this teacher got the contact by buying it, rather than through
  /// a free unlock made before pay-per-lead existed. Those older unlocks still
  /// stand — the difference is only what the caption says.
  final bool isPaid;

  /// KYC verified **and** profile approved by the tutor admin. The server
  /// refuses a purchase without it, so the button must not be offered.
  final bool isApproved;

  /// The teacher's credit balance. Not a gate on buying a lead.
  final double balance;

  /// How many teachers already hold this family's contact.
  final int unlockCount;

  /// The cap, or 0 when uncapped.
  final int maxUnlocks;

  final bool limitReached;

  /// Returned once the contact is held.
  final String? whatsapp;

  /// Remaining places, or null when there is no cap.
  int? get slotsLeft {
    if (maxUnlocks <= 0) return null;
    final left = maxUnlocks - unlockCount;
    return left < 0 ? 0 : left;
  }

  /// Every place has been taken.
  bool get isSoldOut => limitReached || (slotsLeft != null && slotsLeft == 0);

  /// Whether this teacher may buy [job]'s contact right now.
  ///
  /// Takes the lead alongside the status because the two halves live apart:
  /// the lead says whether it is for sale, the status says whether this
  /// particular teacher may buy it.
  bool canBuy({required bool leadIsBuyable}) =>
      leadIsBuyable && !isUnlocked && isApproved && !isSoldOut;

  /// How many places are left, in words — or null when there is nothing worth
  /// saying about scarcity.
  String? get spotsLine {
    if (maxUnlocks > 0) {
      final left = slotsLeft ?? 0;
      if (left <= 0) return 'All places taken';
      return '$unlockCount of $maxUnlocks taken — only $left left';
    }
    if (unlockCount > 0) {
      return unlockCount == 1
          ? '1 teacher has bought this lead'
          : '$unlockCount teachers have bought this lead';
    }
    return 'Be the first to buy this lead';
  }

  factory UnlockStatus.fromJson(Map<String, dynamic> json) => UnlockStatus(
        isUnlocked: asBool(json, 'is_unlocked'),
        isPaid: asBool(json, 'is_paid'),
        isApproved: asBool(json, 'is_approved'),
        balance: asDouble(json, 'balance'),
        unlockCount: asInt(json, 'unlock_count'),
        maxUnlocks: asInt(json, 'max_unlocks'),
        limitReached: asBool(json, 'limit_reached'),
        whatsapp: asStringOrNull(json, 'whatsapp'),
      );
}
